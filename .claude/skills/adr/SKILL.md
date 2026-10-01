---
name: adr
description: Create an Architecture Decision Record in docs/adr when a significant technical decision is made (framework, schema, pattern, trade-off).
argument-hint: "<decision title>"
disable-model-invocation: true
allowed-tools: Read, Glob, Bash(ls:*), Edit(./docs/adr/**)
---
1. List `docs/adr/` to find the next number (zero-padded 4 digits).
2. Copy `docs/adr/0000-template.md` to `docs/adr/NNNN-<kebab-title>.md` for "$ARGUMENTS".
3. Fill Context, Decision, Options considered (with trade-offs), Consequences (positive, negative, risks), Status = Proposed. Base it on the conversation and code; don't invent facts.
4. Link superseded ADRs. Show the user the result.
