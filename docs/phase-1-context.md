# Phase 1: Context as Code

## What context files are and why they matter

AI coding tools start every session with zero knowledge of your project. They don't know your ORM, your auth pattern, your test framework, or your import conventions. Without context, they guess. They guess wrong about 40% of the time, and every wrong guess costs you review cycles.

Context files fix this. They are checked-in configuration files that tell AI tools how your project works. Not aspirational architecture docs -- actual patterns, actual commands, actual rules that the AI reads before writing a single line of code.

The goal: an AI agent should be able to clone your repo, read the context files, and produce a PR that passes review on the first try.

---

## CLAUDE.md

CLAUDE.md is the primary context file for Claude Code. It lives at the repo root and is automatically loaded at the start of every session. Keep it under 200 lines. This is not documentation for humans -- it is an instruction set for an AI agent.

### What to include

**Project overview.** Name, tech stack, package structure. Enough for the agent to know what it's working with.

```markdown
# Pebble

Multi-tenant SaaS platform for project management.

| Package | Path | Purpose |
|---------|------|---------|
| web | `apps/web/` | Next.js 14 frontend |
| backend | `apps/backend/` | NestJS API |
| database | `packages/database/` | Drizzle ORM schema + migrations |
```

**Commands.** Every command the agent needs to run. Do not assume it knows your package manager.

```markdown
## Commands

pnpm install              # Install dependencies
pnpm run dev              # Start dev server
pnpm run build            # Production build
pnpm run test             # Unit tests (Vitest)
pnpm run lint             # ESLint
pnpm run type-check       # TypeScript strict
pnpm run test:e2e         # Playwright E2E
```

**Git conventions.** Branch naming, commit format, PR rules. Be explicit about the dev branch name -- it varies across projects (`dev`, `develop`, `development`).

```markdown
## Git Conventions

- Commits: `type(scope): description` (feat, fix, refactor, test, docs, chore, ci)
- Branches: `PEB-123-short-description` from `development`
- PRs: Target `development`. Title: `type(scope): description (PEB-123)`
- No force pushes. No `git add .`. Commit specific files.
- PRs under 10 files. Split larger work into stacked PRs.
```

**Code patterns.** Show the actual pattern, not a description of it. "We use Drizzle" is not enough. Show a query, an error handler, a service return type.

```markdown
## Error Handling

Services return Result tuples. Never throw from a service function.

```typescript
// Correct
export async function getUser(id: string): Promise<Result<User>> {
  const user = await db.query.users.findFirst({ where: eq(users.id, id) });
  if (!user) return { data: null, error: new NotFoundError("User not found") };
  return { data: user, error: null };
}

// Wrong -- do not throw from services
export async function getUser(id: string): Promise<User> {
  const user = await db.query.users.findFirst({ where: eq(users.id, id) });
  if (!user) throw new Error("User not found");
  return user;
}
```

**Agent behavior rules.** The 10 rules (covered in full below).

**Definition of Done.** A checklist the agent checks before declaring work complete.

### What NOT to include

- Full API documentation (link to it instead)
- Onboarding instructions for humans
- History or changelog
- Anything over 200 lines -- move detailed patterns into `.claude/skills/`

### Common mistakes

1. **Aspirational rules.** "Follow clean architecture" means nothing to an agent. Say "services go in `src/services/`, return `Result<T>` tuples, never import from `src/components/`."
2. **Too long.** Over 200 lines and the agent starts ignoring the end. Move detailed patterns to skills files.
3. **Only on main.** If your dev branch is `development` and CLAUDE.md only exists on `main`, agents branching from `development` never see it. Push to both.
4. **Missing commands.** The agent will try `npm test` if you don't tell it your project uses `pnpm run test`.

---

## Multi-tool configuration

Most teams use more than one AI tool. Claude Code, Cursor, and GitHub Copilot each read different config files. Here is how to configure all of them without maintaining three copies of the same rules.

### .cursorrules

This file sits at the repo root and is loaded by Cursor on every session. It must be **standalone and comprehensive**. Do not write a `.cursorrules` that says "Read CLAUDE.md for project rules." This fails for two reasons:

1. **Cursor's config loading is fragile.** The "Include third-party configs" setting that reads CLAUDE.md is unreliable -- it may not load, may load partially, or may be disabled by the user.
2. **Cursor does not have a `Read` tool by default.** Unlike Claude Code, Cursor cannot reliably read arbitrary files on demand during its planning phase.

Your `.cursorrules` should contain the same standards as CLAUDE.md, written inline:

```
# Project: Pebble

## Tech Stack
Next.js 14, NestJS, Drizzle ORM, PostgreSQL, Playwright, Vitest

## Commands
pnpm install / pnpm run dev / pnpm run build / pnpm run test / pnpm run lint

