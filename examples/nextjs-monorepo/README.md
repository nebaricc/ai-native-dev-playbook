# Next.js pnpm Monorepo Example

This example shows a filled-in AI-native configuration for a typical SaaS application
built as a pnpm monorepo with Next.js.

## Stack

- **apps/web** -- Next.js 14 App Router (customer-facing dashboard)
- **apps/api** -- Next.js Pages Router (REST API endpoints)
- **packages/database** -- Drizzle ORM + PostgreSQL migrations
- **packages/shared** -- Zod schemas, shared types, constants

## Key Choices

- **pnpm workspaces** for dependency management
- **PostgreSQL** via Drizzle ORM
- **Firebase Auth** for authentication
- **Turborepo** for build orchestration
- **Vitest** for unit tests, Playwright for E2E
- Branch model: feature branches from `development`, PRs to `development`
- Jira ticket prefix: `PROJ`

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code project instructions |
| `.cursorrules` | Cursor IDE rules |
| `.claude/settings.json` | Allowed/denied commands for Claude |
| `.cursor/rules/api-routes.mdc` | API route conventions |
| `.cursor/rules/components.mdc` | React component conventions |
