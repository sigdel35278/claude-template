#!/usr/bin/env bash
# PreToolUse(Bash): exit 2 blocks the call and feeds stderr back to Claude.
# A denylist is a speed bump against mistakes and naive prompt injection, not a
# sandbox: obfuscated commands can evade it. For isolation enable sandboxing (README).
# Portable to macOS bash 3.2 / BSD grep. Add a case to test-hooks.sh for every change.
command -v jq >/dev/null 2>&1 || { echo "Blocked: guardrail hooks require jq (failing closed). Install jq." >&2; exit 2; }
cmd=$(jq -r '.tool_input.command // ""') || { echo "Blocked: unreadable hook input (failing closed)." >&2; exit 2; }
# Lowercase once: macOS filesystems are case-insensitive (.ENV == .env). Keep the raw
# command for the few checks where case matters (env var names).
raw=$cmd
cmd=$(printf '%s\n' "$cmd" | tr '[:upper:]' '[:lower:]')

deny() { echo "Blocked by policy: $1. Propose a safer alternative or ask the user to run it." >&2; exit 2; }
has() { printf '%s\n' "$cmd" | grep -Eq -- "$1"; }

s='[[:space:]]'
start='(^|[;&|(/"'"'"'\\]|[[:space:]])'
end='([[:space:];&|)"'"'"']|$)'

# --- Destructive commands ---
sys_dir='/((bin|boot|dev|etc|lib|opt|root|sbin|srv|usr|var|system|library|applications)/?|(users|home)/[^/[:space:]"'"'"']+/?)?\*?'
home_dir='(~|\$\{?home\}?)/?\*?'
has "${start}(sudo$s+)?rm$s+([^;&|]*$s)?(-[a-z]*r|--recursive)([^;&|]*$s)?[\"']?($sys_dir|$home_dir|\.\.?/?\*?|\*|\.git/?)$end" \
  && deny "recursive rm of root, home, cwd, .git or glob"
has ":\(\)$s*\{"                             && deny "fork bomb"
has "${start}mkfs"                           && deny "filesystem format"
has "${start}dd$s+[^;&|]*(if|of)="           && deny "raw disk copy (dd)"
has ">$s*/dev/(sd|nvme|disk)"                && deny "write to block device"
has "(curl|wget)$s[^|]*\|$s*(sudo$s+)?[a-z]*sh$end"            && deny "piping a download into a shell"
has "[a-z]*sh$s+(-c$s+)?[\"']?(<\(|\\\$\()$s*(curl|wget)$s"   && deny "executing a downloaded script"
git_push="${start}git$s([^;&|]*$s)?push$s([^;&|]*$s)?"
has "$git_push(--force|-[a-z]*f[a-z]*$end)"  && deny "force push"
has "$git_push\+[^[:space:]]"                && deny "force push via +refspec"
has "git$s[^;&|]*reset$s[^;&|]*--hard"       && deny "git reset --hard (discards work)"
has "git$s[^;&|]*clean$s[^;&|]*-[a-z]*f"     && deny "git clean -f (deletes untracked files)"
has "chmod$s[^;&|]*777"                      && deny "world-writable permissions"
has "(^|[^a-z_])drop$s+(table|database|schema)"    && deny "SQL DROP"
has "(^|[^a-z_])truncate$s+table"                  && deny "SQL TRUNCATE"
# Options that turn auto-allowed read commands into file writers or command runners
# (e.g. `git diff --output=` could overwrite a hook and make it fail open).
has "git$s[^;&|]*--(output|upload-pack|receive-pack|exec)([=[:space:]]|$)" && deny "git option that writes files or runs commands"
has "${start}rg$s[^;&|]*--pre([=[:space:]]|$)"     && deny "rg --pre (runs a command per file)"
# Skipping or disabling git hooks would skip the secret-scanning pre-commit hook.
# git accepts unambiguous abbreviations (--no-veri); -n means --no-verify for commit only.
git_sub="git$s+((-c$s+[^[:space:]]+|--?[a-z-]+(=[^[:space:]]*)?)$s+)*"
has "git$s[^;&|]*--no-veri[a-z]*"                      && deny "skipping git hooks (--no-verify)"
has "${git_sub}commit$s([^;&|\"'\$]*$s)?-[aeqsv]*n[aeqsvm]*$end" && deny "skipping git hooks (commit -n)"
has "core\.hookspath|git_config_(count|key|value)"     && deny "redirecting git hooks (core.hooksPath)"
has "pre-commit$s+uninstall|\.git/hooks"               && deny "removing or editing git hooks"
printf '%s\n' "$raw" | grep -Eq "${start}(export$s+)?SKIP=" && deny "skipping pre-commit hooks (SKIP=)"

