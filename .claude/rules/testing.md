---
description: Testing conventions
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "tests/**"
  - "test/**"
  - "__tests__/**"
---
# Testing rules
- Co-locate or mirror source layout: `<PATTERN — customize>`.
- Names describe behavior: `should <result> when <condition>`.
- No sleeps; use fake timers/awaits. No shared mutable state between tests.
- Mock at system boundaries (HTTP, DB, clock), never the unit under test.
- Every bug fix includes a regression test. Keep tests fast (<100ms unit).