## Git Conventions
- Conventional commits: type(scope): description
- Branch from `development`, PR to `development`
- Keep PRs under 10 files

## Code Style
- TypeScript strict. No `any`.
- Named exports only.
- Services return Result<T> tuples, never throw.

## Agent Behavior Rules
1. Read context files before writing code.
2. Plan before coding.
3. Run lint + type-check + tests before every commit.
4. Commit specific files with conventional messages.
5. Never force push or git add .
6. Keep PRs under 10 files.
7. Every source change ships with tests.
8. Track change budget -- reassess if exceeding scope.
9. Ask before assuming on ambiguous requirements.
10. Verify your own output.
```

Yes, this duplicates content from CLAUDE.md. That is intentional. Each tool needs its own self-contained config. CLAUDE.md is the source of truth; `.cursorrules` is a copy tailored for Cursor.

### .cursor/rules/*.mdc

File-scoped rules that activate when Cursor edits files matching a glob pattern. These use MDC (Markdown Components) frontmatter to specify which files they apply to.

```markdown
<!-- .cursor/rules/tests.mdc -->
---
description: Test file conventions
globs: ["**/*.test.ts", "**/*.test.tsx", "**/*.spec.ts"]
---

# Test Conventions

- Framework: Vitest + React Testing Library
- Never use `.toBeDefined()` alone -- assert specific values or DOM state
- Use `screen.getByRole()` over `getByTestId()` where possible
- Test behavior, not implementation (don't assert CSS classes)
- Include error/empty state tests, not just happy path
- Mock external services, not internal modules
```

```markdown
<!-- .cursor/rules/components.mdc -->
---
description: React component patterns
globs: ["**/components/**/*.tsx", "**/app/**/*.tsx"]
---

# Component Conventions

- Named exports only: `export function UserCard()`
- Props interface above the component: `interface UserCardProps {}`
- Use `cn()` for conditional classNames (from @/lib/utils)
- Server Components by default. Add "use client" only when needed.
- Colocate component tests: `UserCard.test.tsx` next to `UserCard.tsx`
```

```markdown
<!-- .cursor/rules/api-routes.mdc -->
---
description: API route handler patterns
globs: ["**/app/api/**/*.ts", "**/routes/**/*.ts"]
---

# API Route Conventions

- Validate input with Zod schemas
- Return typed responses: `NextResponse.json<ResponseType>()`
- Handle errors with try/catch at the route level, not in services
- Auth check at top of every handler: `const session = await getSession()`
- Log errors before returning error responses
```

```markdown
<!-- .cursor/rules/database.mdc -->
---
description: Database and schema conventions
globs: ["**/schema/**/*.ts", "**/migrations/**/*.ts", "**/db/**/*.ts"]
---

# Database Conventions

- ORM: Drizzle with PostgreSQL
- Schema files in packages/database/schema/
- Always use transactions for multi-table writes
- Soft delete pattern: `deletedAt` column, filter in queries
- New tables need a migration: `pnpm run db:generate`
```

### .claude/settings.json

Controls which commands Claude Code can run without prompting for permission. Without this, the agent asks "Can I run this?" for every shell command, which breaks flow.

```json
{
  "permissions": {
    "defaultMode": "plan",
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(pnpm run lint)",
      "Bash(pnpm run type-check)",
      "Bash(pnpm run test*)",
      "Bash(pnpm run build)",
      "Bash(git *)",
      "Bash(gh *)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)",
      "Bash(rm -rf*)"
    ]
  }
}
```

Adapt the allow list to your package manager and test runner:

| Project uses | Allow pattern |
|-------------|---------------|
| npm | `Bash(npm run test*)`, `Bash(npm run lint)` |
| pnpm | `Bash(pnpm run test*)`, `Bash(pnpm run lint)` |
| yarn | `Bash(yarn test*)`, `Bash(yarn lint)` |
| make | `Bash(make test)`, `Bash(make lint)` |

### .claude/skills/

Skills are markdown files that provide on-demand domain knowledge. Unlike CLAUDE.md (always loaded), skills are loaded only when relevant. Use skills for detailed patterns that would bloat CLAUDE.md past 200 lines.

```
.claude/skills/
  visual-testing.md      # Playwright visual regression patterns
  auth-patterns.md       # Authentication flow details
  deployment.md          # Deploy process and environment config
  database-migrations.md # Migration workflow and gotchas
```

**When to use skills vs CLAUDE.md:**
- CLAUDE.md: rules that apply to every task (git conventions, code style, agent behavior)
- Skills: detailed knowledge needed only for specific tasks (visual test setup, migration workflow)

Skills are referenced from CLAUDE.md with a pointer: "See `.claude/skills/visual-testing.md` for visual regression test patterns."

### .github/copilot-instructions.md

For teams using GitHub Copilot. This file is loaded by Copilot in VS Code and on github.com.

```markdown
# Copilot Instructions

