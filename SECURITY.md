# Security Policy

<!-- TEMPLATE: replace every <placeholder>, adjust the targets to what your team can meet,
     and have your legal team review "Safe harbor" before publishing. -->

## Reporting a vulnerability
**Please do not open a public issue, PR or discussion for security problems.**

Report privately through GitHub: **Security tab → Report a vulnerability** (private vulnerability reporting).
If you can't use GitHub, email **<security@your-domain.example>** (optionally encrypted to our PGP key: `<fingerprint / URL>`).

Please include:
- Affected version, commit or URL
- Steps to reproduce or a proof of concept
- Impact: what an attacker can do
- How we can reach you for follow-up

## What to expect
| Stage | Target |
|---|---|
| Acknowledgement | within 3 business days |
| Triage (validity, severity via CVSS) | within 7 days |
| Fix or mitigation, Critical/High | within 30 days |
| Fix or mitigation, Medium/Low | within 90 days |
| Public disclosure | coordinated with you after a fix ships, by default 90 days after your report |

If a fix can't ship within 90 days, we'll tell you why before the deadline and agree an extension with you, or publish an advisory with mitigations. We will keep you updated, tell you when the issue is fixed, and credit you in the advisory unless you prefer to stay anonymous.

## Supported versions
| Version | Security fixes |
|---|---|
| `<latest release / main>` | ✅ |
| `<older versions>` | ❌ |

## Scope
**In scope:** code in this repository, its CI/CD pipeline, and artifacts we publish (packages, container images, `<production URL>`).

**Out of scope:** denial-of-service or load testing; social engineering or phishing; physical attacks; reports from automated scanners without a demonstrated impact; vulnerabilities in third-party dependencies that are already public (report upstream, but tell us if we are exploitable).

## Safe harbor
We will not pursue or support legal action against good-faith research that follows this policy: only test against accounts and data you own, avoid privacy violations, data destruction and service degradation, stop and report as soon as you find a vulnerability, and give us reasonable time to fix it before disclosure.
