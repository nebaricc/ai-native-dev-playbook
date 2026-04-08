# {PROJECT}

## Project Overview

{PROJECT_DESCRIPTION}

| Package | Path | Purpose |
|---------|------|---------|
| {PACKAGE_1} | `{PACKAGE_1_PATH}` | {PACKAGE_1_PURPOSE} |
| {PACKAGE_2} | `{PACKAGE_2_PATH}` | {PACKAGE_2_PURPOSE} |

## Commands

```bash
{PACKAGE_MANAGER} install            # Install dependencies
{PACKAGE_MANAGER} run dev            # Start dev server
{PACKAGE_MANAGER} run build          # Production build
{PACKAGE_MANAGER} run test           # Run unit tests
{PACKAGE_MANAGER} run test:e2e       # Run E2E tests
{PACKAGE_MANAGER} run lint           # Lint (ESLint)
{PACKAGE_MANAGER} run lint --fix     # Lint with auto-fix
{PACKAGE_MANAGER} run type-check     # TypeScript type checking
{PACKAGE_MANAGER} run format         # Format (Prettier)
```

## Git Conventions

- **Commits**: Conventional Commits -- `type(scope): description`
  - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `style`, `perf`
- **Branches**: `{TICKET_PREFIX}-123-short-description` from `{DEV_BRANCH}`
- **PRs**: Target `{DEV_BRANCH}`. Title matches commit format: `type(scope): description ({TICKET_PREFIX}-123)`
- **No force pushes**. No `git add .` -- commit specific files.
- **PR size**: Keep under 10 files changed. Split larger work into stacked PRs.

## Deployment Pipeline

| Stage | Branch | URL |
|-------|--------|-----|
| Development | `{DEV_BRANCH}` | {DEV_URL} |
| Staging | `{STAGING_BRANCH}` | {STAGING_URL} |
| Production | `{MAIN_BRANCH}` | {PROD_URL} |

## Code Style

- TypeScript strict mode. No `any` -- use `unknown` + type guards.
- Named exports only (no default exports).
- Explicit return types on exported functions.
- Errors: return `Result<T, E>` or throw typed errors -- never swallow silently.
- Imports: Node built-ins > external packages > internal aliases > relative paths.
- Destructure props/params. Prefer `const` over `let`.

## Clean Code & Design Principles

### Function Quality (Clean Code)
- **Max 40 lines per function.** If longer, extract helpers. This is a hard limit, not a guideline.
- **One responsibility per function.** A function that fetches, transforms, and writes should be three functions.
- **Descriptive names.** `isLoading`, `handleSubmit`, `getUserById` -- not `x`, `tmp`, `data2`.
- **No dead code.** No commented-out blocks, no unused imports, no unreachable branches. Delete it.
- **No magic numbers.** Extract to named constants: `const MAX_RETRIES = 3`, not bare `3` in code.

### DRY (Don't Repeat Yourself)
- Extract shared logic into utility functions or hooks after **3 instances** of duplication.
- Use generics to avoid duplicating type-safe patterns.
- **But:** prefer duplication over the wrong abstraction. Two similar 5-line blocks are better than a premature helper.

### SOLID Principles
- **Single Responsibility:** Each module, component, and function does one thing. If you need "and" to describe it, split it.
- **Open/Closed:** Extend behavior via composition (hooks, middleware, decorators), not by modifying existing functions.
- **Interface Segregation:** Prefer small, focused interfaces. `UserAuth` and `UserProfile` over a single `User` god-type.
- **Dependency Inversion:** Business logic depends on abstractions (interfaces/types), not concrete implementations. Inject dependencies, don't import singletons.

## Architecture

### Directory Structure
```
{DIRECTORY_STRUCTURE}
```

### Key Patterns
- {PATTERN_1}
- {PATTERN_2}
- {PATTERN_3}

### State Management
{STATE_MANAGEMENT_APPROACH}

### API Layer
{API_LAYER_APPROACH}

## Quality Standards

- All new code must have tests. Minimum coverage: {COVERAGE_THRESHOLD}%.
- No lint warnings in changed files.
- Type-check must pass with zero errors.
- Tests must pass before pushing.
- Visual regression baselines updated when UI changes.

## Scaling & Architecture

- **Stateless services**: Deployed services are ephemeral and horizontally scaled. Never store state in memory (caches, counters, in-flight data) — use the database or an external store.
- **Bounded queries**: Every list query must have a `LIMIT`. Never return unbounded result sets. Paginate all collection endpoints.
- **Avoid unnecessary encoding**: Don't base64-encode data that stays inside the system. Only encode at actual transport boundaries.
- **No confused deputy**: Secrets loaded at startup via environment injection, not fetched per-request inside user-facing handlers.

## Testing Quality

- **No weak assertions**: `.toBeDefined()`, `.toBeTruthy()`, `.not.toBeNull()` pass for almost any value. Assert the actual shape: `.toEqual(...)`, `.toBe(true)`, `.toHaveLength(n)`.
- **Test names describe behavior**: Format `[action] when [condition]` — names should read like requirements, not implementation.
- **Trust but verify**: After any agent writes tests, introduce a deliberate bug and confirm the test catches it. If it doesn't, the assertions are too weak.

## Security

- Never commit secrets, `.env` files, or credentials.
- Always use parameterized queries — never string interpolation.
- Validate and sanitize all user input via schema (Zod, Joi, etc.).
- Enforce tenant/org scoping on every query — derive from auth context, never from request params.

**Load `.claude/skills/security/SKILL.md` whenever building or reviewing any feature.**

**Load `.claude/skills/compliance/SKILL.md` for any feature touching user data, logging, auth, or data exports. Proactively flag missing audit logs, unscoped queries, and PII in logs without being asked.**

## Agent Behavior Rules

1. Read this file and referenced skills before writing code.
2. Plan before coding -- outline approach, identify affected files.
3. Run lint + type-check + tests before every commit.
4. Commit specific files with conventional commit messages.
5. Never force push, never `git add .`, never skip pre-commit hooks.
6. Keep PRs under 10 files. Split into stacked PRs if larger.
7. Every source change ships with corresponding tests.
8. Track a change budget -- stop and reassess if exceeding scope.
9. Ask clarifying questions before making assumptions on ambiguous requirements.
10. Verify your own output -- check test results, screenshots, build artifacts.

## Continuous Improvement

When a CI failure, bug, or review finding reveals a pattern not yet covered by these standards, add a new rule to the appropriate section (CLAUDE.md or a skill file) as part of the fix.

**Skill gap nagging**: If a recurring question, pattern, or mistake comes up that isn't covered by an existing skill, flag it: "This keeps coming up — should we add it to `.claude/skills/`?" Do not silently let gaps accumulate.

## Definition of Done

- [ ] Code compiles (`{PACKAGE_MANAGER} run type-check`)
- [ ] Lint passes (`{PACKAGE_MANAGER} run lint`)
- [ ] Tests pass (`{PACKAGE_MANAGER} run test`)
- [ ] New code has test coverage
- [ ] PR is under 10 files changed
- [ ] Commit messages follow conventional format
- [ ] No `any` types introduced
- [ ] PR description includes what/why and test plan
