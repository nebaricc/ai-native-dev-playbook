# Session State

## The session amnesia problem

AI coding assistants forget everything between sessions. Close the terminal, hit the context window limit, or come back the next morning -- the AI starts from zero. It does not know what you finished yesterday, what approach you tried and abandoned, what is blocked on a teammate's PR, or what you planned to do next.

Git log captures what changed in code. It does not capture:

- Why you chose approach A over approach B
- What you tried that did not work
- What is blocked and why
- What the priority order is across repos
- What the human decided in a Slack conversation that affects the next task

Without session state, you spend the first 10 minutes of every session re-explaining context. With three repos, that is 30 minutes of daily waste on re-orientation alone.

---

## Session state files

The solution is simple: markdown files that persist context between sessions. The AI reads them at the start of a session and updates them after completing milestones.

Two files handle most cases.

### session-flow.md -- the index

This file tracks the big picture across all repos. What is active, what is the priority, what are the cross-cutting concerns.

```markdown
# Session Flow

## Active Repos
1. **Signalboard** -- Level 4.5 complete, maintenance mode
2. **Pebble** -- Visual CI done, unit tests in progress
3. **Diggit** -- Initial setup, CLAUDE.md created, not yet tested

## Current Priority
Pebble unit tests -- target 80% coverage on src/services/

## Cross-Repo Notes
- All three repos use the same Playwright visual regression setup
- Signalboard patterns are the reference implementation for Pebble and Diggit
- Slack CI channels are configured for all three repos

## Session Log
- 2026-03-11: Pebble visual CI merged (PR #134). Started unit test audit.
- 2026-03-10: Diggit CLAUDE.md and settings created. Signalboard lint cleanup done.
- 2026-03-09: Signalboard Level 4.5 milestone -- 13 PRs merged, 280+ tests.
```

### session-{repo}.md -- per-repo detail

One file per repo. Tracks what is done, what is next, what is blocked, and a running log of decisions.

```markdown
# Session: Pebble

## Done
- [x] CLAUDE.md with stack, commands, conventions
- [x] .claude/settings.json with permissions
- [x] CI workflow (lint, type-check, unit tests, visual regression)
- [x] Playwright visual regression -- 17 tests, 15 baselines (PR #134)
- [x] .cursorrules standalone copy

## Todo
- [ ] Unit tests for src/services/auth.ts (0% coverage)
- [ ] Unit tests for src/services/billing.ts (12% coverage)
- [ ] Unit tests for src/services/projects.ts (34% coverage)
- [ ] Integration tests for API routes
- [ ] Sync main branch with dev (main is 23 commits behind)

## Blocked
- billing.ts tests blocked on understanding the Stripe mock setup
  - Asked in #pebble-dev on 2026-03-10, waiting for response
- main/dev sync blocked on PR #131 (needs review from Jordan)

## Failed Approaches
- Tried mocking Prisma client directly for service tests -- too brittle,
  every query change breaks mocks. Switched to test containers.
- Tried running visual tests in CI without Xvfb -- headless Chromium
  needs a virtual framebuffer on Linux runners. Added Xvfb to workflow.

## Decisions
- Using test containers over mocks for all database-touching tests
- Visual baselines stored in repo (not external storage) -- small project,
  acceptable repo size impact
- PR convention: conventional commits, scope is the module name

## Session Log
- 2026-03-11 14:30: Merged PR #134 (visual CI). Started test audit.
  auth.ts has zero tests. billing.ts has 2 tests but they mock everything.
  projects.ts has decent coverage but missing edge cases.
- 2026-03-11 16:00: Wrote 8 tests for auth.ts. Found a bug in
  refreshToken() -- it does not check token expiry before refresh.
  Filed issue PEB-142.
- 2026-03-12 09:00: Resuming. Priority is billing.ts tests.
  Need to sort out Stripe mock setup first.
```

---

## Why git log is not enough

Git log tells you what code changed. Session state tells you everything else.

