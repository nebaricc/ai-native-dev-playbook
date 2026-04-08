---
name: security/multi-tenancy
description: Multi-tenancy and tenant isolation — {TENANT_ID_FIELD} scoping, cross-tenant attack patterns. Load for any query or endpoint that touches tenant-scoped data.
user-invocable: false
---

# Multi-Tenancy

A data leak between tenants is a serious security and compliance incident. Every query touching tenant data must be scoped.

## {TENANT_ID_FIELD} on Every Query

Always from the auth context. Never from the request.

```typescript
// ✅ Correct — tenant ID from verified auth
const tenantId = ctx.{TENANT_ID_FIELD};
const rows = await db.query(
  'SELECT * FROM {TABLE} WHERE {TENANT_ID_FIELD} = $1 LIMIT $2',
  [tenantId, limit]
);

// ❌ Wrong — tenant ID from request (attacker-controlled)
const rows = await db.query(
  'SELECT * FROM {TABLE} WHERE {TENANT_ID_FIELD} = $1',
  [req.query.{TENANT_ID_FIELD}]
);

// ❌ Wrong — no tenant scoping (cross-tenant leak)
const rows = await db.query(
  'SELECT * FROM {TABLE} WHERE id = $1',
  [recordId]
);
```

## DB-Level Enforcement

{TENANT_ENFORCEMENT_MECHANISM}
<!-- Examples:
- PostgreSQL RLS: policies enforce tenant isolation at DB level (backstop, not primary defense)
- Firestore Security Rules: `request.auth.token.orgId == resource.data.orgId`
- Always enforce in application code too — defense in depth
-->

## Cross-Tenant Attack Patterns to Watch For

- **IDOR (Insecure Direct Object Reference)**: endpoint takes record ID in URL, fetches without tenant check → attacker enumerates IDs across tenants
- **Mass assignment**: `UPDATE {TABLE} SET fields WHERE id = $1` without `{TENANT_ID_FIELD} = $2` → attacker modifies any tenant's data
- **Aggregation leak**: `SELECT COUNT(*) FROM {TABLE}` without tenant scope → leaks tenant data sizes
- **Privilege escalation**: admin endpoint accessible to regular user role → missing role check

## Joins Must Preserve Isolation

When joining tables, the tenant filter on the anchor table may not be enough:

```sql
-- ✅ Safe — tenant filter on anchor table constrains the join
SELECT a.*, b.field
FROM {TABLE_A} a
JOIN {TABLE_B} b ON b.{TABLE_A}_id = a.id
WHERE a.{TENANT_ID_FIELD} = $1

-- ⚠️ Risky — if TABLE_B has its own tenant ID, verify it's also constrained
```

## Super Admin / Cross-Tenant Access

If your system has super admins that cross tenant boundaries, any such endpoint must:
1. Explicitly check super admin role before proceeding
2. Emit an audit log entry
3. Have a comment explaining the intentional cross-tenant access
