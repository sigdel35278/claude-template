# Changelog

## [Unreleased] (2026-10-01)

### Fixed — first real CI run
- `Workflows (zizmor)` failed in CI: with a token it runs online audits, whose cache defaulted to `/.cache` (the non-root container user has no home). Now `HOME=/tmp` and `--cache-dir /tmp/zizmor`. The local simulation had no token, so it only ever exercised offline mode.

### Added — hardening & policy (Phase 2)
- **Sandbox on by default** (`settings.json`): OS-enforced; command writes limited to the project, credential dirs and secret files unreadable, secret env vars unset, network via allowlist proxy (hardened further in the review round below). `autoAllowBashIfSandboxed: false` keeps all prompts. Verified live: writes to `.claude/hooks/` and `~` refused.
- `docs/managed-settings.example.json`: org-wide policy (bypass off, secret deny rules, sandbox required on macOS/Linux/WSL, credentials hidden), schema-validated.
- `SECURITY.md`: private vulnerability reporting, response targets, scope, safe harbor (placeholders to fill).
- `docs/security-checklist.md`: GitHub/org settings, developer accounts, Claude managed settings, OWASP ASVS L1 app baseline, infra/runtime, incident response and leaked-secret playbook; `/release-check` walks it.
- `security.yml`: `Infrastructure (trivy config)` and `Container image (trivy image)` jobs. Trivy pinned by digest with verified provenance (its action/tags were hijacked in March 2026; the action is not used). Repo `trivy.yaml` ignored; `.trivyignore`/`trivy:ignore` flagged by the Suppression audit. Verified (26 sim cases): catches a root Dockerfile, an SSH-open security group and a CRITICAL base-image CVE, including with a bypass `trivy.yaml`.
- `.claude/rules/infrastructure.md`: container/IaC rules for Claude (digest-pinned bases, non-root, no secrets in layers, least-privilege IAM, OIDC).
- Terraform state protected: hooks and permissions block reading `*.tfstate`; `.gitignore` covers state, `.terraform/`, `*.tfvars`.

### Changed — Phase 2 review round
- Sandbox: `docker` no longer excluded (every run outside the sandbox needs explicit approval); pre-allowed network hosts limited to download-only ones (`github.com`, `api.github.com`, npm registry now prompt); more credential paths (gcloud, Azure, git-credentials, Vault, Terraform, Cargo, Composer, Maven, `~/.claude.json`, shell history, browser profiles, keychains) and all `.env.*` except examples hidden; `.claude/`, `CLAUDE.md`, `.mcp.json`, `.github/`, `.git/hooks`, `.git/config`, scanner suppressions read-only to commands; 20 secret env vars unset. Verified live.
- Hook blocks docker host escapes (host-path mounts outside the project, `--privileged`, host namespaces, `--cap-add`, `--device`, docker socket) and terraform state/output dumps (169 tests).
- Trivy: repo `trivy-secret.yaml` ignored (it could disable secret rules); IaC checks taken from the pinned image (`--skip-check-update`); `BUILD_CONTEXT` for Dockerfiles in subdirectories (not `DOCKER_CONTEXT`, which the docker CLI reserves). Sim: 28 cases.
- Trivy provenance: verified the pinned image's signature names the v0.74.0 tag commit, and that commit is on `main` (a signature alone would also have passed for the March 2026 malicious build). README documents both checks; cosign pinned by digest.
- Managed-settings example aligned with the project deny list and sandbox; checklist adds dependency rollout before `failIfUnavailable`, stricter tier (`allowUnsandboxedCommands: false`), MCP review, `pull_request_target`/self-hosted-runner rules, tag protection, `ignore-scripts`. `SECURITY.md` timelines made consistent; `/release-check` checks placeholders are filled.

### Fixed — Phase 2
- Hook false positive on jq's `.key` (matched the private-key pattern).
- Hook test "fails closed without jq" depended on a temp dir and passed by coincidence inside the sandbox; now tests the jq check directly (149 tests).

