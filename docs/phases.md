# The Four Phases of AI-Native Development

This playbook has four phases. Each builds on the previous one. Skip ahead and you'll get AI agents that write confident, wrong code with no guardrails.

---

## Phase 1: Context as Code

**What:** Give AI tools the project context they need to write correct code. CLAUDE.md for Claude Code, .cursorrules for Cursor, .cursor/rules/ for file-scoped rules, .claude/settings.json for permissions.

**Why this matters:** Without context, AI tools guess. They guess wrong about your ORM, your auth pattern, your test framework, your import style. Every wrong guess costs you review time. Context files turn a generic AI into one that knows your project.

**Common mistakes:**
- Writing aspirational rules instead of actual patterns. Don't say "use clean architecture" -- say "services go in src/services/, they return `{data, error}` tuples, never throw."
- Making CLAUDE.md too long. Keep it under 200 lines. Link to detailed docs instead of inlining them.
- Forgetting .cursorrules. If your team uses Cursor, they need rules too. Have .cursorrules reference CLAUDE.md so you don't maintain two copies.
- Not including .claude/settings.json. This controls which commands the agent can run without asking. Without it, agents prompt for every shell command.
- Listing your stack without showing patterns. "We use Prisma" is not enough. Show the actual query pattern, the error handling pattern, the test pattern.

**What good context looks like:**

```markdown
## Error Handling
Services return { data, error } tuples. Never throw from a service.

// Good
const { data, error } = await userService.getById(id);
if (error) return NextResponse.json({ error: error.message }, { status: 400 });

// Bad -- don't do this
try { const user = await userService.getById(id); } catch (e) { ... }
```

**How to verify it's working:**
- Ask the AI to create a new API endpoint. Does it use your project's patterns (correct ORM, correct auth, correct error handling)?
- Ask it to write a test. Does it use your test framework and follow your conventions?
- If either answer is no, your context files are missing something. Add the missing pattern and test again.
- Run this verification for 3-4 different task types (new endpoint, new component, refactor, bug fix) to get good coverage.

**Time estimate:** 1-2 hours for a new repo. 30 minutes if you're adapting from a similar project.

---

## Phase 2: CI Enforcement

**What:** Automated gates that catch AI mistakes before they merge. PR review workflows, pre-push hooks, branch protection rules.

**Why this matters:** Context files are suggestions. AI tools follow them most of the time, but not always. CI enforcement is the safety net. If the AI skips a test, the build fails. If it changes too many files, the PR check warns. You don't rely on the honor system.

**Common mistakes:**
- Only running lint and type checks. You also need test coverage gates, change budget checks (warn at 200 lines / 7 files, block at 300 / 10), and PR size monitoring.
- Not setting up branch protection. If anyone can push to main without PR review, your CI gates don't matter.
- Making CI too slow. If the full suite takes 20 minutes, developers (and AI agents) will skip it. Keep the critical path under 5 minutes. Run expensive tests nightly.
- Forgetting to add AI-aware PR review. A workflow that posts review comments using AI catches things lint can't -- like "this function duplicates existing logic in utils/auth.ts."
- Not gating on test coverage. Without a coverage threshold, AI agents will happily ship untested code that passes lint.

**Minimum CI checks for AI-assisted repos:**
1. Lint + type check (fast, catches syntax issues)
2. Unit tests with coverage threshold (catches logic bugs)
3. Change budget check (catches scope creep)
4. PR template validation (catches missing descriptions)
5. Visual regression tests on UI changes (catches layout bugs)

**How to verify it's working:**
- Deliberately submit a PR with a missing test. Does CI fail?
- Submit a PR that touches 15 files. Does the change budget check flag it?
- Push directly to main. Does branch protection block it?
- Submit a PR with no description. Does the template check catch it?

**Time estimate:** 2-4 hours. Most of this is writing GitHub Actions workflows and configuring branch protection.

---

## Phase 3: Testing Standards

**What:** Rules for test quality, visual regression testing, and CI enforcement of test standards. Not just "write tests" but "write tests that actually catch regressions."

