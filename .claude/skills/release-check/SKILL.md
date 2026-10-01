---
name: release-check
description: Pre-release readiness gate - verification, security, migrations, docs, rollback plan. Use before tagging or deploying.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git status), Bash(git fetch:*), Bash(git diff:*), Bash(git log:*), Bash(git describe:*), Bash(git tag --list:*), Bash(npm run lint:*), Bash(npm run typecheck:*), Bash(npm test:*), Bash(npm run build:*), Bash(npm audit:*)
---
Read-only gate: do not commit, tag, push or deploy.
Run and report PASS/FAIL with evidence for each:
1. Clean working tree on the release branch; up to date with remote.
2. Full verify command (lint, typecheck, tests, build).
3. Dependency audit — no unaddressed High/Critical.
4. Secrets scan of the diff since last tag (`git diff <last-tag>..HEAD`).
5. Migrations: reversible, backward-compatible, tested on a copy.
6. Config: new env vars documented in `.env.example` and set in target env.
7. CHANGELOG/docs updated; breaking changes called out; version bumped.
8. Observability: logs/metrics/alerts for new paths; rollback plan written.
9. Run `/review` on `<last-tag>..HEAD` for blockers.
10. Walk `docs/security-checklist.md` sections D–E for what this release touches; report each item PASS/FAIL/N/A.
11. `SECURITY.md` and `.github/CODEOWNERS` contain no `<placeholder>` / `@your-org/` text (`rg -n '<[a-z@]|@your-org/' SECURITY.md .github/CODEOWNERS` is empty).
Finish with GO / NO-GO and the list of blockers.
