# Phase 4: Workflow Skills -- Implementation Guide

Workflow skills are reusable instructions that encode your team's development process. Instead of explaining your branching strategy, PR format, test requirements, and deploy process every session, you write it once. The AI tool follows the same workflow every time, triggered by what you say rather than a command you type.

This guide covers implementation in Claude Code and adaptation for Cursor.

---

## What Workflow Skills Are

A workflow skill is a markdown file that describes a multi-step development process. When the AI detects intent that matches a skill -- "build this feature" triggers the planning skill, "ship it" triggers the PR skill -- it follows the encoded steps without you spelling them out.

Skills are not prompts. A prompt says "write me a login page." A skill says "when the developer wants to build something, first draft a 5-bullet spec, then ask clarifying questions, then create a branch, then implement with parallel agents, then track the change budget." The skill is the process. The prompt is the work.

The three essential skills:

- **idea** -- Feature planning and implementation kickoff
- **ship** -- The full PR workflow: test, lint, commit, push, create PR
- **continue** -- Stacked PR creation when work exceeds the change budget

---

## Claude Code Implementation

Claude Code supports two types of skill files:

### Slash Commands: `.claude/commands/*.md`

These are user-facing skills invoked with `/project:command-name`. The file name becomes the command name. Each file contains markdown instructions that Claude follows when the command is invoked.

```
.claude/commands/
  idea.md        # /project:idea
  ship.md        # /project:ship
  continue.md    # /project:continue
```

Commands are also auto-triggered. If your `idea.md` skill describes planning behavior, Claude will recognize planning intent ("let's build a notification system") and follow the skill without the user typing `/project:idea`. You declare this in the skill file itself:

```markdown
# /idea -- Feature Planning

Auto-trigger when the user describes something to build, requests a feature,
or says "let's add..." / "I want to..." / "we need..."
```

### Sub-Agent Instructions: `.claude/agents/*.md`

These are instructions for spawned sub-agents. When a skill needs parallel execution -- three features built simultaneously, or tests written alongside implementation -- it spawns agents. Agent files tell those agents how to behave.

```
.claude/agents/
  implementer.md    # Instructions for agents that write code
  tester.md         # Instructions for agents that write tests
```

An agent file typically includes:

```markdown
# Implementer Agent

You are implementing a feature in a sub-agent. Follow these rules:

1. Read CLAUDE.md before writing any code.
2. Work only in your assigned worktree directory.
3. Run type-check and lint after every file change.
4. Write tests for every new function and component.
5. Commit with conventional commit messages.
6. Do not push. The lead agent handles push and PR creation.
7. When done, report: files changed, tests added, any issues found.
```

### How They Work Together

The lead agent (your main Claude Code session) reads the command file and orchestrates. When it needs parallel work, it spawns sub-agents with instructions from the agent files. The lead handles coordination, PR creation, and verification.

```
User: "Let's build a notification preferences page"

Claude reads .claude/commands/idea.md:
  1. Drafts inline spec (5 bullets)
  2. Asks clarifying questions
  3. Creates branch

Claude reads .claude/agents/implementer.md:
  4. Spawns agent A: build the UI component
  5. Spawns agent B: build the API endpoint
  6. Spawns agent C: write tests

Lead agent:
  7. Verifies all agent work
  8. Runs full test suite
  9. Waits for user to say "ship it"
```

---

## Cursor Equivalent

Cursor does not have slash commands or sub-agents. There is no direct equivalent to `.claude/commands/` or `.claude/agents/`. Here is what you can do and where the gaps are.

### What Works: `.cursor/rules/`

Cursor rules files (`.cursor/rules/*.mdc`) activate based on file glob patterns. You can encode workflow knowledge in these files, though they are designed for file-type conventions rather than multi-step workflows.

```
.cursor/rules/
  workflow-planning.mdc     # Planning conventions
  workflow-shipping.mdc     # PR and commit conventions
  workflow-testing.mdc      # Test writing standards
```

Each rule file uses frontmatter to declare when it activates:

```yaml
---
description: PR and shipping workflow
globs: ["**/*"]
alwaysApply: true
---
# Shipping Workflow

When asked to ship, push, or create a PR:
1. Map every changed source file to a test file
2. Write missing tests
3. Run type-check, lint, and tests locally
4. Commit specific files (never use git add .)
5. Push and create PR targeting dev
6. Include change summary in PR description
```

