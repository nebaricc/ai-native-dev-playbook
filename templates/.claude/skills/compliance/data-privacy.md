---
name: compliance/data-privacy
description: Data privacy rules — audit logging, tenant scoping, PII in logs, data access controls. Load when building any feature that reads or writes user records.
user-invocable: false
---

# Data Privacy

## Audit Logging — Required for Sensitive Data Access

Every endpoint reading or writing {SENSITIVE_DATA_TYPE} must emit an audit event. This is not optional for {COMPLIANCE_FRAMEWORK} compliance.

Key fields every audit event must include:
- **Who**: user ID, role — never names or emails
- **What**: entity type + entity ID (e.g. `student`, `survey-response`)
- **Where**: request path — strip query strings, they may contain PII or tokens
- **Outcome**: HTTP status code, duration

```typescript
// Pseudocode — adapt to your audit logger
auditLog({
  userId: ctx.userId,
  tenantId: ctx.{TENANT_ID_FIELD},
  action: 'READ',               // READ | CREATE | UPDATE | DELETE
  entityType: '{ENTITY_TYPE}',
  entityId: recordId,
  httpMethod: req.method,
  httpPath: req.url.split('?')[0],  // strip query string
  statusCode: 200,
});
```

**Never include in audit events**: names, emails, PII, raw request/response bodies, secrets or tokens.

## Tenant Scoping — Every Query

Every query touching user data must scope to `{TENANT_ID_FIELD}` from the auth context — never from query params or request body.

```typescript
// ✅ Correct — tenant ID from verified auth
const tenantId = ctx.{TENANT_ID_FIELD};
const records = await db.query(
  'SELECT * FROM {TABLE} WHERE {TENANT_ID_FIELD} = $1',
  [tenantId]
);

// ❌ Wrong — tenant ID from request (attacker-controlled)
const tenantId = req.params.{TENANT_ID_FIELD};
```

## PII in Logs — Prohibited

Logs are retained, auditable, and often more broadly accessible than the DB.

**PII includes**: {PII_FIELDS} — name, email, date of birth, address, phone, health data, financial data.
**Safe to log**: IDs (UUIDs), `{TENANT_ID_FIELD}`, request IDs, HTTP status codes, error types (not messages in prod).

## Data Minimization

Before adding any new field associated with a user:
1. What is the purpose of collecting this?
2. Can the feature work with less (e.g. age range instead of DOB)?
3. How long is this data retained? Does it need a TTL?

## Third-Party Data Sharing

Before sending user data to any external service:
- [ ] Signed DPA (Data Processing Agreement) exists with this vendor
- [ ] Purpose is documented and limited to what's in the contract
- [ ] Data is minimized to only what the vendor actually needs
- [ ] Vendor is listed in your privacy policy / data map

## Checklist for New Endpoints

- [ ] Audit log emitted with correct action and entity type
- [ ] Request path stripped of query string before logging
- [ ] All queries include `{TENANT_ID_FIELD}` from auth context, not request
- [ ] No PII in `console.log` / `console.error`
- [ ] Response does not include more fields than the feature needs
- [ ] If sharing with a third party — DPA confirmed
