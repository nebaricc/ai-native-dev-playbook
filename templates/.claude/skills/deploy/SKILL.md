---
name: deploy
description: CI/CD pipeline, deploy scripts, environment layout, and infra. Use when touching deploy workflows, infrastructure config, or troubleshooting CI failures.
user-invocable: false
---

# Deploy & Infrastructure

## Environment Layout

| Environment | Branch/Trigger | Project/Cluster | Auto-deploy? |
|---|---|---|---|
| Development | Push to `{DEV_BRANCH}` | `{DEV_PROJECT}` | Yes |
| Staging | PR merged to `{STAGING_BRANCH}` | `{STAGING_PROJECT}` | Yes |
| Production | `{PROD_TRIGGER}` | `{PROD_PROJECT}` | On trigger |

## Deploy Pipeline

```
{DEV_BRANCH} push → dev deploy → PR to {STAGING_BRANCH} → stage deploy → {PROD_TRIGGER} → prod deploy
```

CI order per deploy: **{DEPLOY_STEPS}**
<!-- Example: migrate → build → push image → deploy service -->

## Authentication

{AUTH_METHOD}
<!-- Examples:
- WIF (Workload Identity Federation) — no key files; GitHub Actions auth via OIDC
- Service account key stored as GitHub secret (less preferred)
- OIDC with cloud provider
-->

## GitHub Secrets Scoping

**Environment secrets, not repo secrets.** Auth credentials (`WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`, etc.) must be stored as GitHub Environment secrets — not repo-level secrets.

| Wrong | Right |
|---|---|
| Repo secret `PROD_WIF_PROVIDER` | Environment secret `WIF_PROVIDER` on `production` |
| Repo secret `STAGE_WIF_PROVIDER` | Environment secret `WIF_PROVIDER` on `staging` |

Repo-level secrets are readable by any workflow on any branch. Environment secrets are only accessible to jobs that declare `environment: production` — and only when that environment's protection rules are satisfied.

**Public config is not a secret.** Values that are intentionally client-exposed (Firebase web config, public API URLs, project identifiers) do not belong in secrets. Commit them in per-environment config files (`.env.dev`, `.env.stage`, `.env.prod`) and copy the right file in CI:

```yaml
- name: Setup environment
  run: cp .env.{ENV} apps/web/.env
```

Runtime secrets (DB credentials, API keys, private keys) live in **{SECRETS_STORE}** — fetched at runtime, never baked into images or stored in GitHub.

## Deploy Script

```bash
# {DEPLOY_COMMAND_EXAMPLES}
./bin/deploy.sh {DEV_PROJECT} --service api --yes
./bin/deploy.sh {PROD_PROJECT} --service all --skip-build --sha $SHA --yes
```

Key flags:
- `{SKIP_BUILD_FLAG}` — use image/artifact already built by CI
- `{MIGRATE_FLAG}` — run DB migrations before deploying
- `{YES_FLAG}` — skip confirmation prompt (for CI)

## Secrets & Config

- All secrets in `{SECRETS_STORE}` — fetched at runtime, not baked into images
- Config that varies by environment: `{CONFIG_APPROACH}`
- Never commit `.env` files with real values

## IAM Bootstrap Problem

When adding new permissions to the deploy service account, Terraform/IaC can't self-apply them because it lacks the roles to grant them. Fix: manually grant the new role first, then let IaC reconcile.

```bash
# {CLOUD_PROVIDER} example
{GRANT_ROLE_COMMAND}
# Then run terraform apply / IaC apply
```

## Troubleshooting CI

| Symptom | Likely cause |
|---|---|
| Permission denied on deploy step | Missing IAM role on deploy SA — grant manually then re-run |
| IAM propagation lag | Wait ~60s after granting new roles |
| Image pull auth failure | Using public registry without auth at pull rate limits — use a mirror |
| Migration failure | Check migration tracking table for duplicate timestamps or failed state |
| State lock collision | Concurrent IaC applies — wait for first, then re-run |
| Prod workflow uses wrong environment's credentials | Secrets are repo-level with prefixes instead of environment-scoped — move to GitHub Environments |