### What Works: Composer for Multi-File Operations

Cursor's Composer mode handles multi-file edits. For features that touch several files, Composer is the right tool. But it runs sequentially -- there is no parallel agent spawning. For a feature that touches the API, the UI, and the tests, Composer will work through them one at a time.

### What Does Not Work

- **Auto-triggered workflows.** Cursor rules activate based on file patterns, not intent. You cannot make Cursor automatically start a planning workflow when a user describes a feature. The user must know the process and follow it manually, or explicitly reference the rule.
- **Parallel agents.** Cursor cannot spawn sub-agents. Large features that would benefit from parallel implementation run sequentially.
- **Stacked PR automation.** The `/continue` pattern (branch from current branch, PR targeting previous branch) must be done manually in Cursor.
- **Change budget tracking.** Cursor has no built-in mechanism to track how many files or lines have changed during a session.

### Practical Advice for Cursor Teams

Put your workflow steps in `.cursorrules` directly. Make them prominent. Cursor reads this file on every interaction:

```markdown
## Workflow Rules

BEFORE implementing any feature:
- Draft a 5-bullet spec as a code comment at the top of the main file
- List the files you will change (max 10 per PR)

BEFORE committing:
- Run: npm run type-check && npm run lint && npm test
- Stage specific files: git add src/path/to/file.ts (never git add .)
- Use conventional commit format: feat(scope): description

WHEN a PR exceeds 10 files or 300 lines:
- Stop. Split into smaller PRs. Each PR must be independently mergeable.
```

This is less powerful than Claude Code's skill system, but it puts the workflow in front of the AI every time. The limitation is enforcement -- Cursor will sometimes ignore these rules, especially in long sessions. CI enforcement (Phase 2) becomes even more important.

---

## The Three Essential Skills

### Skill 1: `/idea` -- Feature Planning

This skill triggers when the user describes something to build. It prevents the AI from immediately writing code and instead establishes a plan.

**Implementation: `.claude/commands/idea.md`**

```markdown
# /idea -- Feature Planning

Auto-trigger when the user describes a feature to build.

## Steps

1. **Inline spec** -- Write a 5-bullet summary directly in the conversation.
   Do NOT create a spec file unless the feature is large (10+ files).
   Format:
   - Problem: one sentence
   - Solution: one sentence
   - Files to change: list them
   - Dependencies: anything this needs that doesn't exist yet
   - Risks: what could go wrong

2. **Clarifying questions** -- Ask up to 3 questions. Batch them in a single
   message. Do not ask questions one at a time. Skip this step if the request
   is clear enough to proceed.

3. **Branch creation** -- Create a feature branch from dev:
   ```
   git checkout dev && git pull origin dev
   git checkout -b feat/TICKET-short-description
   ```

4. **Implementation** -- Use parallel agents for independent workstreams.
   If the feature has a UI component, an API component, and tests, those
   are three independent agents. Never serialize work that can parallelize.

5. **Change budget** -- Track files and lines throughout. Report the count
   after implementation. If approaching 10 files or 300 lines, suggest
   splitting before shipping.
```

The key behaviors:

- **Spec before code.** The AI must articulate what it's building before it builds. This catches misunderstandings early.
- **Batched questions.** Serial clarification ("what about X?" / answer / "what about Y?" / answer) wastes time. Batch all unknowns into one question.
- **Branch from dev.** Not from main, not from a stale local branch. Always pull first.
- **Parallel agents from the start.** If the feature has independent parts, assign them to agents immediately.

### Skill 2: `/ship` -- PR Workflow

This skill triggers when the user indicates the work is ready: "ship it," "push it," "looks good," "create a PR."

**Implementation: `.claude/commands/ship.md`**

