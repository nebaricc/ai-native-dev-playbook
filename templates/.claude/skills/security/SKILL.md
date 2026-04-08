---
name: security
description: Security index — routes to the relevant sub-skill. Load this first, then the specific sub-skill for what you're building. Mandatory for every feature.
user-invocable: false
---

# Security Index

**Load the relevant sub-skill before writing any code.**

| You're working on... | Load |
|---|---|
| Auth, sessions, tokens, roles | `security/auth.md` |
| Any query touching {SENSITIVE_DATA_TYPE} | `security/multi-tenancy.md` |
| Secrets, env vars, credentials | `security/secrets.md` |
| User input, API params, file uploads | `security/input-validation.md` |
| General review / unsure | load all four |
| OWASP review of new feature | `security/owasp.md` |

## Always-On Rules

- No secrets committed — ever
- Parameterized queries only — never string interpolation
- Production error responses scrub internals
- No base64 for internal data
- No in-memory state on horizontally-scaled services

## Proactive Flags

Raise these without being asked:

- New endpoint with no auth check → "Missing auth — load `security/auth.md`"
- Query without `{TENANT_ID_FIELD}` filter → "Unscoped query — potential data leak"
- `console.log` with user data → "PII in logs — load `compliance/data-privacy.md`"
- New env var or credential → "Where does this live in {SECRETS_MANAGER}? See `security/secrets.md`"
- Client-supplied `{TENANT_ID_FIELD}` or user ID used directly → "Use auth context, not request data"
