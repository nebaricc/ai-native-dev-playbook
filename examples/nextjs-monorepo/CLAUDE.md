# CLAUDE.md -- Acme Dashboard

## Project Overview

Acme Dashboard is a SaaS analytics platform built as a pnpm monorepo. Customers
use the web app to visualize business metrics. The API serves both the web app
and third-party integrations.

## Architecture

```
apps/
  web/          -- Next.js 14 App Router (customer dashboard)
  api/          -- Next.js Pages Router (REST API, /api/v1/*)
packages/
  database/     -- Drizzle ORM schemas, migrations, seed scripts
  shared/       -- Zod validation schemas, TypeScript types, constants
```

## Tech Stack

- Runtime: Node.js 20 LTS
- Package manager: pnpm 9.x (workspaces)
- Build orchestration: Turborepo
- Database: PostgreSQL 16 via Drizzle ORM
- Auth: Firebase Auth (JWT verification in API middleware)
- Styling: Tailwind CSS + shadcn/ui
- Testing: Vitest (unit), Playwright (E2E)
- CI: GitHub Actions

## Branch Strategy

- Default branch: `development`
- Production branch: `main`
- Feature branches: `feat/PROJ-123-short-description`
- Bug fix branches: `fix/PROJ-456-short-description`
- Always branch from `development`, PR back to `development`

## Ticket System

- Jira project prefix: PROJ
- Include ticket ID in branch names and PR titles
- PR title format: `type(scope): description (PROJ-123)`

## Commands

```bash
# Install dependencies
pnpm install

# Development
pnpm dev                          # Start all apps (turbo)
pnpm dev --filter=apps/web        # Start web only
pnpm dev --filter=apps/api        # Start API only

# Build
pnpm build                        # Build all packages
pnpm build --filter=apps/web      # Build web only

# Testing
pnpm test                         # Run all tests
pnpm test --filter=apps/web       # Test web only
pnpm vitest run                   # Unit tests (no watch)
pnpm playwright test              # E2E tests (requires running app)

# Database
pnpm --filter=packages/database db:generate   # Generate migration from schema changes
pnpm --filter=packages/database db:migrate    # Apply pending migrations
pnpm --filter=packages/database db:seed       # Seed development data
pnpm --filter=packages/database db:studio     # Open Drizzle Studio

# Linting & Formatting
pnpm lint                         # ESLint across all packages
pnpm lint:fix                     # Auto-fix lint issues
pnpm format                       # Prettier format
pnpm typecheck                    # TypeScript check all packages
```

## Code Conventions

- Use named exports, not default exports (except Next.js pages/layouts)
- Colocate tests: `component.tsx` -> `component.test.tsx` in same directory
- API routes return `{ data, error, meta }` envelope
- All API request/response bodies validated with Zod schemas from `packages/shared`
- Database queries go through repository pattern in `packages/database/src/repositories/`
- Use `@acme/database` and `@acme/shared` workspace imports, never relative paths across packages
- Server components by default; add `"use client"` only when needed
- Environment variables: validated at startup via `packages/shared/src/env.ts`

## File Naming

- React components: `PascalCase.tsx`
- Utilities and hooks: `camelCase.ts`
- Database schemas: `kebab-case.ts` (e.g., `user-sessions.ts`)
- Test files: `*.test.ts` or `*.test.tsx`
- E2E tests: `tests/e2e/*.spec.ts`

## Error Handling

- API routes: wrap handlers with `withErrorHandler()` from `apps/api/src/lib/errors.ts`
- Use custom `AppError` class with HTTP status codes
- Never expose internal error details to clients in production
- Log errors with structured logging via `pino`

## Environment Variables

- `.env.local` for local development (git-ignored)
- `.env.example` checked into repo with placeholder values
- Access via `env()` helper from `@acme/shared`, never `process.env` directly
- Required vars validated at build time

## Testing Requirements

- New features require unit tests for business logic
- API endpoints require integration tests
- UI flows require Playwright E2E tests for happy path
- Minimum coverage target: 70% lines on changed files

## PR Requirements

- All checks must pass (lint, typecheck, test)
- At least one approval required
- Squash merge to `development`
- Delete branch after merge
