---
name: new-feature
description: End-to-end workflow to deliver a feature safely - design, plan, implement, test, review, document. Use when asked to build or add functionality.
argument-hint: "<feature description or issue link>"
disable-model-invocation: true
---
# Feature: $ARGUMENTS

Follow these phases; stop and ask at any ambiguity.
1. **Understand** — restate requirements, acceptance criteria, non-goals. List questions; get answers before continuing.
2. **Design** — if non-trivial (schema/API/multi-module), delegate to `architect`; summarize chosen approach and task list; get user approval.
3. **Implement** — small steps in dependency order, following existing patterns and `.claude/rules/*`. Keep each step compiling.
4. **Test** — delegate to `test-writer` for unit + integration tests including failure and authz cases.
5. **Verify** — run the Full verify command from CLAUDE.md; fix until green.
6. **Review** — run `/review` on the diff; address blockers and should-fix items.
7. **Document** — update README/API docs/CHANGELOG; run `/adr` if an architectural decision was made.
8. **Report** — summary of what changed, how it was verified (real output), risks, follow-ups. Do not commit unless asked.
