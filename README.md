# AI-Native Development Playbook

A battle-tested guide to making AI assistants effective contributors to your codebase.

---

## What This Is

A practical playbook for configuring any repository so AI coding assistants -- Claude Code, Cursor, Copilot, Windsurf, or whatever ships next quarter -- produce high-quality, reviewable, test-backed work.

This is **not** about prompt engineering. It is about:

- **Repo-level configuration** that gives AI agents the context they need
- **CI enforcement** that catches what agents get wrong
- **Workflow design** that channels AI speed into shippable increments
- **Testing standards** that prevent velocity theater

The approach has been proven across three production codebases: a Next.js/Firebase monorepo, a pnpm monorepo (Next.js + NestJS + Flutter), and a Django + Flutter app. It was created by a Fractional CTO who applied it across 3 client engineering teams in early 2026.

---

## The Problem

AI assistants are powerful but undisciplined by default:

- They dump 500-line PRs touching 30 files
- They skip tests unless explicitly told to write them
- They invent new patterns instead of following yours
- They don't know your deployment pipeline, branch strategy, or PR conventions
- They force-push, commit `.env` files, and `git add .` without thinking
- Different team members get wildly different quality from the same tools
- They produce "velocity theater" -- lots of code, few guarantees

The root cause is the same every time: **the AI has no context about how your team works.** It is coding in a vacuum.

---

## The Solution: Context as Code

Treat AI configuration like infrastructure -- version-controlled, enforced by CI, shared across the team.

The playbook has four phases, each building on the last:

| Phase | What | Why |
|-------|------|-----|
| 1. Context as Code | CLAUDE.md, .cursorrules, settings, skills | AI knows your standards |
| 2. CI Enforcement | PR guards, test gates, pre-push hooks | Standards are enforced, not suggested |
| 3. Testing Standards | Quality rules, visual regression, coverage gates | AI output is verified |
| 4. Workflow Skills | /idea, /ship, /continue automation | AI workflow matches your workflow |

---

## Phase 1: Context as Code (Foundation)

Every AI tool reads some form of context file. The goal is to make these files comprehensive, version-controlled, and consistent across tools.

### 1.1 Create CLAUDE.md

This is the primary context file. It lives at the root of your repo and is loaded automatically by Claude Code. Other tools can reference it too.

**Sections to include** (adapt to your stack):

| Section | What to Put |
|---------|-------------|
| Overview | Repo structure, tech stack, package manager, test runner |
| Commands | `install`, `dev`, `test`, `type-check`, `lint`, `build` |
| Git Conventions | Branch naming (`type/TICKET-123-desc`), commit format, PR titles, target branch, merge strategy |
| Code Style | Language-specific rules: strict mode, naming, imports, component patterns |
| Architecture | API patterns, service layer, state management, data access rules |
| Quality Standards | Test requirements, assertion rules, pre-push checks |
| Agent Behavior Rules | The 10 rules (see Section 1.3) |
| Definition of Done | Checklist: compiles, tests pass, lint clean, no secrets in diff |

See `templates/CLAUDE.md.template` for a full example.

### 1.2 Create Tool-Specific Configs

Different AI tools read different files. You need all of them.

**`.claude/settings.json`** -- permissions and guardrails for Claude Code:

