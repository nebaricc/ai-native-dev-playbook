# AI-Native Development Playbook

**A battle-tested system for making AI coding assistants produce production-quality work.**

Built from real experience applying AI-assisted development across 3 client engineering teams, 40+ merged PRs, and hundreds of AI-generated commits. Works with Claude Code, Cursor, GitHub Copilot, and whatever ships next.

---

## Who This Is For

- **Engineering leads** adopting AI tools across a team and tired of inconsistent output quality
- **Solo developers** who want AI assistants that understand their codebase, not just their prompt
- **Fractional CTOs and consultants** standardizing AI workflows across multiple client repos
- **Teams using Cursor** who can't access Claude Code (or vice versa) and need tool-agnostic standards

If you've ever watched an AI assistant confidently generate code that doesn't match your patterns, skip your tests, force-push to main, or produce a 500-line PR that touches every file in the repo -- this playbook is your fix.

---

## The Industry Problem

AI coding assistants are the biggest productivity unlock in a decade. They're also the biggest quality risk.

**The promise:** A senior developer pairs with an AI that understands the codebase, follows conventions, writes tests, and ships small, reviewable PRs. The developer focuses on architecture and code review while the AI handles implementation.

**The reality for most teams:**

- **No context, no consistency.** The AI doesn't know your ORM, your auth pattern, your component library, or your branch strategy. It guesses -- and guesses differently every session. One developer gets clean output because they prompt well. Another gets spaghetti. The tool isn't the variable; the context is.

- **Velocity theater.** The AI ships fast. Four PRs before lunch. But zero tests, no type checking, invented patterns that don't match the codebase, and a 30-file PR that no one wants to review. It *looks* fast. It creates more work than it saves.

- **Rules without enforcement.** You write a CONTRIBUTING.md that says "all PRs need tests." The AI doesn't read CONTRIBUTING.md. Even if you add rules to an AI-specific config file, nothing stops the AI from ignoring them. Without CI gates, rules are suggestions.

- **Tool fragmentation.** Your team uses three different AI tools. Claude Code reads `CLAUDE.md`. Cursor reads `.cursorrules`. Copilot reads `.github/copilot-instructions.md`. Each tool gets different context, produces different output, and the team has no shared standard for AI-assisted work.

- **Session amnesia.** You spend 45 minutes getting the AI up to speed on your project. The context window fills up. Next session, you start over. The AI has no memory of what was done, what failed, or what's left.

The root cause is always the same: **the AI has no context about how your team works.** It's coding in a vacuum. And no one is checking its homework.

---

## The Solution

Treat AI configuration like infrastructure: version-controlled, enforced by CI, consistent across tools, and shared across the team.

This playbook has four phases. Each builds on the last:

| Phase | What You Do | What You Get |
|-------|-------------|--------------|
| **1. Context as Code** | Add `CLAUDE.md`, `.cursorrules`, settings, and file-scoped rules to your repo | AI knows your stack, patterns, conventions, and constraints before writing a single line |
| **2. CI Enforcement** | Add PR size guards, test coverage gates, pre-push hooks | Standards are enforced automatically -- the AI can't merge bad code even if it tries |
| **3. Testing Standards** | Define test quality rules, set up visual regression, block weak assertions | AI-generated tests actually catch bugs instead of giving false confidence |
| **4. Workflow Skills** | Create `/idea`, `/ship`, `/continue` commands that encode your workflow | The AI follows your team's process -- branching, testing, PR creation -- every time |

**You can stop at any phase and still get value.** Phase 1 alone -- adding context files to your repo -- typically produces the biggest quality jump. Most teams see AI output go from "needs heavy editing" to "ready for review" just by giving the AI proper context.

---

## Multi-Tool Support: Claude Code + Cursor + Copilot

This playbook is tool-agnostic by design. The standards are the same regardless of which AI tool your team uses. What changes is *where* you put the configuration.

| Concept | Claude Code | Cursor | GitHub Copilot |
|---------|-------------|--------|----------------|
| **Project context** | `CLAUDE.md` (auto-loaded) | `.cursorrules` (auto-loaded) | `.github/copilot-instructions.md` |
| **Permissions / guardrails** | `.claude/settings.json` | Built-in settings UI | N/A |
| **File-scoped rules** | `.claude/skills/*.md` (on-demand) | `.cursor/rules/*.mdc` (glob-triggered) | N/A |
| **Workflow commands** | `.claude/commands/*.md` → `/command` | N/A (manual workflow) | N/A |
| **Sub-agents** | Agent tool with worktrees | Composer (limited) | N/A |

### Why you need both `.cursorrules` AND `CLAUDE.md`

