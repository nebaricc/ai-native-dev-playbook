---
name: security/input-validation
description: Input validation patterns — schema validation, SQL parameterization, pagination bounds, file uploads. Load when building any endpoint that accepts user input.
user-invocable: false
---

# Input Validation

## Schema Validation — All External Input

Every endpoint that accepts user input must validate it with a schema ({VALIDATION_LIBRARY}) before use:

```typescript
import { z } from 'zod';  // or your validation library

const QuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),  // max bound required
  search: z.string().max(200).optional(),
});

const parsed = QuerySchema.safeParse(req.query);
if (!parsed.success) {
  return res.status(400).json({ error: 'Invalid parameters' });
}
```

## Pagination Bounds — Always

Never trust client-supplied `limit` without a cap. Without it, `limit=1000000` reads the full table.

```typescript
// ✅ Bounded
const limit = Math.min(Math.max(parseInt(req.query.limit) || 20, 1), 100);

// ❌ Unbounded
const limit = parseInt(req.query.limit);
```

## SQL — Parameterized Only

```typescript
// ✅ Safe
await db.query(
  'SELECT * FROM {TABLE} WHERE {TENANT_ID_FIELD} = $1 AND name ILIKE $2 LIMIT $3',
  [tenantId, `%${search}%`, limit]
);

// ❌ SQL injection
await db.query(`SELECT * FROM {TABLE} WHERE name ILIKE '%${search}%'`);
```

For dynamic ORDER BY (column name can't be parameterized), use an allowlist:

```typescript
const ALLOWED_COLUMNS = ['{COLUMN_1}', '{COLUMN_2}'] as const;
const sortBy = ALLOWED_COLUMNS.includes(req.query.sort) ? req.query.sort : '{COLUMN_1}';
await db.query(`SELECT * FROM {TABLE} ORDER BY ${sortBy} LIMIT $1`, [limit]);
```

## File Uploads

- Validate MIME type from file headers, not `Content-Type` (client-controlled)
- Enforce max file size before reading the full body
- Validate file structure/schema before processing
- Never execute or eval file contents
- Scan for malicious content if processing untrusted files

## URL / Path Parameters

Validate before use — never assume route params are safe:

```typescript
const id = req.params.id;
if (!id || typeof id !== 'string') {
  return res.status(400).json({ error: 'Missing ID' });
}
// Optionally validate format (UUID, numeric, etc.)
```