```json
{
  "permissions": {
    "defaultMode": "plan",
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(npm run lint)",
      "Bash(npm run type-check)",
      "Bash(npm run test*)",
      "Bash(npm run build)",
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

Adapt commands per repo (`npm` vs `pnpm`, `vitest` vs `jest`, etc.).

**`.cursorrules`** -- must be comprehensive and standalone. Do NOT just write "read CLAUDE.md" -- Cursor's "Include third-party configs" setting is fragile. Duplicate all key standards inline: tech stack, git conventions, code style, testing rules, and the 10 agent rules.

**`.cursor/rules/*.mdc`** -- file-scoped rules that activate for specific globs:

```
# .cursor/rules/tests.mdc
---
globs: ["**/*.test.ts", "**/*.test.tsx", "**/*.spec.ts"]
---
Testing conventions:
- Use describe/it blocks with clear descriptions
- No .toBeDefined() — use .toBeInTheDocument(), .toEqual(), etc.
- Mock external services, not internal functions
- Test edge cases: empty data, error states, loading states
```

Create `.mdc` files for each domain: API routes, components, tests, database, etc.

**`.claude/skills/`** -- on-demand domain knowledge Claude Code loads when relevant (visual testing conventions, deployment pipeline, database schema docs).

### 1.3 The 10 Agent Rules

Include these in CLAUDE.md, .cursorrules, and any other context file. These are non-negotiable:

| # | Rule | Why |
|---|------|-----|
| 1 | **Read before writing** | Don't create a file that already exists. Don't rewrite a function without reading its callers. |
| 2 | **Plan before coding** (3+ files) | If a change touches 3 or more files, write a plan first. List the files, the changes, the order. |
| 3 | **Small PRs only** | Max 10 files, 300 lines changed. No exceptions. Split larger work into stacked PRs. |
| 4 | **Match existing patterns** | Find a similar file in the codebase and follow its structure exactly. Don't invent. |
| 5 | **Test every change** | Every source file change needs a corresponding test. No "I'll add tests later." |
| 6 | **Run checks locally** | Type-check, lint, and test before pushing. The CI should never be the first to catch errors. |
| 7 | **Never force push** | No `git push --force`. No `git reset --hard`. No exceptions. |
| 8 | **Ask when uncertain** | If unsure about architecture, naming, or scope -- stop and ask. Don't guess. |
| 9 | **Parallel execution** | Independent tasks run simultaneously. Never serialize what can parallelize. |
| 10 | **Change budget** | Track lines and files. Warn at 200 lines / 7 files. Split at 300 lines / 10 files. |

### 1.4 Spec Template

Create `specs/_TEMPLATE.md` for feature work:

```markdown
# Feature Name

## Problem
What user problem does this solve? Why now?

## Solution
High-level approach. 3-5 bullets max.

## Acceptance Criteria
- [ ] Specific, testable criteria
- [ ] Including edge cases
- [ ] And error states

## Out of Scope
- What this PR does NOT do (prevents scope creep)

## Dependencies
- Other PRs, services, or data this depends on

## PR Plan
If large: how to split into <=10-file PRs
```

### 1.5 Session State Files

AI conversations have limited context windows. When a session ends mid-task or you pick up work the next day, the AI starts from zero. Session state files solve this by giving the AI a persistent, human-readable record of what's done, what's left, and what went wrong.

**Structure:**

```
memory/
  session-flow.md          # Index — which repos, current priorities, what to do next
  session-signalboard.md   # Per-repo state
  session-pebble.md
```

**`session-flow.md`** (the index):

```markdown
# Session Flow

## Active Repos
- **Signalboard** → [session-signalboard.md](session-signalboard.md) — Level 4.5 complete
- **Pebble** → [session-pebble.md](session-pebble.md) — visual CI done, unit tests next

## Next Session Priorities
1. Pebble: frontend unit tests (zero exist in apps/web)
2. Pebble: generate visual baselines from CI
3. Diggit: apply Phase 1-2

## Cross-Repo Notes
- All repos use conventional commits, target dev/development branch
- Visual baselines must be generated in CI (Linux), never committed from local
```

**`session-{repo}.md`** (per-repo):

```markdown
# Session: Pebble

## Done
- [x] CLAUDE.md with full standards
- [x] CI review workflow (PR size + test coverage gates)
- [x] Visual regression — 17 smoke tests, 15 baselines
- [x] JWT_SECRET mismatch fix (backend + frontend must share same secret)

## Todo
- [ ] Frontend unit tests (apps/web has zero)
- [ ] @core visual tests (need auth + database seed helpers)
- [ ] Main ↔ development branch sync

## Blockers
- Pre-existing type errors in @pebble/backend (swagger docs) — must fix before enabling strict CI

