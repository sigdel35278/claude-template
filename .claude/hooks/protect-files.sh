#!/usr/bin/env bash
# PreToolUse(Read|Grep|Edit|Write|MultiEdit|NotebookEdit): exit 2 blocks the call.
# Secrets are never read or written (example/sample/template env files are allowed).
# Lockfiles and generated/vendored code are readable but never hand-edited.
# Portable to macOS bash 3.2. Add a case to test-hooks.sh for every change.
command -v jq >/dev/null 2>&1 || { echo "Blocked: guardrail hooks require jq (failing closed). Install jq." >&2; exit 2; }
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""') || { echo "Blocked: unreadable hook input (failing closed)." >&2; exit 2; }
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // ""')
[ -n "$f" ] || exit 0
case "$f" in /*) ;; *) f="/$f" ;; esac
# Match lowercased: macOS filesystems are case-insensitive (.ENV == .env).
lf=$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')
name=${lf##*/}

deny() { echo "Blocked: $f is protected ($1). $2" >&2; exit 2; }

is_secret() {
  case "$name" in
    .env.example|.env.sample|.env.template|.env.dist) return 1 ;;
    .env|.env.*|*.env|.envrc|*.pem|*.key|*.p12|*.pfx|id_rsa|id_ed25519|id_ecdsa|.netrc|.npmrc|.pypirc|credentials.json|*.tfstate|*.tfstate.*) return 0 ;;
  esac
  case "$lf" in
    */secrets|*/secrets/*|*/.ssh|*/.ssh/*|*/.aws|*/.aws/*|*/.config/gh/*|*/.kube/*|*/.docker/config.json|/proc/*) return 0 ;;
  esac
  return 1
}

is_generated() {
  case "$name" in
    package-lock.json|yarn.lock|pnpm-lock.yaml|composer.lock|poetry.lock|uv.lock|cargo.lock|gemfile.lock|go.sum) return 0 ;;
  esac
  case "$lf" in */node_modules/*|*/vendor/*|*/dist/*|*/.git/*) return 0 ;; esac
  return 1
}

is_secret && deny "secret" "Ask the user for the non-secret value you need; document new vars in .env.example."
case "$tool" in
  Read|Grep) ;;
  *) is_generated && deny "lockfile, generated or vendored" "Change it with the package manager or build tool instead." ;;
esac
exit 0
