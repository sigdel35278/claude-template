---
description: Container and infrastructure-as-code security
paths:
  - "**/Dockerfile*"
  - "**/*.dockerfile"
  - "**/*compose*.y*ml"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/k8s/**"
  - "**/kubernetes/**"
  - "**/charts/**"
  - "**/helm/**"
  - "**/*.bicep"
  - "**/cloudformation/**"
---
# Infrastructure & container rules
- **Images:** pin base images by digest (`FROM image:tag@sha256:…`); prefer minimal bases (distroless, slim, alpine); multi-stage builds so build tools don't ship.
- **Containers:** run as a non-root `USER`; read-only root filesystem; drop all capabilities; never `privileged`, `hostNetwork`, `hostPID` or `hostPath`; set CPU/memory limits.
- **Secrets:** never in `Dockerfile`, build args, image layers, manifests, `.tfvars` or state committed to git. Use BuildKit `--secret`, a secret manager, or External Secrets. Terraform state holds secrets: remote, encrypted, locked backend only.
- **Kubernetes:** `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, default-deny `NetworkPolicy`, dedicated ServiceAccount without auto-mounted token unless needed.
- **Cloud/IAM:** least privilege; no `*` actions or resources; no `0.0.0.0/0` to SSH/RDP/database ports; databases and buckets private (public-access block on); encryption at rest and in transit; audit logging on.
- **CI → cloud:** OIDC federation with short-lived credentials; never long-lived access keys in CI secrets.
- The `Infrastructure (trivy config)` and `Container image (trivy image)` checks must pass; fix HIGH/CRITICAL findings rather than ignoring them.