## Session Log
- 2026-03-10: Created visual test infra, PR #134 merged
- 2026-03-11: Fixed JWT mismatch, added cursor config, PR #166
- 2026-03-12: Debugged admin auth locally — cookie is set but middleware can't verify JWT when secrets differ
```

**Why this works:**

- **New conversations start informed**: The AI reads session files and knows exactly where you left off
- **Human-readable**: You can review and edit state between sessions — it's just markdown
- **Prevents duplicate work**: "Already merged PR #134" stops the AI from redoing visual test infra
- **Captures tribal knowledge**: Blockers and session logs preserve context that git history doesn't (e.g., "JWT mismatch causes admin redirect" isn't in any commit message)

**Where to store them:**

- Claude Code: `.claude/memory/` or a dedicated `memory/` directory configured via project settings
- The session files are for AI continuity, not for the repo itself — consider `.gitignore`-ing them or keeping them in a separate location

### 1.6 Push to Your Dev Branch

This is the most commonly missed step. CLAUDE.md must exist on whatever branch agents will branch from. If your team works off `dev` and CLAUDE.md only exists on `main`, agents branching from `dev` won't see it.

Push context files to **both** `main` and your active development branch.

---

## Phase 2: CI Enforcement

Rules without enforcement are suggestions. Every standard from Phase 1 needs a CI gate.

### 2.1 PR Review Automation

Create `.github/workflows/ci-review.yml`:

```yaml
name: PR Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  pr-size-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check PR size
        run: |
          FILE_COUNT=$(git diff --name-only origin/${{ github.base_ref }}...HEAD | wc -l)
          echo "Changed files: $FILE_COUNT"

          if [ "$FILE_COUNT" -gt 30 ]; then
            echo "::error::PR touches $FILE_COUNT files (max: 30). Split into smaller PRs."
            exit 1
          elif [ "$FILE_COUNT" -gt 10 ]; then
            echo "::warning::PR touches $FILE_COUNT files. Consider splitting."
          fi

  test-coverage-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check test coverage for changed files
        run: |
          CHANGED_SOURCE=$(git diff --name-only origin/${{ github.base_ref }}...HEAD \
            | grep -E '\.(ts|tsx|js|jsx|py)$' \
            | grep -vE '(test|spec|__tests__|\.config\.|\.d\.ts)' \
            | grep -vE '(layout|page|middleware|loading|error|not-found)\.' || true)

          MISSING_TESTS=""
          for file in $CHANGED_SOURCE; do
            dir=$(dirname "$file")
            base=$(basename "$file" | sed 's/\.\(ts\|tsx\|js\|jsx\|py\)$//')
            if ! git diff --name-only origin/${{ github.base_ref }}...HEAD \
              | grep -qE "(${base}\.test|${base}\.spec|${base}_test)"; then
              MISSING_TESTS="$MISSING_TESTS\n- $file"
            fi
          done

          if [ -n "$MISSING_TESTS" ]; then
            echo "::error::Source files changed without corresponding test files:$MISSING_TESTS"
            exit 1
          fi

  ai-review:
    # Posts a checklist comment: missing tests, UI screenshot reminder,
    # config/secret exposure check, scope check.
    # IMPORTANT: Updates existing comment instead of creating new ones (prevents spam).
    # See templates/ci-review.yml.template for full implementation.
    runs-on: ubuntu-latest
    if: github.event.action == 'opened' || github.event.action == 'reopened'
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: AI Review Checklist
        uses: actions/github-script@v7
        with:
          script: |
            const { execSync } = require('child_process');
            const files = execSync(
              `git diff --name-only origin/${{ github.base_ref }}...HEAD`
            ).toString().trim().split('\n');
            const checks = [];
            const srcFiles = files.filter(f => /\.(ts|tsx|js|jsx|py)$/.test(f));
            const testFiles = files.filter(f => /(test|spec)/.test(f));
            if (srcFiles.length > 0 && testFiles.length === 0)
              checks.push('- [ ] **Missing tests**');
            else checks.push('- [x] **Tests included**');
            if (files.some(f => /\.(tsx|jsx|vue)$/.test(f)))
              checks.push('- [ ] **UI changes**: Add screenshots');
            if (files.some(f => /\.(env|json|ya?ml)$/.test(f)))
              checks.push('- [ ] **Config changed**: Check for secrets');
            checks.push(`- [ ] **${files.length} files**: Scope appropriate?`);
            const body = `## AI Review Checklist\n\n${checks.join('\n')}`;
            // Upsert: update existing comment or create new
            const { data: comments } = await github.rest.issues.listComments({
              ...context.repo, issue_number: context.issue.number });
            const existing = comments.find(c => c.body.includes('AI Review Checklist'));
            const method = existing ? 'updateComment' : 'createComment';
            const params = existing
              ? { ...context.repo, comment_id: existing.id, body }
              : { ...context.repo, issue_number: context.issue.number, body };
            await github.rest.issues[method](params);
