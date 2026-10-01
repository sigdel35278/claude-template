---
description: API and database conventions
paths:
  - "src/**/api/**"
  - "src/**/routes/**"
  - "src/**/controllers/**"
  - "**/migrations/**"
  - "**/*.sql"
---
# API & data rules
- APIs: versioned, validated request/response schemas, consistent error shape, pagination on every list, idempotency keys for unsafe retries.
- Never break existing contracts; deprecate first. Document in OpenAPI/README.
- Migrations: backward-compatible (expand → migrate → contract), reversible, never edit applied migrations, no data loss without explicit approval, index new query paths.
- Transactions around multi-step writes; define timeouts.