**Why this matters:** AI-generated tests have a specific failure mode: they test that the code does what it currently does, not what it should do. They mock too aggressively. They assert on implementation details. Without standards, you get 90% coverage that catches 10% of bugs.

**Common mistakes:**
- Accepting any test the AI writes. Review AI-generated tests more carefully than AI-generated code. A bad test is worse than no test -- it gives false confidence.
- Not requiring visual regression tests for UI changes. Unit tests don't catch CSS regressions. If you have a frontend, you need screenshot comparisons.
- Running visual tests on developer machines. Font rendering differs across OSes. Run visual tests in CI only, on Linux, with fixed viewports.
- Skipping database integration tests. Mocking the database means you're not testing your queries. Use containers (testcontainers or docker-compose) for real database tests.

**Signs of weak AI-generated tests:**
- Tests that only assert `toBeDefined()` or `not.toBeNull()` -- these prove existence, not correctness.
- Tests that mock the thing they're supposed to test. If you mock the database in a database service test, you're testing your mocks.
- Tests with no negative cases. Only testing the happy path means bugs in error handling go undetected.
- Tests that duplicate the implementation logic. If the test contains the same calculation as the code, both will be wrong in the same way.

**How to verify it's working:**
- Break a CSS layout intentionally. Does a visual test catch it?
- Introduce a logic bug that existing tests don't catch. Write a test that does. If your standards are working, the coverage gap should be small.
- Check that CI blocks merges when tests fail.
- Review AI-generated tests for the weak patterns listed above. If you find them frequently, add explicit rules to CLAUDE.md about test quality.

**Time estimate:** 4-8 hours for initial setup. Visual regression infrastructure takes the most time. Ongoing: 15 minutes per PR to review test quality.

---

## Phase 4: Workflow Skills

**What:** Custom slash commands and agent teams that encode your development workflow. /idea for planning, /ship for the full PR flow, /continue for picking up where you left off.

**Why this matters:** Without workflow skills, every AI session starts from scratch. The developer explains the branching strategy, the PR format, the test requirements, the deploy process. Skills encode this once. `/ship` means "create a branch, write code, write tests, run CI locally, push, create a PR with our template." Every time.

**Common mistakes:**
- Making skills too complex. A skill should do one workflow, not be a Swiss Army knife. `/ship` ships. `/test` tests. Don't combine them.
- Not including verification steps. A `/ship` skill that doesn't run tests before pushing is just `/yolo`.
- Hardcoding values that differ across repos. Use environment variables or read from config files so skills are portable.
- Forgetting `/continue`. Sessions get interrupted. The continue skill reads the last session state and picks up where it left off. Without it, context is lost.

**Essential skills to build first:**
1. `/idea` -- Takes a feature description, creates a plan with file list, estimates scope, identifies risks. Does not write code.
2. `/ship` -- Full PR workflow: branch, implement, test, lint, commit, push, create PR. Includes change budget check before pushing.
3. `/continue` -- Reads session state, identifies incomplete work, picks up where the last session stopped.
4. `/test` -- Analyzes untested code, writes appropriate tests, verifies coverage improvement.

**How to verify it's working:**
- Run `/ship` on a small feature. Does it produce a correct, tested, properly-formatted PR without manual intervention?
- Kill a session mid-task, start a new one, run `/continue`. Does it pick up correctly?
- Have a teammate who didn't write the skills try them. Do they work without explanation?
- Run `/idea` on a medium feature. Does the plan make sense? Does it identify the right files?

**Time estimate:** 2-4 hours to write initial skills. Refinement is ongoing -- you'll tweak skills as you discover edge cases.

---

## Total Time

| Phase | Time | Prerequisites |
|-------|------|---------------|
| 1. Context as Code | 1-2 hours | None |
| 2. CI Enforcement | 2-4 hours | Phase 1 |
| 3. Testing Standards | 4-8 hours | Phase 2 |
| 4. Workflow Skills | 2-4 hours | Phases 1-3 |

A solo developer can reach Phase 4 in 1-2 focused days. A team will take longer due to alignment discussions, but the setup work is the same.

Start with Phase 1. Get value immediately. Layer on phases as you're ready.
