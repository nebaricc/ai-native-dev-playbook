# CLAUDE.md -- Signalboard

## Project Overview

Signalboard is a real-time team coordination platform. Users manage projects and
signals through a web dashboard, receive notifications via a Discord bot, and
backend logic runs on Cloud Functions triggered by Firestore events and HTTP requests.

## Architecture

```
apps/
  web/            -- Next.js 14 App Router (customer dashboard, Firebase Hosting)
  functions/      -- Cloud Functions v2 (TypeScript, event triggers + HTTP)
  bot/            -- Discord.js bot (deployed to Cloud Run)
databases/
  firestore.rules -- Firestore security rules
  firestore.indexes.json -- Composite index definitions
```

## Tech Stack

- Runtime: Node.js 20 LTS
- Package manager: npm 10.x (workspaces)
- Database: Firestore (with offline persistence in web app)
- Auth: Firebase Auth with custom claims (`role`, `orgId`)
- Hosting: Firebase Hosting (web), Cloud Functions v2 (backend), Cloud Run (bot)
- Styling: Tailwind CSS + custom design system (`@sig/ui`)
- Testing: Vitest (unit), Firebase Emulator Suite (integration)
- CI: GitHub Actions

## Branch Strategy

- Default branch: `dev`
- Production branch: `main`
- Feature branches: `feat/SIG-123-short-description`
- Bug fix branches: `fix/SIG-456-short-description`
- Always branch from `dev`, PR back to `dev`
- Releases: merge `dev` -> `main` triggers production deploy

## Ticket System

- Jira project prefix: SIG
- Include ticket ID in branch names and PR titles
- PR title format: `type(scope): description (SIG-123)`

## Commands

```bash
# Install all workspace dependencies
npm install

# Development
npm run dev -w apps/web               # Start web app (port 3000)
npm run dev -w apps/functions          # Start functions emulator
npm run dev -w apps/bot                # Start bot in dev mode
npm run emulators                      # Start full Firebase Emulator Suite

# Build
npm run build                          # Build all workspaces
npm run build -w apps/web              # Build web only
npm run build -w apps/functions        # Build functions only

# Testing
npm test                               # Run all tests
npm test -w apps/web                   # Test web only
npm test -w apps/functions             # Test functions only
npm run test:emulator                  # Integration tests against emulators

# Deploy
npm run deploy:hosting                 # Deploy web to Firebase Hosting
npm run deploy:functions               # Deploy Cloud Functions
npm run deploy:rules                   # Deploy Firestore rules + indexes

# Linting & Formatting
npm run lint                           # ESLint across all workspaces
npm run lint:fix                       # Auto-fix lint issues
npm run format                         # Prettier format
npm run typecheck                      # TypeScript check all workspaces
```

## Deterministic agent workflow

Borrowed from harness-style agent orchestration: **fix the sequence**, let the model fill in the work at each step. Same phases every time reduces skipped tests and inconsistent PRs.

| Phase | Do |
|-------|-----|
| **Classify** | Decide: bug, feature, refactor, chore, docs, or investigation. If the ask is ambiguous, ask one clarifying question before coding. |
| **Context** | Read this file, project rules, and similar code in the repo before editing. |
| **Plan** | For 3+ files or cross-package changes: list steps, files, and risks; keep the plan in the session until the PR is up. |
| **Implement** | Small steps; prefer scripts and test commands over guessing outcomes. |
| **Validate** | Run type-check, lint, and tests locally before push. CI is a backstop, not the first check. |
| **Review** | Re-read the diff; map every changed source file to a test or a short reason it cannot be tested. |
| **Ship** | Branch, commit, push, open PR using the team template and definition of done. |

**Isolation:** Use a **dedicated branch** per task. For parallel agent work, use **separate git worktrees** so runs do not overwrite each other.

**Artifacts:** When investigation or planning matters, keep a short **plan** (session summary or `plan.md` if the team uses it) so implementation does not drift from agreed scope.

**Loops:** **Implement until green** (fix and re-run tests until they pass). **Review until done** (address feedback on the same branch before merge).

## Firestore Data Model

Collections follow this pattern:
- `orgs/{orgId}` -- Organization documents
- `orgs/{orgId}/projects/{projectId}` -- Projects within an org
- `orgs/{orgId}/signals/{signalId}` -- Signals (the core entity)
- `orgs/{orgId}/members/{userId}` -- Org membership + roles
- `users/{userId}` -- User profile (cross-org)

All documents include `createdAt`, `updatedAt` (Timestamps), and `createdBy` (userId).

## Code Conventions

- Use named exports everywhere except Next.js pages/layouts.
- Firestore access through service classes in `apps/functions/src/services/`.
- Web app Firestore reads use React hooks from `apps/web/src/hooks/firestore/`.
- Shared types in root `types/` directory, imported as `@sig/types`.
- Design system components in `packages/ui/`, imported as `@sig/ui`.
- All Firestore writes must go through Cloud Functions (never write directly from web).
- Use `converter<T>()` pattern for typed Firestore document access.
- Environment variables prefixed: `NEXT_PUBLIC_` for web, `SIG_` for functions/bot.

## File Naming

- React components: `PascalCase.tsx`
- Cloud Functions handlers: `kebab-case.ts` (e.g., `on-signal-created.ts`)
- Firestore converters: `*.converter.ts`
- Test files: `*.test.ts` or `*.test.tsx`

## Error Handling

- Cloud Functions: `HttpsError` with codes for callable functions. Retry transient failures.
- Web app: error boundaries per route segment. Bot: log and send user-friendly embeds.

## Security and Testing

- All Firestore rules in `databases/firestore.rules`. Never deploy without `npm run test:rules`.
- Rules must enforce org-scoping: users can only read/write within their `orgId`.
- Cloud Functions: unit test each handler with mocked Firestore.
- Firestore rules: test with `@firebase/rules-unit-testing`.
- Web components: test with Vitest + Testing Library.
- Integration tests run against Firebase Emulator Suite in CI.
- New features require tests before merge.
