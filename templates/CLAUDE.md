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

## Definition of Done

- [ ] Code compiles (`{PACKAGE_MANAGER} run type-check`)
- [ ] Lint passes (`{PACKAGE_MANAGER} run lint`)
- [ ] Tests pass (`{PACKAGE_MANAGER} run test`)
- [ ] New code has test coverage
- [ ] PR is under 10 files changed
- [ ] Commit messages follow conventional format
- [ ] No `any` types introduced
- [ ] PR description includes what/why and test plan
