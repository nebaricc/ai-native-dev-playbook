---
name: security/owasp
description: OWASP Top 10 mapped to this project's stack. Use during security reviews or when unsure if a pattern is safe.
user-invocable: false
---

# OWASP Top 10 — {PROJECT} Mapping

## A01: Broken Access Control

**What it looks like**: endpoint fetches record by ID without verifying `{TENANT_ID_FIELD}` → users can access other tenants' data by guessing IDs.

**Prevention**: `{TENANT_ID_FIELD}` on every data query from auth context. Role checks on privileged operations. Audit logs on sensitive reads.

## A02: Cryptographic Failures

**What it looks like**: storing sensitive data unencrypted, weak JWT algorithms, hardcoding secrets.

**Prevention**: use platform encryption at rest (don't disable it). Strong signing algorithms for JWTs. Secrets in `{SECRETS_MANAGER}` only. No sensitive data in URLs.

## A03: Injection

**What it looks like**: `SELECT * FROM table WHERE field = '${userInput}'`

**Prevention**: parameterized queries always. See `security/input-validation.md`. Dynamic identifiers use allowlists, never string interpolation.

## A04: Insecure Design

**What it looks like**: confused deputy — service fetching secrets per-request; endpoints that do more than the caller should trigger.

**Prevention**: secrets loaded at startup. Each endpoint does one thing at the right privilege level. Design threat models for sensitive features.

## A05: Security Misconfiguration

**What it looks like**: over-broad permissions, debug info in production responses, default credentials.

**Prevention**: least-privilege IAM/roles. Error messages scrubbed in production. No `console.log(process.env.*)`. CORS restricted to known origins.

## A07: Identification and Authentication Failures

**What it looks like**: trusting client-decoded tokens, missing token expiry checks, reusing secrets across environments.

**Prevention**: server-side token verification via `{AUTH_PROVIDER}` SDK. Dev bypass only outside production. Per-environment secrets.

## A08: Software and Data Integrity Failures

**What it looks like**: accepting file uploads without structure validation, processing webhook payloads without signature verification.

**Prevention**: validate file/payload structure before processing. Verify webhook signatures (HMAC) before acting on events.

## A09: Security Logging and Monitoring Failures

**What it looks like**: new endpoint added without audit logging → compliance gaps; errors swallowed silently.

**Prevention**: audit log on every sensitive data access. Errors always logged with trace ID. Log aggregation monitored for anomalies.

## A10: Server-Side Request Forgery (SSRF)

**What it looks like**: endpoint accepts a URL and fetches it server-side → pointed at internal metadata endpoints or internal services.

**Prevention**: never fetch user-supplied URLs without strict allowlisting. Validate scheme (https only) and block private IP ranges if URL fetching is needed.
