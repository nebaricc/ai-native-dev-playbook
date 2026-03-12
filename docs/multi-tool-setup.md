# Multi-Tool Setup

## The multi-tool reality

Most teams do not standardize on a single AI coding tool. One developer uses Claude Code in the terminal. Another uses Cursor because their company has a Cursor license. A third uses VS Code with GitHub Copilot because that is what IT approved. A contractor uses Cursor because it is the only tool they know.

This is normal. Fighting it is a waste of time.

What matters is not which tool people use. What matters is that every tool produces code that follows the same conventions. The AI should generate the same error handling pattern, the same test structure, the same file organization regardless of whether it read the instructions from CLAUDE.md or .cursorrules.

This means maintaining multiple config files. Yes, that means some duplication. The alternative -- inconsistent output across tools -- is worse.

---

## Configuration mapping

Each tool reads different files, supports different features, and has different limitations.

| Capability | Claude Code | Cursor | GitHub Copilot |
|---|---|---|---|
| Primary config | `CLAUDE.md` | `.cursorrules` | `.github/copilot-instructions.md` |
| Permissions | `.claude/settings.json` | Cursor Settings UI | N/A |
| Slash commands | `.claude/commands/*.md` | N/A (uses built-in commands) | N/A |
| File-scoped rules | `.claude/skills/*.md` | `.cursor/rules/*.mdc` | N/A |
| Cross-file reference | Reads any file in repo | "Include third-party configs" setting | Cannot reference other files |
| Agent/sub-agent support | Yes (parallel agents) | Composer (limited) | N/A |
| Context window awareness | Automatic with CLAUDE.md | Manual or glob-triggered | Automatic but limited |

### Claude Code configuration

**CLAUDE.md** is the primary context file. Claude Code reads it automatically at the start of every session. Keep it under 200 lines. Include your tech stack, key commands, project structure, coding conventions, and common patterns.

**.claude/settings.json** controls which commands Claude Code can run without prompting. This is a permissions file, not a context file.

```json
{
  "permissions": {
    "allow": [
      "npm run dev",
      "npm test",
      "npm run lint",
      "npx prisma *"
    ],
    "deny": [
      "rm -rf *",
      "npx prisma migrate deploy"
    ]
  }
}
```

