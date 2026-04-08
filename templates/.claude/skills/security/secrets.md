---
name: security/secrets
description: Secrets management — {SECRETS_MANAGER}, runtime injection, rotation, what never goes in source control. Load when adding new secrets, env vars, or credentials.
user-invocable: false
---

# Secrets Management

## Where Secrets Live

| Secret type | Location | Injected via |
|---|---|---|
| DB connection strings | {SECRETS_MANAGER} | Runtime env injection |
| API keys / tokens | {SECRETS_MANAGER} | Runtime env injection |
| Auth secrets (JWT, session) | {SECRETS_MANAGER} | Runtime env injection |
| CI/CD auth credentials | {CI_SECRETS_STORE} | CI environment only |

**Nowhere else.** Not in committed `.env` files. Not hardcoded. Not in CI secrets beyond what's strictly needed for deployment auth.

## Adding a New Secret

1. Store in {SECRETS_MANAGER}
2. Reference via runtime injection (not baked into image/bundle)
3. Access as `process.env.SECRET_NAME` — never fetch from secrets manager at request time
4. Repeat for each environment separately (dev/stage/prod must be isolated)

## What Never Goes in Source Control

- Database URLs (contain credentials)
- API keys and tokens
- JWT / session secrets
- Service account keys
- Any value you'd rotate if compromised

`.env.example` with placeholder values is fine. `.env` with real values is never committed.

## Secret Rotation

1. Create new secret version in {SECRETS_MANAGER}
2. Redeploy service — picks up new version automatically
3. Verify service healthy with new secret
4. Disable/delete old version

## Common Mistakes

- **`console.log(process.env.SECRET)`** — logs credentials to your log aggregator
- **`process.env.SECRET || 'hardcoded-fallback'`** — hardcoded fallback becomes the real secret in misconfigured environments
- **Fetching secrets per-request** — adds latency and unnecessary credential exposure; load at startup
- **Shared secrets across environments** — a compromised dev secret should not affect prod
- **Secrets in Docker build args** — build args appear in image layers and `docker history`
