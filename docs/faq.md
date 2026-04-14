# Frequently Asked Questions

## "Can I use this repo as a central template for all my projects?"

Yes. There is no package manager install — you **copy** files from `templates/` into each repo and commit them. The easiest path:

1. From any project root, run the sync script (see [playbook-as-dependency.md](playbook-as-dependency.md)) to copy `CLAUDE.md`, `.cursorrules`, `.claude/`, `.cursor/rules/`, and `specs/_TEMPLATE.md`.
2. Customize `CLAUDE.md` and `.cursorrules` for that project's stack.
3. Later, run the same script with `--skip-root` to refresh skills and rules without overwriting your customized root files.

To add **only** Claude Code skills (`.claude/skills/`) and leave everything else alone, use `--skills-only` on the sync script. See [playbook-as-dependency.md](playbook-as-dependency.md).

If you maintain a **fork** of this playbook, set `PLAYBOOK_URL` to your fork when running the script.

## "Do I need both CLAUDE.md and .cursorrules?"

Yes. Claude Code reads CLAUDE.md. Cursor reads .cursorrules. They're different tools with different config formats. The simplest approach: make CLAUDE.md the source of truth and have .cursorrules contain one line: `Read and follow all instructions in CLAUDE.md in this repository.`

## "What if my team uses different AI tools?"

That's fine. All config files live in the repo and each tool reads its own. A team where one person uses Claude Code and another uses Cursor will both get project-aware behavior because both CLAUDE.md and .cursorrules are committed. See [multi-tool-setup.md](multi-tool-setup.md) for the full list.

## "How do I enforce these rules?"

CI gates, not the honor system. AI tools follow context files most of the time, but not always. Phase 2 adds automated checks: lint, type checking, test coverage, change budget limits, and AI-powered PR review. If the AI skips a test or changes too many files, the build fails. See [phase-2-ci.md](phase-2-ci.md).

## "What about GitHub Copilot?"

Copilot is less configurable than Claude Code or Cursor. It doesn't support slash commands or file-scoped rules. You can provide project context via `.github/copilot-instructions.md`, but it's a single flat file. Include your most important conventions there and accept that Copilot will need more manual correction than the other tools.

## "Is this only for TypeScript?"

No. The playbook works for any language. The config file formats are the same (CLAUDE.md is markdown, .cursorrules is text). Only the content changes. A Django project would reference Python conventions, pytest, and Django-specific patterns instead of Vitest and Next.js. A Rails project would reference RSpec and ActiveRecord patterns. The CI workflows and visual testing infrastructure adapt the same way -- swap `npm test` for `pytest` or `bundle exec rspec`.

## "How long does setup take?"

- **Phase 1 (Context as Code):** 1-2 hours. Mostly writing CLAUDE.md and understanding your own conventions well enough to document them.
- **Phase 2 (CI Enforcement):** 2-4 hours. Writing GitHub Actions workflows and configuring branch protection.
- **Phase 3 (Testing Standards):** 4-8 hours. Visual test infrastructure takes the most time (Docker setup, seed data, baseline generation).
- **Phase 4 (Workflow Skills):** 2-4 hours for initial skills, then ongoing refinement.
- **Total:** A focused developer can reach Phase 4 in 1-2 days.

## "What if the AI ignores the rules?"

That's what CI enforcement is for. Context files are instructions the AI usually follows. CI gates are hard stops the AI cannot bypass. If the AI writes code without tests, the coverage check fails. If it changes 15 files in one PR, the change budget check flags it. Design your pipeline so bad code can't merge, regardless of who (or what) wrote it.

## "Should I check .claude/ and .cursor/ into git?"

Yes, with one exception. `.claude/settings.json` (permissions), `.claude/commands/` (skills), and `.cursor/rules/` (file-scoped rules) should all be in version control. The exception is `.claude/settings.local.json`, which can contain machine-specific overrides or secrets -- add it to `.gitignore`.

## "How do visual test baselines work across different machines?"

They don't -- that's the point. Font rendering, anti-aliasing, and subpixel rendering differ between macOS, Windows, and Linux. If you generate baselines on a Mac and compare on Linux CI, every test fails.

The solution: generate baselines only in CI, on Linux. Developers write visual tests locally but don't commit local baselines. A CI workflow generates baselines on push to the dev branch and commits the resulting `.png` files. All comparisons happen Linux-to-Linux. See [visual-testing.md](visual-testing.md#baseline-management) for the workflow.

## "What's the change budget?"

A guideline for PR size. AI agents will happily refactor 50 files in one shot if you let them. Large PRs are hard to review, easy to get wrong, and risky to merge.

The recommended limits:
- **Warn** at 200 lines changed or 7 files touched
- **Split** at 300 lines or 10 files

Encode these in your CI pipeline as a PR check. The check doesn't block the merge (sometimes large PRs are necessary), but it posts a comment warning the author to consider splitting. Your CLAUDE.md and workflow skills should also include these limits so the AI self-constrains before CI has to catch it.

## "Can I adopt this incrementally?"

Yes, and you should. Start with Phase 1 (context files) and get immediate value. You don't need all four phases on day one. Most teams see the biggest ROI from Phase 1 alone -- AI output quality improves dramatically when the tool knows your patterns. Add phases as you have bandwidth. See the phase guides linked from [README.md](../README.md#full-setup-1-2-days----all-4-phases) for time estimates.

## "What if I'm joining an existing project that has none of this?"

Start by writing CLAUDE.md. Read through the codebase for 30 minutes and document what you see: the stack, the patterns, the conventions. Then ask the AI to create a new feature. Compare its output to the existing code. Whatever it gets wrong, add that rule to CLAUDE.md. Iterate until the AI consistently produces code that fits the project.

## "Do I need Docker for visual tests?"

Not strictly, but it helps. Visual tests need a running app with a database and seed data. Docker Compose gives you reproducible infrastructure with one command. If your app can run against SQLite or an in-memory store for tests, you can skip Docker, but most production apps use PostgreSQL or MySQL and you want your tests to match.

## "How do I handle monorepos?"

Put a root-level CLAUDE.md with shared conventions and a CLAUDE.md in each package/app directory with package-specific rules. Claude Code reads the nearest CLAUDE.md relative to the files being edited. For Cursor, use .cursor/rules/ with glob patterns scoped to each package.