```markdown
# /ship -- PR Workflow

Auto-trigger when the user says to ship, push, create a PR, or indicates
the work is done.

## Steps

1. **Test mapping** -- For every changed source file, identify the
   corresponding test file. If a test file is missing, write it.
   ```
   src/services/notification.ts  ->  src/services/notification.test.ts
   src/components/Bell.tsx        ->  src/components/Bell.test.tsx
   ```
   Do not skip this step. Every source file gets a test file.

2. **Quality checks** -- Run all three locally:
   ```
   npm run type-check
   npm run lint
   npm test
   ```
   Fix any failures before proceeding. Do not push broken code.

3. **Visual tests** -- If any UI files changed (.tsx, .css, .scss),
   run visual regression tests:
   ```
   npx playwright test --config=playwright.visual.config.ts --grep '@smoke|@core'
   ```
   Update baselines only if the visual changes are intentional.

4. **Commit** -- Stage specific files. Never use `git add .` or `git add -A`.
   ```
   git add src/services/notification.ts src/services/notification.test.ts
   git commit -m "feat(notifications): add notification preferences"
   ```

5. **Push and create PR** --
   ```
   git push -u origin feat/TICKET-short-description
   gh pr create --base dev --title "feat(notifications): add preferences (NEB-42)" \
     --body "## Summary\n- Added notification preferences API\n- Added Bell component\n\n## Test plan\n- [ ] Unit tests pass\n- [ ] Visual regression screenshots reviewed"
   ```

6. **Report** -- Summarize what shipped:
   - Files changed (count)
   - Tests added (count)
   - PR URL
   - Any remaining work
```

The key behaviors:

- **Test mapping is mandatory.** The ship skill does not just commit and push. It audits test coverage first. This is the single most important step.
- **Specific file staging.** `git add .` picks up untracked files, editor configs, debug logs, and environment files. Always stage by name.
- **Local checks before push.** Do not rely on CI to catch type errors and lint failures. Run them locally. CI is the safety net, not the primary check.
- **PR description has a test plan.** Every PR includes a checklist of what to verify. This is for the human reviewer.

### Skill 3: `/continue` -- Stacked PRs

This skill triggers when the user continues building after a PR has been created. The previous PR is still open, and the new work depends on it.

**Implementation: `.claude/commands/continue.md`**

```markdown
# /continue -- Stacked PR

Auto-trigger when the user continues working after a PR was just created
and the new work depends on code from that PR.

## Steps

1. **Branch from current branch** -- Do NOT go back to dev.
   ```
   git checkout -b feat/TICKET-next-part
   ```
   This creates a branch that includes the previous PR's changes.

2. **PR targets previous branch** --
   ```
   gh pr create --base feat/TICKET-previous-part \
     --title "feat(notifications): add email delivery (NEB-43)" \
     --body "## Summary\n- Stacked on #42\n- Adds email delivery for notifications"
   ```
   The PR base is the previous branch, not dev. This prevents merge
   conflicts and ensures the PRs merge in order.

3. **Reset change budget** -- The new PR starts with a fresh budget.
   Track files and lines from this point forward.

4. **After previous PR merges** -- Rebase onto dev and update the PR base:
   ```
   git rebase dev
   git push --force-with-lease
   gh pr edit --base dev
   ```
```

When to stack vs. not stack:

- **Stack** when the new work imports functions, types, or components from the previous PR. The code literally depends on the previous changes.
- **Do not stack** when the new work touches different files. Create a parallel branch from dev instead. Parallel PRs merge independently and avoid the rebase chain.

---

## Always-Active Rules

These rules are not skills. They are behaviors that apply to every interaction, declared in CLAUDE.md or `.cursorrules`.

### Parallel Execution

When work has independent parts, run them in parallel. This is non-negotiable. Three independent test files means three agents, not three sequential tasks.

The test for independence: would changing file A require changing file B? If no, they are independent and should run in parallel.

```markdown
# In CLAUDE.md:

## Agent Behavior
- ALWAYS launch independent agents in parallel. If 3 tasks are
  independent, fire 3 agents in ONE message. Never serialize
  what can parallelize.
```

### Prefer Parallel PRs Over Stacked

Stacked PRs create a dependency chain. If PR 1 needs changes, PR 2 and PR 3 need rebasing. This is fragile.

Default to parallel branches from dev. Only stack when there is a real code dependency.

```
# Parallel (preferred):
git checkout dev -b feat/NEB-42-notifications
git checkout dev -b feat/NEB-43-user-settings
git checkout dev -b feat/NEB-44-dashboard-widget

# Stacked (only when necessary):
git checkout dev -b feat/NEB-42-notifications
# ... work, commit, push, create PR ...
git checkout -b feat/NEB-43-email-delivery  # branches from NEB-42
```

### Change Budget Tracking

Track the scope of changes throughout a session. The thresholds:

| Metric | Warning | Hard Limit |
|--------|---------|------------|
| Files changed | 7 | 10 |
| Lines changed | 200 | 300 |