If your team uses multiple tools -- or if some team members can't access Claude Code due to licensing or policy -- you need both files. They serve the same purpose (project context) but are read by different tools.

**Critical rule: `.cursorrules` must be comprehensive and standalone.** Don't just write "read CLAUDE.md" -- Cursor's config loading is fragile and won't reliably follow that reference. Duplicate the key standards: tech stack, git conventions, code style, testing rules, and the 10 agent behavior rules. Yes, this means maintaining two files. The alternative -- team members getting inconsistent AI behavior -- is worse.

**File-scoped rules** give you context-aware guidance when editing specific file types:

```
# .cursor/rules/tests.mdc
---
globs: ["**/*.test.ts", "**/*.test.tsx", "**/*.spec.ts"]
---
- Use describe/it blocks with clear behavior descriptions
- No .toBeDefined() -- use .toEqual(), .toBeInTheDocument(), etc.
- Test edge cases: empty data, error states, permission denied
- One assertion concept per test
```

Claude Code's equivalent is `.claude/skills/` -- markdown files loaded on-demand when the agent encounters relevant files. Cursor's `.cursor/rules/*.mdc` files use MDC frontmatter with glob patterns to auto-activate.

**Keep them in sync.** Make `CLAUDE.md` the source of truth. Mirror key standards into `.cursorrules`. Create parallel file-scoped rules in both `.claude/skills/` and `.cursor/rules/`. See [docs/multi-tool-setup.md](docs/multi-tool-setup.md) for the full alignment strategy.

> **For Cursor-only teams:** You can adopt this entire playbook using only `.cursorrules` and `.cursor/rules/`. Skip the `.claude/` directory. The CI enforcement (Phase 2), testing standards (Phase 3), and the concepts from Phase 4 all apply regardless of which AI tool generates the code.

---

## The 10 Agent Rules

These rules go in every context file -- `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`. They're the behavioral contract between you and the AI:

| # | Rule | Why It Matters |
|---|------|----------------|
| 1 | **Read before writing** | Don't create a file that already exists. Don't rewrite a function without reading its callers. |
| 2 | **Plan before coding** (3+ files) | If a change touches 3+ files, write a plan first. List files, changes, order. |
| 3 | **Small PRs only** | Max 10 files, 300 lines. Split larger work into stacked PRs. |
| 4 | **Match existing patterns** | Find a similar file in the codebase and follow its structure. Don't invent. |
| 5 | **Test every change** | Every source file change gets a corresponding test. No "I'll add tests later." |
| 6 | **Run checks locally** | Type-check, lint, and test before pushing. CI shouldn't be the first to catch errors. |
| 7 | **Never force push** | No `--force`. No `reset --hard`. No exceptions. |
| 8 | **Ask when uncertain** | Unsure about architecture, naming, or scope? Stop and ask. Don't guess. |
| 9 | **Parallel execution** | Independent tasks run simultaneously. Never serialize what can parallelize. |
| 10 | **Change budget** | Track lines and files. Warn at 200 lines / 7 files. Split at 300 / 10. |

These aren't aspirational. They're extracted from hundreds of AI-assisted commits across production codebases. Every rule exists because we watched an AI agent violate it and create real problems.

---

## How to Apply This to Your Repo

### Quick Start (30 minutes -- Phase 1 only)

This gets you immediate improvement in AI output quality.

**Step 1: Create your context files.**

```bash
# Clone the playbook for templates
git clone https://github.com/nebaricc/ai-native-dev-playbook.git /tmp/playbook

# Copy and customize
cp /tmp/playbook/templates/CLAUDE.md ./CLAUDE.md
cp /tmp/playbook/templates/.cursorrules ./.cursorrules
mkdir -p .claude .cursor/rules specs

cp /tmp/playbook/templates/.claude/settings.json ./.claude/settings.json
cp /tmp/playbook/templates/specs/_TEMPLATE.md ./specs/_TEMPLATE.md
```

**Step 2: Customize for your stack.**

Edit `CLAUDE.md` and `.cursorrules` with:
- Your project name, tech stack, and package manager
- Your actual build/test/lint commands
- Your git branch strategy (what branch do PRs target?)
- Your naming conventions and architecture patterns
- The 10 agent rules (copy from the template)

Edit `.claude/settings.json` with your actual commands (replace `npm` with `pnpm`, `vitest` with `jest`, etc.).

**Step 3: Add file-scoped rules** for your most common file types.

Copy examples from `templates/.cursor/rules/` and customize the globs and conventions for your project. Common ones: `tests.mdc`, `components.mdc`, `api-routes.mdc`.

**Step 4: Push to your active development branch.**

