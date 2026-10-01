# Claude Code Project Template

Drop-in setup for secure, maintainable, scalable development with Claude Code.

## Install into a project
```bash
rsync -a --ignore-existing --exclude .git --exclude .qodo --exclude README.md --exclude CHANGELOG.md --exclude .DS_Store claude-template/ /path/to/your-project/
```
Never overwrites your files, so the hardening is **skipped** for any file that already exists: merge those by hand, especially `.claude/settings.json`, `.mcp.json`, `.github/workflows/claude-review.yml`, `.gitignore` and `CLAUDE.md`. If you copied from a zip, run `chmod +x .claude/hooks/*.sh`. Requires `jq`; without it the guardrail hooks **block every call** (fail closed) rather than silently allowing. Then run `.claude/hooks/test-hooks.sh`. Commit everything except `CLAUDE.local.md` and `settings.local.json`.

## Customize (≈15 min)
1. **CLAUDE.md** — fill stack, commands table, architecture. Keep it < ~150 lines; move detail to `docs/` and `@import` it.
2. **.claude/settings.json** — adjust `permissions` allow-list to your tooling; edit `hooks/format.sh` for your formatter. After changing hook patterns, add cases to `hooks/test-hooks.sh` and run it.
3. **.claude/rules/** — edit `paths:` globs to your layout; add language rules (e.g. `typescript.md`, `python.md`).
4. **.mcp.json** — keep only servers you need, read-only endpoints where offered. Tokens come from env vars (documented in `.env.example`): fine-grained, read-only, expiring. If `GITHUB_MCP_TOKEN` is unset the GitHub server fails to connect.
5. **CI** — add the `ANTHROPIC_API_KEY` secret and adjust `claude-review.yml`. It uses the job-scoped `GITHUB_TOKEN` (comments come from `github-actions[bot]`), so each job's `permissions:` is the real ceiling. Actions are pinned to commit SHAs; let Dependabot/Renovate bump them.
6. **Security scanning** — see below. At minimum: replace `@your-org/security-team` in `.github/CODEOWNERS`, uncomment your ecosystems in `.github/dependabot.yml`, and run `pipx install pre-commit && pre-commit install` in each clone. If your Dockerfile isn't at the root, set `DOCKERFILE` in `security.yml`.
7. **Security policy & checklist** — fill the `<placeholders>` in `SECURITY.md`, then work through [`docs/security-checklist.md`](docs/security-checklist.md) (GitHub settings, accounts, Claude managed settings, app, infra, incident response).
8. **Sandbox** — on by default (see "Sandbox" below). Adjust `sandbox.network.allowedDomains` to your registries.
9. Delete skills/agents you don't need.

## Repository security scanning
Protects against threats from **outside Claude** too: vulnerable dependencies, secrets committed by anyone, insecure code and CI.

| Layer | Tool | Runs | Catches |
|---|---|---|---|
| Secrets | gitleaks | pre-commit (local) + `security.yml` | API keys/tokens in commits, including ones added then deleted |
| Dependencies | osv-scanner | `security.yml` (PRs + weekly) | Known CVEs in any lockfile (npm, pip, composer, go, cargo, …) |
| Dependency updates | Dependabot | weekly PRs | Outdated actions/packages; 7-day cooldown against freshly hijacked releases |
| Code | Semgrep (`p/default`) | `security.yml` | Injection, XSS, unsafe deserialization, weak crypto, … |
| CI | zizmor | `security.yml` | Script injection, over-broad permissions, unpinned actions, dangerous triggers |
| Infrastructure | Trivy (`config`) | `security.yml` | Root containers, open security groups, public buckets, missing encryption in Dockerfile/Terraform/K8s/Helm/CloudFormation |
| Container image | Trivy (`image`) | `security.yml` (if a Dockerfile exists) | Fixable HIGH/CRITICAL CVEs in the base image's OS packages; secrets baked into layers |
| Suppressions | Suppression audit | `security.yml` (PRs) | A PR adding an ignore file or `# nosemgrep`-style marker fails, so an owner must look |
| Review | CODEOWNERS | every PR | Changes to `.claude/`, CI, scanner config and suppressions need a security owner |

All scanners are free, open source and work on private repos without GitHub Advanced Security. They run as non-root on a read-only checkout, and config a PR could use to silence them is ignored: gitleaks rules come from the workflow, zizmor runs with `--no-config`, Trivy ignores repo `trivy.yaml`/`trivy-secret.yaml`, osv-scanner honours only the root `osv-scanner.toml` and also scans gitignored lockfiles. Scanner images are pinned by digest: bump them deliberately (quarterly, or for a fix you need); Dependabot doesn't update them.

**Trivy** was hit by a supply-chain attack in March 2026 ([GHSA-69fq-xp46-6x23](https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23)): action tags were hijacked, and a malicious tag was built *and signed* by Aqua's own release pipeline from code that was never on `main`. So a valid signature alone proves nothing. The template never uses `trivy-action`, and the pinned digest (v0.74.0) passed two checks: its tag commit is on `main`, and its Sigstore certificate names exactly that commit. Repeat both on every bump:
```bash
# 1) the tag's commit must be an ancestor of main (status "ahead" or "identical")
gh api repos/aquasecurity/trivy/compare/<tag-commit-sha>...main --jq .status
# 2) the signature must come from Aqua's release workflow, built from that exact commit
docker run --rm ghcr.io/sigstore/cosign/cosign@sha256:9e5c2f2edc34351160407ca3416c61855bdf9403c3c5936e0f0be7fc261611b8 verify ghcr.io/aquasecurity/trivy@sha256:<digest> --certificate-identity-regexp '^https://github\.com/aquasecurity/trivy/\.github/workflows/.+@refs/tags/v<version>$' --certificate-oidc-issuer https://token.actions.githubusercontent.com --certificate-github-workflow-sha <tag-commit-sha>
```
Also check Trivy's [advisories](https://github.com/aquasecurity/trivy/security/advisories) and prefer a release that has been public for a couple of weeks.

**Turn on in GitHub settings** (not possible from files; full list in [`docs/security-checklist.md`](docs/security-checklist.md)):
- Branch protection / ruleset on `main`: require PRs, 1+ approval, **review from Code Owners**, and the checks `Secrets (gitleaks)`, `Dependencies (osv-scanner)`, `Code (semgrep)`, `Workflows (zizmor)`, `Infrastructure (trivy config)`, `Container image (trivy image)` (not `Suppression audit`: an owner may accept a justified one); block force pushes. Works with merge queues.
- **Private vulnerability reporting**, so `SECURITY.md`'s "Report a vulnerability" button works.
- Code security: Dependabot alerts + security updates; secret scanning + **push protection** (free on public repos).
- Public repo or GitHub Advanced Security: also enable **CodeQL default setup** (deeper analysis than Semgrep's free rules).
- Optional: move `ANTHROPIC_API_KEY` into a GitHub **Environment** limited to `main`/PRs.

**Handling findings:** fix them. A leaked secret must be **rotated** (deleting it doesn't un-leak it). Pushes to `main` scan the **full history**, so an old leak keeps `main` red: rotate it, then add its fingerprint (printed by gitleaks) to `.gitleaksignore` with a comment. False positives only, with a reason: `.gitleaksignore` or `# gitleaks:allow`, root `osv-scanner.toml` (with `ignoreUntil`), `# nosemgrep: <rule>` or `.semgrepignore`, `# zizmor: ignore[<audit>]`, root `.trivyignore` (with an expiry) or `# trivy:ignore:<id>`. Claude needs approval to edit these files, and its hook blocks common ways of skipping git hooks (`--no-verify`, `core.hooksPath`, `SKIP=`); CI re-runs every scan anyway.

**Known limits:** Semgrep's `p/default` rules and Trivy's vulnerability DB are fetched at run time (not pinned; Trivy's IaC checks come from the pinned image). Those downloads can occasionally hit registry rate limits; re-run the job. zizmor runs its online audits only when a token is available (always in CI). The container job builds **one** image (`DOCKERFILE` + `BUILD_CONTEXT` in `security.yml`) from the PR's code, on GitHub-hosted runners only (no secrets are available to it), and needs disk for the image plus a saved copy.

## Sandbox
`settings.json` turns on Claude Code's OS-level [sandbox](https://code.claude.com/docs/en/sandboxing) for Bash (Claude Code v2.1.187+; macOS Seatbelt; Linux/WSL2 need `bubblewrap` + `socat`). Unlike the pattern hooks, it is **enforced by the OS** for every sandboxed command, including code that `npm test` or a script runs:
- **Writes** only inside the project and temp dirs. Even there, `.claude/` (settings, hooks, skills, rules, agents), `CLAUDE.md`, `.mcp.json`, `.github/`, `.git/hooks`, `.git/config`, `.pre-commit-config.yaml`, `SECURITY.md` and scanner suppression files are read-only to commands (Claude edits them via its Edit tool, which asks you).
- **Reads** of every secret path in `permissions.deny` (SSH/cloud/registry/git credentials, key files, Terraform state, `~/.claude.json`) plus `~/.docker`, shell history, browser profiles, keychains and all `.env.*` files except `.env.example`/`.sample`/`.template`/`.dist` are refused.
- **Secret env vars** in `sandbox.credentials` (Anthropic, GitHub/GitLab, npm/PyPI/Cargo/Composer, AWS keys, Azure, Google, OpenAI, Hugging Face, Vault) are unset for commands. Add your own (e.g. `DATABASE_URL` if tests don't need it).
- **Network** goes through a filtering proxy. Only download-only hosts are pre-allowed (PyPI files, Go proxy, crates, Packagist, GitHub archive/asset CDNs); hosts that accept uploads (`github.com`, `api.github.com`, the npm registry) and everything else prompt you, so sandboxed code can't quietly send data out.
- `autoAllowBashIfSandboxed: false` keeps every existing permission prompt: the sandbox adds containment, it doesn't replace approval.

Commands that genuinely need more (e.g. `docker`, which needs its socket, or a tool writing to `~/.cache`) fail with "Operation not permitted"; Claude then asks to re-run **that one command outside the sandbox**, which you approve or deny. That escape hatch is the sandbox's main limit: once approved, a command has your full access. The hook still blocks the dangerous docker forms (host-path mounts outside the project, `--privileged`, host namespaces, the docker socket), but read what you approve. Use `/sandbox` to inspect, and `sandbox.filesystem.allowWrite` for safe extra paths. On unsupported platforms (native Windows) the project setting only warns; to **require** the sandbox, or forbid the escape hatch entirely (`allowUnsandboxedCommands: false`), use managed settings ([`docs/managed-settings.example.json`](docs/managed-settings.example.json), checklist section C).

## What each piece does
| Feature | Location | Purpose |
|---|---|---|
| Memory | `CLAUDE.md`, `CLAUDE.local.md` | Always-loaded project facts and agreements |
| Rules | `.claude/rules/*.md` | Path-scoped standards, loaded only when relevant |
| Subagents | `.claude/agents/` | Isolated-context specialists: code, security, performance review; architect; test-writer; debugger |
| Skills | `.claude/skills/*/SKILL.md` | Repeatable workflows (`/review`, `/new-feature`, `/fix-bug`, `/write-tests`, `/security-audit`, `/adr`, `/release-check`) |
| Hooks | `.claude/hooks/` | Deterministic guardrails: block dangerous commands & protected files, auto-format, session context |
| Permissions | `settings.json` | Allow/ask/deny; common secret files denied (the hook covers every `.env*` variant); guardrail edits need approval; bypass mode disabled |
| MCP | `.mcp.json` | External tools/data |
| CI | `.github/workflows/` | Automated PR review (`claude-review.yml`) and security scanning (`security.yml`) |
| Supply chain | `.github/dependabot.yml`, `.pre-commit-config.yaml`, `.github/CODEOWNERS` | Dependency updates, local secret blocking, owner review of sensitive paths |
| Docs | `docs/` | Architecture + ADRs that Claude reads before changing structure; security checklist; managed-settings example |
| Policy | `SECURITY.md` | How to report vulnerabilities privately; response targets; safe harbor |

## Principles
- **Developer flow:** plan → implement → test → `/review` → verify with real output.
- **Reviewer flow:** reviewers are read-only, cite `file:line`, rank by severity, run in parallel.
- **Guardrails are code** (hooks/permissions), not just prose: prose guides, hooks enforce.
- **Least privilege:** each agent gets only the tools it needs; opus for security/architecture, sonnet for the rest.
- Treat the template as living: when Claude repeats a mistake, add a rule; when a workflow repeats, make a skill.

## Security model & limits
- **Layers:** permission rules (deny > ask > allow) → PreToolUse hooks (`block-dangerous.sh`, `protect-files.sh`) → prose rules. Hooks are tested by `hooks/test-hooks.sh`.
- **Denylists are speed bumps; the sandbox is the stronger layer.** Quoting tricks or interpreters (`python -c …`) can evade pattern hooks, but not the OS sandbox (above), which blocks the listed credential reads, protected writes and unlisted network hosts however a sandboxed command is written. It covers only what it lists, and a command you approve to run *outside* the sandbox has your full access. Anything not allow-listed still prompts.
- **Keep the allow-list read-only.** Auto-allowed commands skip the prompt, so options that write or execute (`git diff --output`, `rg --pre`, `git fetch --upload-pack`) are blocked in the hook: a hook that is overwritten or crashes (exit ≠ 2) fails **open**.
- **Known over-block:** a command that merely *mentions* a secret file (e.g. a commit message saying `.env`) is blocked; rephrase rather than loosening the pattern.
- Reviewer agents are "read-only" by instruction; they keep `Bash` to run git/tests, under the same permissions and hooks.
- **Prompt injection** is the main agent risk: web pages, issues, PR diffs and tool output can carry instructions. Rules tell Claude to treat them as data; `ask` on `curl`, `npx` and installs, plus `WebFetch` prompts, keep a human in the loop for egress and code execution.
- **Self-modification:** edits to `.claude/**`, `CLAUDE.md` and `.mcp.json` require approval; `.github/workflows/**` is denied. Review these diffs like production code.
- **CI:** runs only for same-repo PRs and for comments from owners/members/collaborators, never on fork PRs. It uses per-job least-privilege tokens, persists no git credentials, and gives Claude no free-form comment command to exfiltrate data with.
- `settings.local.json` and user settings can override project settings; enforce org-wide policy with managed settings.