**.claude/commands/** contains custom slash commands. Each markdown file becomes a `/command-name` in Claude Code. Use these for repeatable workflows like shipping a PR, resuming interrupted work, or running a full test suite with analysis.

**.claude/skills/** contains on-demand knowledge files. Claude Code loads these when it encounters relevant files or contexts. More on this in the file-scoped rules section.

### Cursor configuration

**.cursorrules** is Cursor's primary config file. It lives in the repo root. Cursor reads it automatically when you open the project.

**.cursor/rules/*.mdc** files are file-scoped rules using Cursor's MDC (Markdown Config) format. They activate when Cursor is editing files that match a glob pattern.

**Cursor Settings UI** controls model selection, features, and the "Include third-party configs" toggle.

### GitHub Copilot configuration

**.github/copilot-instructions.md** is the only project-level config Copilot supports. It is limited compared to Claude Code and Cursor. No slash commands, no file-scoped rules, no cross-file references.

Keep copilot-instructions.md short and focused on the patterns Copilot is most likely to get wrong: error handling, import paths, test structure.

---

## Why .cursorrules must be standalone

Cursor has a setting called "Include third-party configs" that, when enabled, reads CLAUDE.md alongside .cursorrules. This sounds convenient. Do not rely on it.

Problems with depending on the Cursor cross-read:

1. **Version-dependent behavior.** The setting has changed behavior across Cursor versions. What works in 0.42 may not work in 0.44.
2. **Off by default.** New team members will not have this enabled. You cannot enforce it through repo config.
3. **Parse differences.** Cursor does not interpret CLAUDE.md the same way Claude Code does. Sections that Claude Code understands as structured context may be treated as flat text by Cursor.
4. **No feedback when broken.** If the cross-read stops working, nobody notices. The AI just silently ignores your conventions.

The correct approach: duplicate the key standards in .cursorrules. Yes, this means maintaining two files. The maintenance cost is low because your conventions do not change often. When they do change, update both files. Add it to your PR checklist.

A minimal .cursorrules should contain:

```
# Project Standards

## Stack
- Next.js 14 (App Router), TypeScript, Prisma, PostgreSQL
- Testing: Vitest (unit), Playwright (e2e + visual)

## Commands
- `npm run dev` -- start dev server
- `npm test` -- run unit tests
- `npm run test:e2e` -- run Playwright tests
- `npm run lint` -- ESLint + Prettier check

## Conventions
- Services return `{ data, error }` tuples, never throw
- API routes go in src/app/api/[resource]/route.ts
- Database queries go in src/services/, never in route handlers
- All API routes validate input with zod
- Tests use describe/it blocks, not test()
```

This is not DRY. That is fine. DRY is a principle for application code, not for tool configuration files read by different systems.

---

## File-scoped rules

Both Claude Code and Cursor support rules that activate based on which files are being edited. The mechanisms are different.

### Claude Code: .claude/skills/

Skills are on-demand knowledge files. Claude Code loads them when it encounters files or contexts that match. They are markdown files stored in `.claude/skills/`.

```markdown
<!-- .claude/skills/api-routes.md -->
# API Route Conventions

When creating or modifying API routes in src/app/api/:

- Validate all input with zod schemas defined in src/schemas/
- Return NextResponse.json() with appropriate HTTP status codes
- Log errors to the structured logger (src/lib/logger.ts), never console.log
- Wrap handler bodies in try/catch, return 500 on unhandled errors
- Include request ID from headers in all log entries
```

Skills are loaded when Claude Code determines they are relevant based on the file paths and task context. They are not glob-triggered in the same way Cursor rules are.

### Cursor: .cursor/rules/*.mdc

Cursor uses MDC (Markdown Config) files with frontmatter that specifies glob patterns. Rules activate when the user is editing a file that matches the glob.

```markdown
---
description: API route conventions
globs: src/app/api/**/*.ts
---
- Validate all input with zod schemas defined in src/schemas/
- Return NextResponse.json() with appropriate HTTP status codes
- Log errors to the structured logger (src/lib/logger.ts), never console.log
- Wrap handler bodies in try/catch, return 500 on unhandled errors
- Include request ID from headers in all log entries
```

### The same rule, both formats

Here is a test convention rule implemented for both tools.

**Claude Code** (`.claude/skills/testing.md`):
```markdown
# Test Conventions

When writing or modifying test files:

- Use describe/it blocks, not test()
- Never mock the database -- use the test container via setupTestDb()
- Every test file must have at least one assertion
- Name test files as [module].test.ts, colocated with source
- For Playwright tests, use data-testid attributes for selectors
- Visual regression tests go in tests/visual/ and use toMatchSnapshot()
```

**Cursor** (`.cursor/rules/testing.mdc`):
```markdown
---
description: Test file conventions
globs: "**/*.test.ts, **/*.spec.ts, tests/**/*.ts"
---
- Use describe/it blocks, not test()
- Never mock the database -- use the test container via setupTestDb()
- Every test file must have at least one assertion
- Name test files as [module].test.ts, colocated with source
- For Playwright tests, use data-testid attributes for selectors
- Visual regression tests go in tests/visual/ and use toMatchSnapshot()
```

The content is identical. The wrapper format differs. Maintain both.

---

## Directory structure alignment

Here is the full tree of AI tool configuration files in a well-configured repo:

```
CLAUDE.md                          # Claude Code primary context
.cursorrules                       # Cursor primary context (standalone copy)
.claude/
  settings.json                    # Claude Code permissions (allow/deny commands)
  settings.local.json              # Personal overrides (gitignored)
  commands/
    ship.md                        # /ship -- full PR workflow
    idea.md                        # /idea -- plan before coding
    continue.md                    # /continue -- resume interrupted work
  skills/
    api-routes.md                  # On-demand: API route conventions
    testing.md                     # On-demand: test conventions
    database.md                    # On-demand: Prisma/migration patterns