| Information | Git log | Session state |
|---|---|---|
| What files changed | Yes | No |
| Why an approach was chosen | Rarely (commit messages are terse) | Yes |
| What was tried and abandoned | No | Yes |
| What is blocked and on whom | No | Yes |
| Priority order of remaining work | No | Yes |
| Decisions made in conversation | No | Yes |
| Current coverage gaps | No | Yes |
| Cross-repo dependencies | No | Yes |

A git log entry says "add unit tests for auth service." A session state entry says "auth.ts had zero tests, found a bug in refreshToken() that does not check expiry, filed PEB-142, switched from Prisma mocks to test containers after mocks proved brittle."

The session state entry gives the next session everything it needs to continue intelligently.

---

## Where to store them

Three options, each with tradeoffs.

**Option 1: `.claude/memory/` (recommended for solo or small teams)**

```
.claude/
  memory/
    session-flow.md
    session-pebble.md
    session-signalboard.md
    session-diggit.md
```

Add to .gitignore. These are personal working notes, not team documentation. Claude Code will find and read them automatically if you reference the path in CLAUDE.md or a memory index file.

**Option 2: Dedicated `memory/` directory at repo root**

```
memory/
  MEMORY.md           # Index file -- AI reads this first
  session-flow.md
  session-pebble.md
  client-repos.md     # Repo details, URLs, access info
```

Useful if you want session state to be visible to the whole team. Track in git if the notes have team value. Gitignore if they are personal.

**Option 3: Outside the repo entirely**

```
~/.claude/projects/{project-hash}/memory/
```

Claude Code supports user-level memory that persists across repos. Use this for cross-project preferences and patterns, not for repo-specific session state.

For most setups, Option 1 is the right default. It keeps session state close to the code without polluting the repo for other contributors.

---

## How to use them

### At session start

Reference the session state in CLAUDE.md or your memory index so the AI reads it automatically:

```markdown
# Memory Index

## Key Files
- [session-flow.md](session-flow.md) -- START HERE -- live session state
- [session-pebble.md](session-pebble.md) -- Pebble repo status
```

When the AI starts a session, it reads the index, sees the current state, and picks up where you left off. No re-explanation needed.

### After milestones

Tell the AI to update session state after completing significant work. This can be explicit ("update the session file") or built into your workflow commands:

```markdown
<!-- .claude/commands/ship.md -->
After merging the PR:
1. Update session-{repo}.md -- check off completed items, add session log entry
2. Update session-flow.md if priorities changed
3. Report what was done and what is next
```

### Between sessions (human edits)

Session state files are plain markdown. Edit them yourself between sessions to:

- Reprioritize work based on a stakeholder conversation
- Add blockers discovered outside the AI session
- Remove items that are no longer relevant
- Add context from team meetings or Slack threads

The AI will read your edits at the next session start. This is a two-way communication channel.

---

## For Cursor users

Session state works the same way with Cursor. The difference is that Cursor does not automatically read a memory index file.

**How to adapt:**

1. Store session state files in the same locations described above.
2. At the start of a Cursor session, open the session file and paste it into the chat, or reference it: "Read memory/session-flow.md and memory/session-pebble.md for current state."
3. At the end of a session, ask Cursor to update the files.

The extra manual step of referencing the files is minor. The value of not re-explaining context every session is significant.

If you use Cursor's Composer feature for multi-file edits, you can add the session state files to the Composer context. This gives Composer the same awareness of what is done and what is next.

---

## What makes good session state

**Include:**
- Completed items with dates
- Remaining items in priority order
- Blockers with enough context to unblock (who, what, when asked)
- Failed approaches with why they failed (saves the AI from retrying)
- Decisions with rationale (prevents the AI from re-debating settled questions)
- Links to relevant PRs, issues, Slack threads

**Exclude:**
- Code snippets (that is what the code is for)
- Full error logs (link to the CI run instead)
- Speculation about future work beyond the current milestone
- Anything that belongs in documentation rather than working notes

Keep session state files practical. They are working notes for you and the AI, not documentation for future readers.