At the warning threshold, mention it to the user. At the hard limit, stop and suggest splitting into multiple PRs. This prevents the 40-file, 2000-line PRs that are impossible to review.

### Visual Tests at the Finish Line Only

Do not update visual baselines during active iteration. If you are building a component and running visual tests after every change, you will regenerate baselines dozens of times. Instead:

1. Build the feature.
2. Get it working.
3. Run visual tests once at the end.
4. Update baselines if the changes are intentional.
5. Commit the baselines with the feature.

---

## Agent Teams for Large Work

When work spans three or more independent workstreams, use agent teams. Each agent gets its own git worktree, works independently, and reports back to the lead.

### When to Use Agent Teams

- Test retrofit across a codebase (10 test files to write)
- Multi-feature sprint (3 features with no file overlap)
- Large refactor (rename a service, update all callers, update all tests)
- Any batch of work that would take one agent 30+ minutes but can parallelize

### The Git Worktree Pattern

Git worktrees let multiple agents work on the same repo simultaneously without conflicts. Each worktree is a separate checkout with its own working directory and branch.

**Setup:**

```bash
# From the main repo directory
cd /path/to/project

# Create a worktree for each agent
git worktree add /tmp/project-notifications dev -b feat/NEB-42-notifications
git worktree add /tmp/project-settings dev -b feat/NEB-43-settings
git worktree add /tmp/project-dashboard dev -b feat/NEB-44-dashboard

# Verify
git worktree list
```

Each worktree gets:
- Its own directory (`/tmp/project-notifications`)
- Its own branch (`feat/NEB-42-notifications`)
- A shared git object store (commits in one worktree are visible to others)

**Spawning Agents:**

Each agent receives its worktree path and its specific task. The agent works entirely within that directory.

```markdown
# Agent prompt (passed when spawning):
Work in /tmp/project-notifications on branch feat/NEB-42-notifications.

Your task: Implement the notification preferences API.
- Create src/services/notification-preferences.ts
- Create src/app/api/notifications/preferences/route.ts
- Write tests for both files
- Run type-check and lint when done
- Do not push. Report your results when complete.
```

**Verification After Completion:**

Always verify each agent's work before pushing. Agents can commit to wrong branches, leave uncommitted changes, or break tests.

```bash
# For each worktree:
cd /tmp/project-notifications

# Verify correct branch
git branch --show-current
# Expected: feat/NEB-42-notifications

# Verify clean state
git status

# Run tests
npm test

# Push if everything checks out
git push -u origin feat/NEB-42-notifications
```

**Cleanup:**

Remove worktrees after PRs are created:

```bash
cd /path/to/project
git worktree remove /tmp/project-notifications
git worktree remove /tmp/project-settings
git worktree remove /tmp/project-dashboard

# If a worktree is dirty and you've already pushed:
git worktree remove --force /tmp/project-notifications
```

### Common Pitfalls

- **Creating worktrees from outside a git repo.** The `git worktree add` command must run from inside an existing git repository. If your current directory is not a repo, it fails.
- **Branch already exists.** If the branch name already exists (from a previous attempt), the worktree creation fails. Either delete the branch first or use a different name.
- **Agents committing to wrong branch.** Always verify `git branch --show-current` matches the expected branch after an agent completes. This has caused real bugs in production workflows.
- **Forgetting to install dependencies.** Each worktree is a fresh checkout. If the project uses node_modules, each worktree needs its own `npm install`.

---

## Stacked PRs vs. Parallel PRs -- Decision Framework

This decision comes up constantly. Use this framework:

### Choose Parallel PRs When:

- The features touch different files (no overlap)
- Each PR is independently testable and reviewable
- You want PRs to merge in any order
- Multiple team members will review different PRs

```
Feature A: src/services/auth.ts, src/components/Login.tsx
Feature B: src/services/billing.ts, src/components/Invoice.tsx
Feature C: src/services/notifications.ts, src/components/Bell.tsx

Verdict: Parallel. Zero file overlap.
```

### Choose Stacked PRs When:

- PR 2 imports a function or type defined in PR 1
- PR 2 modifies a file that PR 1 also modifies
- The features are sequential steps of a larger change
- You want to enforce merge order