.cursor/
  rules/
    api-routes.mdc                 # Glob-triggered: API route conventions
    testing.mdc                    # Glob-triggered: test conventions
    database.mdc                   # Glob-triggered: Prisma patterns
.github/
  copilot-instructions.md          # GitHub Copilot context (subset of key rules)
```

Not every project needs all of these. Start with CLAUDE.md and .cursorrules. Add file-scoped rules when you notice the AI consistently getting specific areas wrong. Add commands when you find yourself repeating the same multi-step instructions.

---

## Sync strategy

CLAUDE.md is the source of truth. When conventions change, update CLAUDE.md first, then propagate.

**Propagation checklist:**

1. Update CLAUDE.md with the new convention or change
2. Update .cursorrules with the same change (the sections that overlap)
3. If the change affects a file-scoped rule, update both `.claude/skills/` and `.cursor/rules/`
4. If the change affects a critical pattern Copilot needs, update `.github/copilot-instructions.md`
5. If the change affects permissions, update `.claude/settings.json`

**What lives where:**

| Content | CLAUDE.md | .cursorrules | copilot-instructions.md |
|---|---|---|---|
| Tech stack | Yes | Yes | Yes |
| Build/test commands | Yes | Yes | Brief |
| Coding conventions | Yes | Yes | Key patterns only |
| Project structure | Yes | Yes | No |
| Agent/workflow instructions | Yes | No (Cursor handles differently) | No |
| Permission rules | No (settings.json) | No (Settings UI) | No |

**When to sync:** Add a step to your PR template or checklist. If a PR modifies CLAUDE.md, the reviewer should check that .cursorrules was updated to match.

---

## For Cursor-only teams

If your team uses Cursor exclusively and nobody uses Claude Code, you can simplify.

**What to adopt:**

- `.cursorrules` -- your primary config. Put everything here: stack, commands, conventions.
- `.cursor/rules/*.mdc` -- file-scoped rules for specialized areas.
- The Phase 2-3 practices from this playbook (test standards, CI gates, visual regression) apply regardless of tool.

**What to skip:**

- `CLAUDE.md` -- not needed if nobody uses Claude Code. However, consider creating it anyway. It takes 10 minutes and future-proofs you if someone on the team switches tools or you hire a contractor who uses Claude Code.
- `.claude/settings.json` -- only relevant to Claude Code.
- `.claude/commands/` -- only relevant to Claude Code. Cursor has its own command system.
- `.claude/skills/` -- not needed, use `.cursor/rules/` instead.

**What still applies from the playbook:**

- Phase 1: CLAUDE.md becomes .cursorrules. Same content, different file.
- Phase 2: CI gates, test standards, linting -- all tool-agnostic.
- Phase 3: Visual regression testing -- fully tool-agnostic, it is all Playwright.
- Phase 4: Workflow patterns (session state, PR checklists) work with any tool.

---

## .gitignore considerations

**Track these (commit to git):**

```
# AI tool configs -- these are team standards, not personal preferences
CLAUDE.md
.cursorrules
.claude/settings.json
.claude/commands/
.claude/skills/
.cursor/rules/
.github/copilot-instructions.md
```

**Ignore these (add to .gitignore):**

```
# Personal overrides
.claude/settings.local.json

# Session state (if stored in repo -- see session-state.md)
.claude/memory/

# Cursor local state
.cursor/mcp.json
.cursor/.cursor-server/
```

The reasoning: tool configuration that defines team standards must be shared. Personal settings, session history, and local server state should not pollute the repo.

If you use session state files (see [session-state.md](session-state.md)), decide whether those are personal or shared. For most teams, session state is personal and should be gitignored. For a solo developer or a team that wants handoff visibility, tracking them can be useful.

---

## Testing that tools follow your rules

After setting up config files, verify they work.

1. Open a session in each tool your team uses.
2. Ask the AI to create a new feature -- something with an API route, a service, and a test.
3. Review the output against your conventions. Check error handling, file placement, test structure, import paths.
4. If the AI deviates in one tool but not another, the config for that tool is missing the relevant rule. Add it.
5. Repeat until all tools produce consistent output.

Do this quarterly or whenever you change your conventions. It takes 30 minutes and prevents months of inconsistent AI-generated code.