```bash
git config core.hooksPath .githooks  # if using git hooks
git add CLAUDE.md .cursorrules .claude/ .cursor/ specs/
git commit -m "chore: add AI-native development configuration"
git push origin dev  # push to YOUR dev branch, not just main
```

> **Common mistake:** Pushing context files only to `main`. If your team branches from `dev`, agents on feature branches won't see `CLAUDE.md`. Push to both `main` and your active development branch.

**Step 5: Verify it works.**

Ask your AI tool to create a new feature (a new API endpoint, a new component, a new test). Does the output match your patterns? If not, whatever it got wrong is a missing rule in your context files. Add it and test again.

### Full Setup (1-2 days -- all 4 phases)

Each phase builds on the previous. Detailed implementation guides:

| Phase | Guide | Time | What You Get |
|-------|-------|------|--------------|
| 1. Context as Code | [docs/phase-1-context.md](docs/phase-1-context.md) | 1-2 hours | AI knows your project |
| 2. CI Enforcement | [docs/phase-2-ci.md](docs/phase-2-ci.md) | 2-4 hours | Standards are enforced |
| 3. Testing Standards | [docs/phase-3-testing.md](docs/phase-3-testing.md) | 4-8 hours | AI tests catch real bugs |
| 4. Workflow Skills | [docs/phase-4-workflows.md](docs/phase-4-workflows.md) | 2-4 hours | AI follows your process |

Additional deep dives:
- [Multi-tool setup](docs/multi-tool-setup.md) -- Claude Code + Cursor + Copilot alignment
- [Visual regression testing](docs/visual-testing.md) -- Playwright screenshot testing for UI projects
- [Session state files](docs/session-state.md) -- Cross-session continuity for AI assistants
- [Lessons learned](docs/lessons-learned.md) -- What went wrong and how we fixed it
- [FAQ](docs/faq.md) -- Common questions answered

---

## What's in This Repo

```
README.md                           # You are here
docs/
  phase-1-context.md                # Full Phase 1 guide with code examples
  phase-2-ci.md                     # CI workflows, hooks, GitHub settings
  phase-3-testing.md                # Test quality rules, visual regression
  phase-4-workflows.md              # Workflow skills, agent teams, worktrees
  multi-tool-setup.md               # Claude + Cursor + Copilot config alignment
  visual-testing.md                 # Playwright visual regression deep dive
  session-state.md                  # Cross-session memory for AI assistants
  lessons-learned.md                # Battle stories from 3 production repos
  faq.md                            # Common questions
templates/
  CLAUDE.md                         # Parameterized context file template
  .cursorrules                      # Standalone Cursor rules template
  .claude/settings.json             # Claude Code permissions template
  .claude/commands/                 # /idea, /ship, /continue skill templates
  .claude/skills/                   # Code style and quality skill templates
  .cursor/rules/                    # File-scoped rule templates (.mdc)
  .github/workflows/                # CI review and nightly visual regression
  specs/_TEMPLATE.md                # Feature spec template
  session-flow.md                   # Session state index template
  session-repo.md                   # Per-repo session state template
examples/
  firebase-app/                     # Next.js + Firebase monorepo example
  nextjs-monorepo/                  # pnpm workspace (Next.js + NestJS) example
  django-api/                       # Django REST API example
```

---

## Lessons Learned (The Short Version)

These are from applying the playbook across three production codebases. Every lesson was learned the hard way. [Full details →](docs/lessons-learned.md)

1. **Rules without enforcement are suggestions.** CLAUDE.md said "tests required." Nothing blocked merging without them. Always pair rules with CI gates.
2. **Agent prompts must explicitly say "write tests."** "Implement this feature" means the AI skips tests. Every time.
3. **Fix weak tests before writing more.** We had 655 tests. Many used `.toBeDefined()`, which passes when code is broken. Quality over quantity.
4. **Push context files to your dev branch.** If CLAUDE.md only exists on `main` and agents branch from `dev`, they don't see it.
5. **Always `git pull` before branching.** We duplicated an entire batch of PRs because the branch was 125 commits behind.
6. **Don't demo velocity without quality.** Shipping 4 PRs with zero tests looks fast but creates more work than it saves.
7. **Verify agent work -- don't trust green checkmarks.** Agents report success. Check the actual output.

---

## Contributing

This playbook is opinionated by design. If you've applied it to a stack not covered here (Rails, Go, Swift, Rust, etc.), we want your experience:

- What worked out of the box
- What you had to adapt
- Example config files for your stack

Open a PR or start a discussion.

---

## License

MIT

---

*Created by [Nebari Consulting](https://nebari.io). Built from real experience across 3 client engineering teams, 40+ merged PRs, and hundreds of AI-assisted commits in early 2026.*