```
PR 1: Create src/services/notification.ts with sendNotification()
PR 2: Add email channel to sendNotification() + create EmailProvider
PR 3: Add Slack channel to sendNotification() + create SlackProvider

Verdict: Stacked. Each PR modifies notification.ts.
```

### The Overlap Test

Run this mental test: "If PR A and PR B were both approved right now, could they both merge to dev without a conflict?" If yes, they should be parallel. If no, they should be stacked.

### Stacked PR Merge Workflow

When the base PR merges:

```bash
# PR 1 just merged to dev. PR 2 is stacked on PR 1.

# Update PR 2's branch:
git checkout feat/NEB-43-email-delivery
git rebase dev
git push --force-with-lease

# Update the PR base on GitHub:
gh pr edit 43 --base dev
```

After rebasing, PR 2 now targets dev directly and shows only its own changes in the diff.

---

## Adapting for Cursor-Only Teams

If your team uses Cursor without Claude Code, you lose the command and agent system. Here is how to get as close as possible.

### Encode Workflows in `.cursorrules`

Put your workflow steps directly in `.cursorrules`. Be explicit and prescriptive. Cursor reads this file on every interaction.

```markdown
## Development Workflow

### Planning (before writing code)
When I describe a feature to build:
1. Write a 5-bullet spec as your first response (Problem, Solution,
   Files, Dependencies, Risks)
2. Ask up to 3 clarifying questions in one message
3. Wait for my answers before creating any files
4. Create a branch: git checkout dev && git pull && git checkout -b feat/TICKET-desc

### Shipping (when I say "ship it" or "push it")
1. List every changed source file and its test file
2. Write any missing test files
3. Run: npm run type-check && npm run lint && npm test
4. Stage files individually: git add path/to/file (NEVER git add .)
5. Commit with conventional format: type(scope): description
6. Push and create PR: gh pr create --base dev

### Change Limits
- Warn me if changes exceed 7 files or 200 lines
- Stop and suggest splitting if changes exceed 10 files or 300 lines
```

### Use Composer for Multi-File Work

Cursor's Composer mode is the closest equivalent to Claude Code's agent system. Use it for features that touch multiple files. The limitation is that Composer works sequentially -- there is no parallel execution.

For large features, break the work into chunks manually:
1. Use Composer for the API layer (services + routes)
2. Use Composer for the UI layer (components + pages)
3. Use Composer for tests

This is manual orchestration, not automated parallelism. It works but requires more human coordination.

### Lean Harder on CI

Without automated workflow skills, CI enforcement (Phase 2) becomes your primary safety net. Make sure these are non-negotiable:

- **Test coverage gate** in CI -- blocks PRs without tests
- **Change budget check** -- warns or blocks on large PRs
- **Pre-push hook** -- runs tests before every push
- **PR template** -- forces the developer to fill in a test plan

The CI catches what the workflow skills would have prevented. It is a reactive approach (catch after the fact) rather than proactive (prevent before it happens), but it still works.

### What You Genuinely Cannot Do in Cursor

Be honest with your team about these limitations:

1. **No auto-triggered workflows.** Developers must remember the process or reference the rules manually.
2. **No parallel agents.** Large features run sequentially. Budget more time.
3. **No session state.** There is no `/continue` equivalent. If a session dies, the developer reconstructs context manually.
4. **No change budget tracking.** Cursor does not count files or lines during a session. Rely on CI to catch oversized PRs after the fact.

These are not dealbreakers. Teams shipped software for decades without any of this. But they are real differences that affect velocity, and your team should know about them when choosing tools.

---

## File Structure Summary

```
.claude/
  commands/
    idea.md           # Feature planning workflow
    ship.md           # PR creation workflow
    continue.md       # Stacked PR workflow
  agents/
    implementer.md    # Instructions for code-writing sub-agents
    tester.md         # Instructions for test-writing sub-agents
  settings.json       # Permission allowlist

.cursor/
  rules/
    workflow.mdc      # Workflow conventions (always active)
    components.mdc    # Component conventions (*.tsx)
    tests.mdc         # Test conventions (*.test.*)
    api-routes.mdc    # API conventions (route.ts)

CLAUDE.md             # Always-active rules (parallel execution,
                      #   change budget, branch strategy)
.cursorrules          # Same rules, formatted for Cursor
```

Skills live in version control. Every team member gets the same workflows. When you improve a skill, everyone benefits on their next `git pull`.
