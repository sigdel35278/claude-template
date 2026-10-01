---
name: write-tests
description: Generate high-quality tests for a file, function or module following project conventions. Use when asked to add tests or improve coverage.
argument-hint: "<file | symbol | module>"
context: fork
agent: test-writer
---
Write tests for `$ARGUMENTS`. First read the target and 2–3 existing tests for conventions. Prioritize risk: business rules, error handling, security checks, boundaries. Run them; report pass/fail and coverage delta if the tool is available.
