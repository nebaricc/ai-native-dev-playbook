---
name: sre
description: SRE and operational concerns — observability, stateless service constraints, health checks, graceful degradation, capacity guardrails. Load when building backend features or changing infrastructure.
user-invocable: false
---

# SRE & Operations

## Observability — Structured Logging

Always log as structured JSON — unstructured strings are unsearchable in log aggregators:

```typescript
// ✅ Structured — queryable in {LOG_PLATFORM}
console.error(JSON.stringify({
  severity: 'ERROR',
  component: '{COMPONENT_NAME}',
  requestId,
  tenantId,   // {TENANT_ID_FIELD}
  error: err.message,
}));

// ❌ Unstructured — hard to query
console.error('Query failed:', err);
```

**Never log**: PII (names, emails, {SENSITIVE_FIELDS}), secrets or tokens, full stack traces in production.
**Always include**: request/trace ID, tenant/org ID, component name, error type (not full message in prod).

## Stateless Service Constraints

Deployed services scale horizontally. Operational rules:

- **No in-memory caches** — invalidation is impossible across instances. Use DB or external cache ({CACHE_SOLUTION}).
- **No in-memory queues or job state** — use a queue service ({QUEUE_SOLUTION}) or DB-backed jobs.
- **Concurrency-safe**: module-level state must be read-only. No shared mutable state.
- **Cold start budget**: minimize startup time. Defer heavy initialization to first use.

## Health Checks

Every service exposes a health endpoint: `GET {HEALTH_PATH}` → 200.

Used by: load balancers, deploy scripts (block deploy if failing), uptime monitors.

Verify at minimum: service is running, DB/primary dependency is reachable.

## Graceful Degradation

Non-critical services failing should not take down the user-facing request:

- Audit/analytics writes: fire-and-forget, log failures to stderr, never surface to user
- Third-party enrichment: return cached/stale data rather than 500
- Background jobs: fail the job, alert on-call, don't fail the trigger request

## Capacity & Cost Guardrails

- Never call expensive external APIs (LLMs, enrichment, {EXPENSIVE_SERVICE}) per-row in a loop — batch or queue
- Every list query must have a `LIMIT` — unbounded reads will kill performance at scale
- Monitor bundle size — flag significant increases in PR review
- External API calls in hot paths need timeouts

## On-Call Runbook Starters

| Symptom | First check |
|---|---|
| 5xx spike | Service logs → filter by ERROR, look for common error message |
| Auth failures | {AUTH_PROVIDER} logs, check token/secret rotation |
| High latency | DB query times, check for missing indexes or missing LIMIT |
| Memory/OOM | Check for unbounded in-memory accumulation, increase instance memory |
| Missing audit events | Check for new endpoints that didn't call audit logger |
| Deploy failure | Health check endpoint, check last deploy logs |
