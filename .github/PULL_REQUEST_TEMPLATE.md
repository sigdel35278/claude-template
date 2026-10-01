## What & why
## How tested
- [ ] Unit/integration tests added or updated
- [ ] Full verify passes locally
## Risk checklist
- [ ] No secrets/PII added or logged
- [ ] Input validated, authz enforced
- [ ] Migrations backward-compatible / rollback noted
- [ ] Docs / CHANGELOG / ADR updated
- [ ] No N+1 / unbounded queries
- [ ] New dependencies justified and audited
- [ ] Security checks green (gitleaks, osv-scanner, semgrep, zizmor); any new suppression has a reason
- [ ] Changes to `.claude/`, `CLAUDE.md`, `.mcp.json` or CI reviewed by a human