# --- Secret exposure through the shell (Read deny rules don't cover every command) ---
for f in $(printf '%s\n' "$cmd" | grep -Eo "(^|[[:space:]/\"'=<>(:@,])\.env[a-z]*(\.[a-z0-9_-]+)*" | sed -E 's/^[^.]//'); do
  case "$f" in
    .env.example|.env.sample|.env.template|.env.dist) ;;
    .env|.envrc|.env.*) deny "access to secret env file $f (use .env.example; if this is only text, e.g. a commit message, say \"env file\")" ;;
  esac
done
has "(\.ssh/|\.aws/|\.config/gh/|\.kube/|\.docker/config\.json|\.npmrc|\.pypirc|\.netrc|\.tfstate($end|\.)|id_(rsa|ed25519|ecdsa)$end)" \
  && deny "access to keys or credential stores"
# Key/cert files (tls.key, certs/server.pem); a token starting ".x" is a jq path (.api.key), not a file.
for k in $(printf '%s\n' "$cmd" | grep -Eo "[[:alnum:]_./~-]*[a-z0-9_-]\.(pem|key|p12|pfx)$end" | sed -E 's/[^a-z0-9]$//'); do
  case "$k" in .[a-z_]*) ;; *) deny "access to key or certificate file $k" ;; esac
done
has "terraform$s+(state$s+pull|show$s[^;&|]*-json|output$s[^;&|]*-(json|raw))" && deny "dumping terraform state/outputs (contain secrets)"

# --- docker runs outside the sandbox: no host privileges, no host mounts beyond the project ---
if has "${start}docker$s"; then
  has "--privileged|--(pid|network|net|ipc|uts|userns)[=[:space:]]+host|--cap-add|--device[=[:space:]]|docker\.sock" \
    && deny "docker with host privileges or the docker socket"
  project=$(printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}" | tr '[:upper:]' '[:lower:]')
  for src in $(printf '%s\n' "$cmd" | grep -Eo "(-v|--volume)(=|$s+)[\"']?[^:[:space:]\"']+|(source|src)=[^,[:space:]\"']+" \
               | sed -E "s/^(-v|--volume)(=|[[:space:]]+)[\"']?//; s/^(source|src)=//"); do
    case "$src" in
      .|./*|\$pwd|\$pwd/*|\$\{pwd\}*|\$\(pwd\)*|"$project"|"$project"/*) ;;      # the project
      /*|~*|\$home*|\$\{home\}*|..*) deny "docker mount of host path $src outside the project" ;;
    esac                                                                        # else: named volume
  done
fi
has "/proc/[^;&|[:space:]]*environ"          && deny "reading a process environment"
has "${start}(printenv|env)$s*([;&|)]|$)"    && deny "dumping the environment (may contain tokens)"
has "${start}jq$s[^;&|]*[^a-z_]\\\$?env([^a-z_]|$)" && deny "dumping the environment via jq"
has "${start}((echo|printf)$s[^;&|]*\\\$\{?|printenv$s+)[a-z0-9_]*(token|secret|passw(or)?d|api_?key|private_key)" \
  && deny "printing a secret variable"
has "${start}rg$s([^;&|]*$s)?(-[a-z]*u[a-z]*|--hidden|--no-ignore[a-z-]*)([=[:space:]]|$)" \
  && deny "rg searching ignored/hidden files (where secrets live)"
exit 0
