---
name: security-audit
description: Deep security audit of a module, feature or the whole repo (dependencies, secrets, auth, input handling, config). Use for periodic audits or before releases.
argument-hint: "[path or module] (default: whole repo)"
disable-model-invocation: true
context: fork
agent: security-reviewer
---
Audit `$ARGUMENTS` (default: repo root).
1. Map entry points (routes, jobs, CLI, webhooks) and trust boundaries.
2. Scan for hardcoded secrets (`rg -n -i "(api[_-]?key|secret|token|passwd|password)\s*[:=]"`, private keys) — report locations only.
3. Run dependency audit using the project's command (npm audit / pip-audit / composer audit / govulncheck).
4. Walk the checklist from your instructions for each entry point.
5. Produce a report: Critical → Low findings with CWE, location, exploit, fix; then a hardening roadmap (quick wins vs. larger work).
