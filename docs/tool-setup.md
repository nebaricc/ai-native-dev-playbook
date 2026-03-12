# AI Tool Setup Guide

Each AI coding tool reads its own config files. Set up all the tools your team uses so everyone gets consistent behavior regardless of which tool they prefer.

---

## Claude Code

Claude Code reads project context from several locations:

**CLAUDE.md** -- The primary context file. Place it in the repo root. Keep it under 200 lines. Include: tech stack, key commands (build, test, lint), project structure, coding conventions, common patterns.

```markdown
# Project Name

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
```

**.claude/settings.json** -- Controls which commands Claude Code can run without prompting. Check this into git.

```json
{
  "permissions": {
    "allow": [
      "npm run dev",
      "npm test",
      "npm run lint",
      "npx prisma *",
      "docker compose *"
    ],
    "deny": [
      "rm -rf *",
      "npx prisma migrate deploy"
    ]
  }
}
```

**.claude/commands/** -- Custom slash commands (skills). Each file is a markdown file that becomes a `/command`.

```
.claude/
  commands/
    ship.md      -- /ship: full PR workflow
    idea.md      -- /idea: plan before coding
    continue.md  -- /continue: resume interrupted work
```

**Agents:** Claude Code can spawn sub-agents for parallel work. Define agent instructions in your skills. The agent inherits CLAUDE.md context automatically.

---

## Cursor

Cursor reads two types of config:

**.cursorrules** -- Global rules file in the repo root. For simplicity, have it reference CLAUDE.md:

```
# .cursorrules
Read and follow all instructions in CLAUDE.md in this repository.
```

This keeps you from maintaining two separate rule files.

**.cursor/rules/*.mdc** -- File-scoped rules. These activate when Cursor is editing files matching a glob pattern. Useful for specialized conventions:

```
---
description: API route conventions
globs: src/app/api/**/*.ts
---
- All API routes must validate input with zod
- Return NextResponse.json() with appropriate status codes
- Log errors to the structured logger, never console.log
```

```
---
description: Test conventions
globs: **/*.test.ts, **/*.spec.ts
---
- Use describe/it blocks, not test()
- Never mock the database -- use the test container
- Every test file must have at least one assertion
```

**Settings:** In Cursor, enable "Include third-party configs" so it reads .cursorrules. This is off by default in some versions.

---

## GitHub Copilot

Copilot has limited project-level configuration compared to Claude Code and Cursor, but you can provide instructions:

**.github/copilot-instructions.md** -- Project-level instructions that Copilot reads for context.

```markdown
This project uses Next.js 14 with App Router, TypeScript, and Prisma.
- Services return { data, error } tuples, never throw exceptions
- Tests use Vitest for unit tests and Playwright for e2e
- API routes validate input with zod schemas
```

Copilot doesn't support slash commands or file-scoped rules. Keep the instructions concise and focused on the patterns Copilot is most likely to get wrong.

---

## Keeping Configs in Sync

The risk with multiple config files is drift. CLAUDE.md says one thing, .cursorrules says another, copilot-instructions.md says a third.

**Strategy:** Make CLAUDE.md the source of truth. Have .cursorrules reference it. Copy the most critical rules into copilot-instructions.md (since Copilot can't reference other files).

**Checklist:**
- [ ] CLAUDE.md exists with stack, commands, and conventions
- [ ] .cursorrules references CLAUDE.md
- [ ] .cursor/rules/ has file-scoped rules for areas with specialized conventions
- [ ] .claude/settings.json has appropriate permissions
- [ ] .github/copilot-instructions.md has a summary of key conventions
- [ ] All config files are checked into git (except .claude/settings.local.json for secrets)

**Testing that agents follow rules:**
1. Ask the AI to create a new feature (e.g., a new API endpoint with tests)
2. Review the output against your conventions
3. If it deviates, your config is missing that rule -- add it
4. Repeat until the AI consistently produces code that matches your standards
