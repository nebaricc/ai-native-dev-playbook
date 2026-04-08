---
name: compliance
description: Compliance index — routes to the relevant sub-skill based on what you're building. Load this first for any feature touching user data, auth, logging, or third-party integrations.
user-invocable: false
---

# Compliance Index

## When to load which sub-skill

| You're building... | Load |
|---|---|
| Any feature touching {SENSITIVE_DATA_TYPE} | `compliance/data-privacy.md` |
| Logging, audit trails, error messages | `compliance/data-privacy.md` |
| Data export, reports, third-party integrations | `compliance/data-privacy.md` |
| Auth, IAM, secrets, infrastructure security | `compliance/security-controls.md` |
| Payments or financial data | `compliance/pci.md` |
| Clinical or medical data | `compliance/hipaa.md` |

## Proactive Triggers

Flag these automatically without being asked:

- **New endpoint returning user data** → "Have you added an audit log call? {COMPLIANCE_FRAMEWORK} may require this."
- **`console.log` with a variable that could contain user data** → "Check this log for PII — it may violate {COMPLIANCE_FRAMEWORK}."
- **Query without `{TENANT_ID_FIELD}` filter** → "Missing tenant scope — this could expose cross-tenant data."
- **New data collection** → "What's the purpose? Data minimization requires justification."
- **Sharing data with a third party** → "Is there a DPA/contract with this vendor?"
- **New secret or credential** → "Is this going into {SECRETS_MANAGER} or hardcoded somewhere?"

## Applicable Frameworks

This project operates under: **{COMPLIANCE_FRAMEWORKS}**

<!-- Examples: FERPA + COPPA (K-12 education), SOC 2 Type II (B2B SaaS), GDPR (EU users), HIPAA (healthcare), PCI-DSS (payments) -->