```

### 2.2 Pre-Push Hook

Create `.githooks/pre-push`:

```bash
#!/bin/sh

# Skip for merge commits
MERGE_COMMIT=$(git log --oneline -1 | grep -c "Merge")
if [ "$MERGE_COMMIT" -gt 0 ]; then
  echo "Merge commit detected, skipping pre-push checks."
  exit 0
fi

echo "Running pre-push checks..."

# Type check
echo "Type checking..."
npm run type-check || { echo "Type check failed. Push aborted."; exit 1; }

# Unit tests
echo "Running tests..."
npm run test || { echo "Tests failed. Push aborted."; exit 1; }

echo "All checks passed."
```

Add setup instructions to CLAUDE.md:

```bash
git config core.hooksPath .githooks
```

For repos using Husky, configure it in `package.json` or `.husky/pre-push` instead.

### 2.3 GitHub Repository Settings

Configure these manually or via the GitHub API:

- **Auto-merge**: Settings > General > Allow auto-merge
- **Auto-delete head branches**: Settings > General > Automatically delete head branches
- **Branch protection on dev** (or your primary development branch):
  - Require status checks to pass (your CI jobs)
  - Require at least 1 approval
  - These are required for auto-merge to gate properly

**CODEOWNERS** (`.github/CODEOWNERS`):

```
# Default owner for everything
* @your-github-username
```

---

## Phase 3: Testing Standards

AI agents are prolific test writers -- but they write bad tests by default. `.toBeDefined()` passes even when the code is broken. Empty test bodies give false green. You need explicit quality rules.

### 3.1 Test Quality Rules

Enforce these in CLAUDE.md, .cursorrules, and code review:

| Bad | Good | Why |
|-----|------|-----|
| `expect(result).toBeDefined()` | `expect(result).toEqual({ id: 1, name: "test" })` | `.toBeDefined()` passes for any non-undefined value |
| `expect(component).toBeTruthy()` | `expect(screen.getByRole('button')).toBeInTheDocument()` | Test what the user sees |
| `it('should work', () => {})` | `it('shows error when email is invalid', () => { ... })` | Empty tests always pass |
| `expect(mockFn).toHaveBeenCalled()` | `expect(screen.getByText('Saved!')).toBeInTheDocument()` | Test behavior, not implementation |

Additional rules:

- Test edge cases: empty arrays, null values, error responses, permission denied
- Don't over-mock: let real child components render when testing parents
- One assertion concept per test (multiple `expect()` calls are fine if testing one behavior)
- Name tests by behavior: "shows error when...", "redirects to...", "disables button when..."

### 3.2 Visual Regression Testing

For any project with a UI, visual regression tests catch what unit tests miss: layout breaks, font changes, color regressions, responsive issues.

**Three-tier approach:**

| Tier | Tag | What | Data | Runs On |
|------|-----|------|------|---------|
| Smoke | `@smoke` | Unauthenticated pages (login, marketing, 404) | None | Every PR |
| Core | `@core` | Authenticated list/dashboard pages | Seeded via test infra | Every PR |
| Full | (all) | Detail pages, modals, multi-step flows | Rich seed data | Push to dev + nightly |

**Playwright config (`playwright.visual.config.ts`):**

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e/visual',
  fullyParallel: true,
  use: {
    viewport: { width: 1440, height: 900 },
    // Disable animations for deterministic screenshots
    launchOptions: {
      args: ['--force-prefers-reduced-motion'],
    },
  },
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01,
      animations: 'disabled',
    },
  },
});
```

**Critical rules:**

- **Linux-only baselines**: macOS and Linux render fonts differently. Always generate baselines in CI (Ubuntu), never commit local screenshots.
- **Self-contained infrastructure**: Visual tests need their own database (Postgres service container), auth (Firebase emulator or equivalent), and seed data. No dependency on external services.
- **Generate baselines via CI workflow**: Create a `visual-baselines.yml` workflow that runs on `workflow_dispatch`, generates screenshots, and commits them.

**CI integration:**

```yaml
# In your main CI workflow
visual-pr:
  if: github.event_name == 'pull_request'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: npx playwright install --with-deps chromium
    - run: npx playwright test --config=playwright.visual.config.ts --grep '@smoke|@core'

visual-full:
  if: github.event_name == 'push' && github.ref == 'refs/heads/dev'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: npx playwright install --with-deps chromium
    - run: npx playwright test --config=playwright.visual.config.ts
```

