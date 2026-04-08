---
name: database
description: Migration workflow, schema conventions, and query patterns. Use when writing migrations, modifying schema, or working with the DB layer.
user-invocable: false
---

# Database

## Stack

- **Schema & migrations**: `{MIGRATION_TOOL}` (Drizzle, Flyway, Alembic, etc.)
- **Query layer**: `{QUERY_LAYER}` (raw SQL, ORM query builder, etc.)
- **DB provider**: `{DB_PROVIDER}`

## Creating a Migration

```bash
# Generate migration from schema diff
{GENERATE_MIGRATION_COMMAND}

# Review the generated SQL/migration file
# Apply locally
{APPLY_MIGRATION_COMMAND}
```

## Migration Tracking Rules

- Every migration must have a **unique, monotonically increasing identifier** (timestamp or sequence number)
- Duplicate identifiers cause migrations to be silently skipped — always verify ordering
- Never edit an applied migration — create a new one to fix mistakes
- Migration history is tracked in `{MIGRATION_TRACKING_TABLE}`

## Running Migrations Against Environments

```bash
# Against a named environment (fetches DB URL from secrets)
{MIGRATE_ENV_COMMAND}

# Against a direct URL (local dev)
{MIGRATE_URL_COMMAND}
```

## Schema Conventions

- **Primary keys**: `{PK_CONVENTION}` — note UUID v4 is random and fragments B-tree indexes at scale; prefer time-ordered (UUID v7, ULID) for high-write tables
- **Multi-tenancy**: every tenant-scoped table has `{TENANT_ID_FIELD}` NOT NULL
- **Timestamps**: `created_at`, `updated_at` on every table — use DB-level defaults
- **Naming**: `{NAMING_CONVENTION}` (snake_case columns, camelCase in ORM models, etc.)

## Query Patterns

Always use parameterized queries — never string interpolation:

```typescript
// ✅ Safe — parameterized
const rows = await db.query(
  'SELECT * FROM {TABLE} WHERE {TENANT_ID_FIELD} = $1 AND id = $2 LIMIT $3',
  [tenantId, recordId, limit]
);

// ❌ Unsafe — SQL injection risk
const rows = await db.query(
  `SELECT * FROM {TABLE} WHERE {TENANT_ID_FIELD} = '${tenantId}'`
);
```

Always scope to `{TENANT_ID_FIELD}`. Always add `LIMIT` to list queries.

## Local Development

```bash
# Start local DB
{LOCAL_DB_COMMAND}

# Apply migrations locally
{LOCAL_MIGRATE_COMMAND}

# Seed with test data
{LOCAL_SEED_COMMAND}
```
