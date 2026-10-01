# Security checklist

What the files in this repo can't enforce. Do **A–C once** per repo/org, check **D–E every release** (`/release-check` walks them), and keep **F** ready before you need it.

## A. GitHub repository & organization (once)
- [ ] Ruleset/branch protection on `main`: PRs required, ≥1 approval, **Code Owner review**, dismiss stale approvals, all `Security` checks required except `Suppression audit`, no force push or deletion, linear history.
- [ ] `.github/CODEOWNERS`: real owner instead of `@your-org/security-team`.
- [ ] Code security: Dependabot alerts + security updates; secret scanning + **push protection**; **private vulnerability reporting** (used by `SECURITY.md`); CodeQL default setup (public repo or GitHub Advanced Security).
- [ ] Actions settings: allow only GitHub-owned, verified and listed actions; **require actions pinned to a full-length SHA**; default `GITHUB_TOKEN` = read-only; Actions may not create or approve PRs; require approval for workflows from outside contributors' forks.
- [ ] No workflow uses `pull_request_target` or `workflow_run` to check out and run PR code. PR workflows of public repos never run on **self-hosted runners** (`security.yml` builds the PR's Dockerfile).
- [ ] Tag protection / rulesets for release tags and **immutable releases**, so a stolen token can't move a tag to malicious code.
- [ ] Deploy secrets live in **Environments** with required reviewers and branch restrictions, never as plain repo secrets.
- [ ] Organization: **2FA required** for all members; least-privilege base permissions (read or none); remove inactive members and outside collaborators; audit-log streaming if available.

## B. Developer accounts & machines (once per person)
- [ ] 2FA on GitHub, cloud, registry (npm/PyPI/…) and email; prefer passkeys or hardware keys.
- [ ] Fine-grained, expiring tokens with minimal scope (e.g. `GITHUB_MCP_TOKEN` read-only); none in shell history, dotfiles or repos.
- [ ] SSH keys with a passphrase (or hardware-backed); commit signing enabled.
- [ ] Password manager; full-disk encryption; OS and tools auto-update.
- [ ] `pre-commit install` run in every clone.

## C. Claude Code (once per org)
- [ ] **First** install the sandbox dependencies on Linux/WSL machines (`bubblewrap`, `socat`): the managed example sets `failIfUnavailable`, so Claude Code won't start without them.
- [ ] Deploy [`managed-settings.example.json`](managed-settings.example.json) as managed settings:
  macOS `/Library/Application Support/ClaudeCode/managed-settings.json` · Linux/WSL `/etc/claude-code/managed-settings.json` · Windows `C:\Program Files\ClaudeCode\managed-settings.json` (or MDM / server-managed settings).
  It sets: bypass mode off; secret-file deny rules; sandbox on and required on macOS/Linux/WSL; credential paths, secret env vars and guardrail-file writes blocked for sandboxed commands. Managed values win, and deny rules/denylists can't be removed locally, but list settings merge: users and projects can still *add* allow rules, domains or paths unless you also set the `allowManaged…Only` keys below.
- [ ] Optional stricter policy: `allowManagedPermissionRulesOnly`, `allowManagedHooksOnly` (then ship this repo's hooks in managed settings too), `allowManagedMcpServersOnly`, `sandbox.network.allowManagedDomainsOnly`, and `sandbox.allowUnsandboxedCommands: false` (Claude can never run a command outside the sandbox; people run docker etc. themselves).
- [ ] Review the MCP servers each developer has configured (`claude mcp list`; user-level ones live in `~/.claude.json`) and remove unused or untrusted ones.
- [ ] Keep Claude Code updated (sandbox credential protection needs v2.1.187+).
- [ ] Review every diff to `.claude/`, `CLAUDE.md`, `.mcp.json` like production code (CODEOWNERS enforces the review).

## D. Application (every release; OWASP ASVS level 1 baseline)
- [ ] **AuthN:** MFA available; passwords hashed with argon2id/bcrypt; login, reset and signup rate-limited; generic error messages; reset tokens single-use and expiring.
- [ ] **Sessions:** cookies `Secure`, `HttpOnly`, `SameSite=Lax/Strict`; rotated on login and privilege change; server-side invalidation on logout; idle and absolute timeouts.
- [ ] **AuthZ:** deny by default; object-level checks on every resource (no IDOR); admin functions separately protected; tests for denial paths.
- [ ] **Input/output:** schema validation at every boundary; parameterized queries; context-aware output encoding; CSRF protection for cookie-authenticated state changes; uploads type/size-checked and stored outside the web root; SSRF allowlist for outbound URLs.
- [ ] **Headers:** `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `frame-ancestors`/`X-Frame-Options`, `Referrer-Policy`; CORS allowlist (no `*` with credentials).
- [ ] **Abuse:** rate limits and request size limits on public endpoints; pagination caps; timeouts on outbound calls.
- [ ] **Errors & logs:** no stack traces to clients; security events logged (logins, failures, permission denials, admin actions) without secrets or full PII.
- [ ] **Dependencies:** all `Security` checks green; no unaddressed High/Critical; licenses acceptable; install scripts disabled where the ecosystem allows (`npm config set ignore-scripts true`, allow-list the few packages that need them).

## E. Infrastructure & runtime (every release that touches it)
- [ ] TLS everywhere (HTTPS only, HSTS); certificates auto-renewed.
- [ ] Least-privilege IAM; CI deploys via OIDC; no long-lived cloud keys anywhere.
- [ ] Secrets in a secret manager, rotated on schedule and on staff changes.
- [ ] Databases, caches and admin panels not publicly reachable; network segmentation; WAF/DDoS protection on public entry points.
- [ ] Containers non-root, read-only filesystem, minimal base pinned by digest; `Container image` check green.
- [ ] Backups encrypted, off-site, and a **restore tested** this quarter.
- [ ] Monitoring and alerts: error-rate and latency spikes, auth-failure spikes, new admin users, unusual egress; uptime checks; logs retained ≥ 90 days.

## F. Incident response (ready before you need it)
1. **Detect & declare:** who is incident lead, where the team coordinates (`<channel>`), who can be paged (`<on-call>`).
2. **Contain:** revoke or rotate exposed credentials first; disable compromised accounts; block malicious IPs/tokens; take affected services offline if needed.
3. **Eradicate:** find the root cause and every affected system; patch; check for persistence (new keys, users, webhooks, workflows, deploy keys).
4. **Recover:** restore from known-good backups/images; monitor closely for recurrence.
5. **Communicate:** customers/regulators as required (`<legal/privacy contact>`; GDPR-style 72-hour clocks may apply); publish a GitHub security advisory for vulnerabilities.
6. **Learn:** blameless postmortem within a week; add a test, rule, hook or scanner check so it can't recur.

**Leaked secret playbook:** revoke/rotate it immediately, *then* clean up. Removing it from git history doesn't un-leak it: assume it was copied within minutes. Check the provider's audit log for use of the secret, and add the gitleaks fingerprint to `.gitleaksignore` only after rotation.