**Nightly regression**: Create a scheduled workflow (`cron: '0 6 * * *'`) that runs the full visual suite against dev. On failure, upload diff artifacts and auto-create a GitHub issue. See `templates/nightly-visual.yml.template` for the full workflow.

### 3.3 Test Coverage Enforcement

The `test-coverage-check` job from Phase 2 maps changed source files to test files and blocks the PR if any are missing. The pre-push hook catches it even earlier.

---

## Phase 4: Workflow Skills

Skills are reusable instructions that tell AI agents how to handle common workflows. In Claude Code, these live in `.claude/commands/` (user-triggered) and `.claude/agents/` (sub-agent instructions). The key insight: **skills should auto-trigger based on intent, not slash commands.**

### 4.1 /idea -- Feature Implementation

Auto-triggers when the user describes something to build ("add a notification system", "we need a settings page").

**Flow:**

1. Draft an inline spec (5 bullets max, not a full document)
2. Ask 1-3 clarifying questions (batched, not serial). Skip if the intent is clear.
3. Create a feature branch from dev: `git checkout -b feature/TICKET-123-short-desc dev`
4. Implement with parallel agents when work spans multiple files/domains
5. Track change budget throughout -- warn at 200 lines, split at 300

Place this in `.claude/commands/idea.md` -- the skill file should contain the flow above as agent instructions. The key behaviors: draft spec first, estimate size, propose splits for large work, track budget during implementation.

### 4.2 /ship -- Push and PR

Auto-triggers when the user says "push it", "ship it", "looks good", "LGTM".

**Flow:**

1. Map every changed source file to a test file. Write missing tests.
2. Run type-check, lint, tests locally.
3. Commit specific files (never `git add .` or `git add -A`).
4. Push and create PR with descriptive title and body.
5. Report summary: files changed, tests added, PR link.

### 4.3 /continue -- Stacked PRs

Auto-triggers when the user continues building after a PR is created.

**Flow:**

1. Create a new branch **from the current branch** (not from dev). This is the stacking mechanism.
2. The PR for this branch targets the previous branch, which prevents out-of-order merges.
3. Reset the change budget for the new PR.

### 4.4 Always-Active Rules

These aren't skills -- they're behaviors that should be active at all times:

- **Parallel execution**: If 3 tasks are independent, fire 3 agents in one message. Never serialize what can parallelize.
- **Prefer parallel PRs over stacked**: If work touches non-overlapping files, branch independently from dev. Only stack when PR B depends on code from PR A.
- **Change budget tracking**: Continuously track lines and files. The agent should self-interrupt when approaching limits.
- **Visual tests at the finish line only**: Don't update baselines during iteration. Run them once when the feature is complete.

### 4.5 Agent Teams for Large Work

When a task naturally breaks into 3+ independent workstreams, use agent teams instead of sequential work.

**When to use teams:**

- Test retrofit (audit the codebase, then N agents write tests in parallel)
- Multi-feature sprints (each feature gets its own agent + branch)
- Any batch of non-overlapping PRs

**Pattern:**

```
1. Create a task list for the work
2. Create git worktrees: one per workstream
   git worktree add /tmp/project-task-a dev -b feature/task-a
   git worktree add /tmp/project-task-b dev -b feature/task-b
3. Spawn one agent per worktree
4. Each agent works independently in its own directory
5. On completion: verify branch, run tests, push, create PR
6. Clean up worktrees: git worktree remove /tmp/project-task-a
```

**Why worktrees**: Multiple agents can't work in the same git checkout without stepping on each other. Worktrees give each agent an isolated working directory while sharing the same repository.

**Watch out for:**

- Create worktrees **before** spawning agents (the directory must exist)
- Verify the branch name after each agent completes (agents sometimes commit to the wrong branch)
- Always clean up worktrees when done

---

## Lessons Learned

These are from applying the playbook across three production codebases. Every lesson was learned the hard way.

1. **Always `git pull` before branching.** A previous session may have pushed work you don't know about. We duplicated an entire batch of PRs because the branch was 125 commits behind dev.

2. **Rules without enforcement are suggestions.** CLAUDE.md said "tests required" but nothing blocked merging without them. Always pair rules with CI gates (Phase 2).

