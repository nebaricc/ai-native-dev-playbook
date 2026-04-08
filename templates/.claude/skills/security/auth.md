---
name: security/auth
description: Auth patterns — token verification, session handling, role checks. Load when building or reviewing any endpoint or auth-related code.
user-invocable: false
---

# Authentication Patterns

## Standard Auth Flow — Every Endpoint

```typescript
// Pseudocode — adapt to your auth middleware
export default async function handler(req, res) {
  // 1. Method guard — before auth
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  // 2. Auth — always before data access
  const ctx = await {AUTH_CONTEXT_FUNCTION}(req);
  if (!ctx) return res.status(401).json({ error: 'Unauthorized' });

  // ctx.userId, ctx.{TENANT_ID_FIELD}, ctx.role are now verified
  // Never use req.body.userId or req.query.{TENANT_ID_FIELD}
}
```

## Token Verification

Tokens must be verified **server-side** using your auth provider's SDK. Never trust client-decoded claims.

```typescript
// ✅ Server-side verification — trustworthy
const ctx = await verifyToken(req.headers.authorization);

// ❌ Client-decoded — attacker-controlled
const claims = JSON.parse(atob(token.split('.')[1]));
```

## Role Checks

Define roles in `{ROLES_DEFINITION}`. Check roles explicitly:

```typescript
if (ctx.role !== '{ADMIN_ROLE}') {
  return res.status(403).json({ error: 'Forbidden' });
}
```

## Auth Error Messages

Return generic messages — never leak why auth failed:

```typescript
// ✅ Generic
return res.status(401).json({ error: 'Unauthorized' });

// ❌ Leaks implementation detail
return res.status(401).json({ error: 'Token expired at 2026-01-01' });
return res.status(401).json({ error: 'User not found: john@example.com' });
```

## Dev/Test Mode

If you have a dev auth bypass, ensure it is **only active outside production**:

```typescript
if (process.env.NODE_ENV !== 'production' && process.env.DEV_AUTH_BYPASS) {
  return devContext;
}
```

## Common AI Auth Mistakes

- Skipping auth on new endpoints entirely
- Trusting `req.body.userId` instead of `ctx.userId`
- Missing method guard before auth check
- No role check on admin-only operations
- Dev bypass left active in production builds
