---
name: fix-bug
description: Disciplined bug-fix workflow - reproduce, root-cause, regression test first, minimal fix, verify. Use for any bug report, failing test, or error trace.
argument-hint: "<bug description, issue link, or error>"
disable-model-invocation: true
---
# Bug: $ARGUMENTS
1. Delegate to `debugger` to reproduce and find the ROOT cause; capture the evidence.
2. Write a failing regression test (`test-writer`); confirm it fails for the right reason.
3. Implement the smallest fix. No unrelated refactoring.
4. Run the regression test, then the Full verify command.
5. Search for the same pattern elsewhere (`rg`) and report (don't silently expand scope).
6. Run `/review`. Summarize: cause, fix, test, residual risk.