3. **Agent prompts must explicitly say "write tests."** If you tell an agent "implement this feature," it will implement the feature and skip tests. Every time. The instruction must be explicit.

4. **Worktree branch management is fragile.** Agents committed to wrong branches, stashes got tangled. Verify the branch after every agent completes.

5. **Fix weak tests before writing more.** We had 655 tests but many used `.toBeDefined()`, which passes even when code is broken. Quality over quantity.

6. **Push context files to your active dev branch.** Feature branches inherit from the base. If CLAUDE.md is only on main and agents branch from dev, they don't see it.

7. **Don't demo velocity without quality.** Shipping 4 PRs with zero tests looks fast but is tech debt with a bow on it.

---

## Getting Started

### Quick Start (30 minutes)

**Step 1: Copy the foundation files to your repo.**

```bash
# Clone the playbook
git clone https://github.com/nebaricc/ai-native-dev-playbook.git /tmp/ai-native-playbook

# Copy templates to your project
cp /tmp/ai-native-playbook/templates/CLAUDE.md.template ./CLAUDE.md
cp /tmp/ai-native-playbook/templates/cursorrules.template ./.cursorrules
mkdir -p .claude .cursor/rules .githooks specs

cp /tmp/ai-native-playbook/templates/settings.json.template ./.claude/settings.json
cp /tmp/ai-native-playbook/templates/spec-template.md ./specs/_TEMPLATE.md
cp /tmp/ai-native-playbook/templates/pre-push.template ./.githooks/pre-push
chmod +x .githooks/pre-push
```

**Step 2: Customize for your stack.**

Edit CLAUDE.md with your:
- Project name and description
- Tech stack and package manager
- Build/test/lint commands
- Git branch strategy and conventions
- Architecture patterns specific to your codebase

Edit `.claude/settings.json` with your actual test and build commands.

**Step 3: Push to your dev branch and enable hooks.**

```bash
git config core.hooksPath .githooks
git add CLAUDE.md .cursorrules .claude/ .cursor/ .githooks/ specs/
git commit -m "chore: add AI-native development configuration"
git push origin dev
```

### Full Setup (2-4 hours)

Follow Phases 1-4 in order. Each phase builds on the previous:

1. **Phase 1** (30 min): Context files, agent rules, spec template
2. **Phase 2** (1 hour): CI workflows, pre-push hooks, GitHub settings
3. **Phase 3** (1 hour): Test quality rules, visual regression setup, coverage gates
4. **Phase 4** (30 min): Workflow skills, agent team patterns

---

## Templates

The `templates/` directory contains starter files you can copy and customize:

| File | Description |
|------|-------------|
| `CLAUDE.md.template` | Root context file with all sections pre-structured |
| `cursorrules.template` | Standalone Cursor rules (not a reference to CLAUDE.md) |
| `settings.json.template` | Claude Code permissions with sensible defaults |
| `ci-review.yml.template` | GitHub Actions workflow for PR review automation |
| `pre-push.template` | Git hook for pre-push type-check and tests |
| `spec-template.md` | Feature spec template (Problem/Solution/AC/Scope) |
| `playwright.visual.config.template.ts` | Playwright config for visual regression |
| `nightly-visual.yml.template` | Nightly visual regression workflow |
| `cursor-rules/` | Example .mdc files for common file types |
| `session-flow.md` | Session state index template |
| `session-repo.md` | Per-repo session state template |

## Examples

The `examples/` directory contains real-world configurations from production repos:

| Directory | Description |
|-----------|-------------|
| `examples/firebase-app/` | Next.js + Firebase monorepo (CLAUDE.md, CI, visual tests) |
| `examples/nextjs-monorepo/` | pnpm workspace with NestJS + Next.js (CLAUDE.md, Cursor rules) |
| `examples/django-api/` | Django REST API (CLAUDE.md, settings) |

---

## Contributing

This playbook is opinionated by design. If you've applied it to a stack not covered here (Rails, Go, Swift, etc.), open a PR with the stack, what worked, what you adapted, and example configs.

---

## License

MIT

---

*Created by [Nebari Consulting](https://nebari.io). Built from real experience across 3 client engineering teams, 13+ merged PRs per repo, and hundreds of AI-assisted commits.*