## Tech Stack
Next.js 14, NestJS, Drizzle ORM, PostgreSQL

## Code Style
- TypeScript strict mode, no `any`
- Named exports only
- Services return Result<T> tuples

## Testing
- Vitest + React Testing Library
- Every new function/component needs a test file
```

Copilot has more limited context handling than Claude Code or Cursor. It does not support file-scoped rules, skills, or permission configs. Keep this file short and focused on code generation patterns.

### Keeping configs in sync

To **bootstrap or refresh** multiple repositories from this playbook's `templates/` (sync script, subtree, or manual copy), see [playbook-as-dependency.md](playbook-as-dependency.md).

CLAUDE.md is the source of truth. When you update a rule in CLAUDE.md, propagate it:

| Source | Copies to |
|--------|-----------|
| CLAUDE.md agent rules | `.cursorrules` agent rules section |
| CLAUDE.md code style | `.cursorrules` code style, `.github/copilot-instructions.md` |
| CLAUDE.md commands | `.cursorrules` commands section |
| `.claude/skills/*` | `.cursor/rules/*.mdc` (adapted for MDC frontmatter) |

You will have some duplication. That is fine. The alternative -- a single file that all tools read -- does not exist. Accept the duplication, and update all copies when the source of truth changes.

---

## The 10 Agent Rules

Include these in CLAUDE.md, `.cursorrules`, and any other context file your AI tools read. These are non-negotiable regardless of project or tool.

| # | Rule | Why |
|---|------|-----|
| 1 | Read context files before writing code | Prevents the agent from guessing patterns it could look up |
| 2 | Plan before coding -- outline approach, identify affected files | Catches scope issues before code is written |
| 3 | Run lint + type-check + tests before every commit | Ensures code compiles and passes before it enters git history |
| 4 | Commit specific files with conventional commit messages | Prevents accidental inclusion of secrets, build artifacts, or unrelated changes |
| 5 | Never force push, never `git add .`, never skip hooks | Protects shared branch history and prevents bypassing safety checks |
| 6 | Keep PRs under 10 files; split larger work into stacked PRs | Smaller PRs get faster, better reviews and reduce merge conflict risk |
| 7 | Every source change ships with corresponding tests | Untested AI-generated code has a high defect rate; tests are the verification layer |
| 8 | Track a change budget -- stop and reassess if exceeding scope | AI agents tend to scope-creep; budgets force deliberate decisions about scope |
| 9 | Ask clarifying questions before assuming on ambiguous requirements | Wrong assumptions waste entire implementation cycles |
| 10 | Verify your own output -- check test results, screenshots, build artifacts | Agents declare success without checking; this rule forces actual verification |

---

## Spec template

Every non-trivial feature starts with a spec. Create `specs/_TEMPLATE.md` in your repo:

```markdown
# Feature: [Name]

## Problem

What user or business problem does this solve? Why now?

## Solution

High-level approach. Key design decisions and trade-offs.

## Acceptance Criteria

- [ ] Criterion 1: specific, testable statement
- [ ] Criterion 2: specific, testable statement
- [ ] Criterion 3: specific, testable statement

## Out of Scope

- What this feature explicitly does NOT cover
- Items deferred to future iterations

## Dependencies

- External services or APIs required
- Other features or PRs this depends on

## PR Plan

Break into small, reviewable PRs (under 10 files each):

1. **PR 1**: `type(scope): description` -- what this covers
2. **PR 2**: `type(scope): description` -- what this covers
3. **PR 3**: `type(scope): description` -- what this covers
```

The PR Plan section is critical. It forces upfront decomposition. Without it, agents build the entire feature in a single 40-file PR.

---

## Session state files

Git log captures what code changed but not why decisions were made, what approaches failed, or what's blocked. Session state files capture tribal knowledge that survives across sessions.

### session-flow.md (index)

A top-level index that tracks priorities and links to per-repo session files.

```markdown
# Session Flow

## Active Repos
- **pebble** -> [session-pebble.md](session-pebble.md) -- Phase 2 complete, working on Phase 3
- **diggit** -> [session-diggit.md](session-diggit.md) -- Phase 1 in progress

## Next Session Priorities
1. Pebble: write visual regression tests for dashboard pages
2. Diggit: create CI review workflow

## Cross-Repo Notes
- All repos use conventional commits
- Visual baselines generated in CI (Linux), never locally
```

### session-{repo}.md (per-repo)

Tracks done/todo/blockers and an append-only session log for a single repo.

```markdown
# Session: Pebble

## Done
- [x] Phase 1: CLAUDE.md, .cursorrules, settings
- [x] Phase 2: CI workflows, pre-push hooks
- [ ] Phase 3: Test quality rules, visual regression

## Todo
- [ ] Write @core visual tests (need auth + database seed helpers)
- [ ] Add frontend unit tests (zero exist in apps/web)

## Blockers
- Pre-existing type errors in @pebble/backend swagger docs -- must fix before strict CI

## Session Log
- 2026-03-08: Created CLAUDE.md, .cursorrules, settings.json. Pushed to main + development.
- 2026-03-09: Added ci-review.yml with PR size guard + test coverage gate. PR #130.
- 2026-03-10: Visual infra complete. Tried seeding via API but auth emulator not ready.
  Switched to direct DB seed in global-setup.ts. PR #134 merged.
- 2026-03-11: Attempted @core tests but hit stale Drizzle schema cache. Deferred.
```

### Where to store them

Session files contain internal working notes, not project documentation. Two options:

1. **In a personal memory directory** (`.claude/projects/` or similar) -- not checked into the repo. Best for solo work or fractional CTO engagements.
2. **In the repo, `.gitignore`d** -- stored at `docs/sessions/` or `.claude/sessions/` with a `.gitignore` entry. Useful if you want the files colocated with code but not in version history.

Do not check session files into the repo. They contain work-in-progress notes, failed approaches, and opinions that do not belong in the project's git history.

### Why git log is not enough

Git log tells you that PR #134 added visual regression infrastructure. It does not tell you:

- That you tried seeding via the API first and it failed because the auth emulator wasn't configured
- That the Drizzle schema cache caused flaky test failures and you need to clear it between runs
- That the visual tests must run on Linux because font rendering differs on macOS
- That Phase 3 is blocked on fixing pre-existing type errors in the backend package

Session files capture the context that makes the next session productive instead of a repeat of past failures.

---

## Recommended Skill Set

A mature project should have at minimum these skills under `.claude/skills/`:

| Skill | Load when... | Notes |
|---|---|---|
| `architecture/` | Building any feature | Patterns, data flow, component structure |
| `code-style/` | Writing or reviewing code | TypeScript, naming, import order |
| `quality/` | Writing tests or reviewing | Assertions, DRY/SOLID, coverage |
| `security/` | **Every feature** | Auth, secrets, multi-tenancy checklist |
| `sre/` | Backend features, infra changes | Observability, stateless constraints, health |
| `compliance/` | Any user data feature | Audit logging, data privacy, regulatory |
| `deploy/` | Deploy or infra work | CI/CD, scripts, environment layout |
| `database/` | Schema or query work | Migrations, query patterns, conventions |
| `visual-testing/` | UI changes | Playwright, baselines, tiers |

**Security and compliance are loaded proactively** — explicitly mandate them in CLAUDE.md, not just make them available. The agent won't load them voluntarily unless told to.

**Sub-skills over monolithic files**: when a skill grows past ~100 lines, split it. The compliance skill, for example, becomes `compliance/data-privacy.md`, `compliance/pci.md`, etc. — each loaded only when relevant. This keeps context tight and prevents the agent from loading irrelevant rules.

**Multi-repo sessions**: Claude Code permissions are scoped to the directory it was launched from. To work across multiple repos in one session, launch from the common parent (e.g. `cd ~/dev && claude`). If launched from a single repo, agents cannot write to sibling repos — open separate sessions per repo instead.

---

## Push to dev branch

This is the most commonly missed step. If your team works off a `dev` (or `develop` or `development`) branch, CLAUDE.md must exist on that branch. Feature branches are created from the dev branch, not from main. If CLAUDE.md only exists on main, agents working on feature branches never see it.

```bash
# After creating your context files on main:
git checkout development
git merge main
git push origin development
```

Or if you created the files on a feature branch that targets dev, merge that PR first. The point is: verify that CLAUDE.md exists on the branch your agents will actually branch from.

---

## Verification

Context files are only useful if they change agent behavior. Test them.

**Test 1: New API endpoint.** Ask the agent to create a new endpoint. Check:
- Does it use your ORM (not a different one)?
- Does it follow your error handling pattern?
- Does it match your route file structure?
- Does it create a test file?

**Test 2: New component.** Ask the agent to create a UI component. Check:
- Does it use your component library?
- Does it follow naming conventions (named exports, colocated tests)?
- Does it use your state management approach?

**Test 3: Bug fix.** Describe a bug. Check:
- Does the agent write a failing test first?
- Does it commit with the correct format (`fix(scope): description`)?
- Does it stay under the file budget?

**Test 4: Permissions.** Run a command that should be denied (e.g., `git push --force`). Does `.claude/settings.json` block it?

If any test fails, your context files are missing information. Add the missing pattern, re-test. Iterate until the agent produces correct output for common task types without manual correction.

A well-configured repo should pass all four tests within the first session after setup. If it doesn't, the context files need more specificity -- less "follow best practices," more "use this exact pattern."