### Added — repository security scanning (Phase 1)
- `.github/workflows/security.yml`: gitleaks (secrets; full history, or the PR's commits), osv-scanner (lockfile CVEs), Semgrep `p/default` (code), zizmor (CI), plus a Suppression audit on PRs. Runs on PRs, merge queue, pushes to `main`, weekly and on demand. Images pinned by digest, run non-root on a read-only checkout, least-privilege tokens, no persisted credentials. Repo config that could silence a scanner (`.gitleaks.toml`, `zizmor.yml`, nested `osv-scanner.toml`, `.gitignore`d lockfiles) is ignored.
- Verified locally with Docker (19 cases): passes on the template; fails on a planted token, vulnerable lodash, SQL/eval/shell injection and an injectable workflow, including when each of those bypass configs is added; PRs adding suppressions are flagged.
- `.github/dependabot.yml` (GitHub Actions, 7-day cooldown; other ecosystems as commented examples).
- `.github/CODEOWNERS` for `.claude/`, `CLAUDE.md`, `.mcp.json`, `.github/` and scanner config/suppressions at any depth.
- `.pre-commit-config.yaml`: gitleaks blocks secrets before commit for every developer (verified end-to-end).
- Hook blocks skipping git hooks: `--no-verify` (and abbreviations), `git commit -n`, `SKIP=`, `core.hooksPath`, `GIT_CONFIG_*`, `pre-commit uninstall`, edits to `.git/hooks` (140 hook tests).
- Edits to `.github/**`, `.pre-commit-config.yaml` and scanner config/suppression files require approval.
- Install command excludes `.git` and `.qodo` (would have copied the template's git metadata into projects).
- `claude-review.yml`: named jobs, documented permissions. `test-writer.md` reworded to avoid a gitleaks false positive.

### Fixed — security hardening
- Hooks failed **open** when `jq` was missing (every command allowed); now fail closed.
- `block-dangerous.sh` was bypassable: `rm -fr`, `rm -r -f`, `/bin/rm`, quoted targets, `bash -c "…"`, `curl … | sudo bash`, `bash <(curl …)`, `git push +main`, `git -C dir push -f`, `--force-with-lease`, `git reset --hard`, `git clean -f`, `DROP SCHEMA`.
- Auto-allowed commands could write files or run commands (`git diff --output=` could overwrite a hook so it fails open; `rg --pre`; `git fetch --upload-pack`); now blocked.
- Secrets were readable through the shell (`cat .env`, `cat .ENV`, `curl -d @.env`, `~/.ssh`, `~/.aws`, `~/.config/gh`, `~/.npmrc`, `/proc/*/environ`, `printenv`, `jq -n env`, `rg --hidden`/`-uu`, `echo $TOKEN`); now blocked by hook.
- Matching is case-insensitive (macOS filesystems are: `.ENV` == `.env`).
- `.env.example` was blocked by both permissions and `protect-files.sh`, contradicting the rule to document vars there.
- `protect-files.sh` missed nested/relative/upper-case `secrets/`, `.envrc`, `~/.ssh`, `~/.aws`, non-npm lockfiles, `vendor/`, and the `Read`/`Grep`/`NotebookEdit` tools.
- Invalid permission rule `Bash(curl:*|*sh)` and wrong `$schema` URL in `settings.json`.
- CI review could not post comments (missing comment tools), and `@claude` comments re-ran the fixed review prompt instead of answering.
- `session-context.sh` exited non-zero outside a git repo.

### Changed — security hardening
- `settings.json`: bypass mode disabled; `rg`/`jq` no longer auto-allowed and `git branch` narrowed to read-only forms; `ask` for `curl`, `npx`, package installs, history-rewriting git, and edits to `.claude/**`, `CLAUDE.md`, `.mcp.json`; deny for more credential stores and `.env` variants, `git clean -f`, `npm publish`.
- CI: actions pinned to commit SHAs; job-scoped `GITHUB_TOKEN` (no `id-token`, so no broader App token); per-job least-privilege permissions; `persist-credentials: false`; fork, draft and Dependabot PRs skipped; `@claude` limited to owners/members/collaborators and refused on fork PRs; summary posted by the action (`track_progress`), not via a free-form `gh pr comment`; stale reviews cancelled.
- `.mcp.json`: GitHub MCP uses the read-only endpoint and a dedicated `GITHUB_MCP_TOKEN`.
- `release-check` no longer pre-approves all Bash; `adr` pre-approves writes only under `docs/adr/`.
- Prompt-injection and "don't weaken guardrails" rules added to `CLAUDE.md`, `rules/security.md` and reviewer/architect agents.
- README install uses non-clobbering `rsync`; documents the security model, its limits and the known over-block.

### Added — security hardening
- `.claude/hooks/test-hooks.sh` (regression cases, incl. allowed everyday commands and fail-closed without `jq`), `.env.example`, wider `.gitignore` coverage.
