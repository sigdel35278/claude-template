---
name: review
description: Full multi-perspective review of the current diff, a branch, or a PR. Use when the user asks to review changes, before a commit, or before opening/merging a PR.
argument-hint: "[branch | PR number | path] (default: uncommitted changes)"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(git status), Bash(gh pr view:*), Bash(gh pr diff:*)
---
# Review: $ARGUMENTS

1. Determine scope: no argument → `git diff HEAD`; branch → `git diff main...$ARGUMENTS`; number → `gh pr diff $ARGUMENTS`.
2. Launch IN PARALLEL (single message, multiple Agent calls) on that scope:
   - `code-reviewer` (always)
   - `security-reviewer` (if the diff touches auth, input, data, deps, config, infra)
   - `performance-reviewer` (if queries, loops, I/O, caching, concurrency)
3. Merge results: dedupe, order by severity, drop unverified claims. Verify blockers yourself by reading the code.
4. Output:
   - **Verdict** (APPROVE / APPROVE WITH NITS / REQUEST CHANGES)
   - Blockers → Should-fix → Nits, each `path:line` + fix
   - Missing tests / docs / migration notes
   - Checklist: tests pass? lint/typecheck pass? secrets-free? docs updated?
Do not modify code. Offer to fix findings afterwards.
