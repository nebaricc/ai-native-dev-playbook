# Quick Rules: Copy-Paste Agent Rules for Any Project

**Drop these into your `CLAUDE.md`, `.cursorrules`, or `.github/copilot-instructions.md` and immediately get better AI output.**

These rules enforce **SOLID principles**, **DRY patterns**, and **Clean Code conventions** in AI-generated code. They cover type safety, function size limits, PR size limits, testing requirements, security basics, and the 10 agent behavior rules. No placeholders, no theory -- just the rules that matter most across every project we've worked on. Customize the specifics (package manager, branch names, ticket prefix) but keep the structure.

---

## Code Quality Rules

### Type Safety
- **No `any`.** Use `unknown` with type guards, or explicit generics. `any` disables the compiler and hides bugs.
- **Strict mode on.** Enable `strict: true` in `tsconfig.json` (or equivalent strict settings in your language).
- **Explicit return types** on all exported functions. The compiler can infer, but humans reviewing PRs cannot.
- **No type assertions** (`as Type`) unless you've verified the shape. Prefer type guards or schema validation (Zod, etc.).
- **Prefer `interface`** for object shapes, `type` for unions/intersections.

### Function Size and Structure
- **Functions under 40 lines.** If a function is longer, extract helpers. Long functions are hard to test and hard to review.
- **One responsibility per function.** A function that fetches data AND transforms it AND writes it should be three functions.
- **Destructure parameters.** `function createUser({ name, email }: CreateUserInput)` is clearer than positional args.
- **Prefer `const` + arrow** for components and callbacks. Use `function` declarations for top-level utilities.

### File Organization
- **One component/module per file.** Co-locate its styles, tests, and types.
- **Named exports only.** No default exports -- they make refactoring harder and imports inconsistent.
- **Import order:** Node built-ins > external packages > internal aliases > relative imports, separated by blank lines.
- **PascalCase** for components (`UserCard.tsx`), **camelCase** for utilities (`formatDate.ts`).

### Error Handling
- **Never swallow errors.** No empty `catch (e) {}` blocks. Log, rethrow, or return an error type.
- **No floating promises.** Every `async` call must be `await`ed or explicitly handled.
- **Use typed errors** or `Result<T, E>` patterns. Bare `throw new Error("something")` loses context.

---

## Git and PR Rules

### Commit Messages
```
type(scope): lowercase description
```
**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `perf`

### Branch Strategy
- **Always branch from your dev branch** (not `main`, not a stale local branch).
- **Always `git pull` before branching.** Stale branches waste entire sessions.
- **Branch name:** `type/TICKET-123-short-description`

### PR Size Limits (Non-Negotiable)
| Metric | Warning | Hard Limit |
|--------|---------|------------|
| Files changed | 7 | 10 |
| Lines changed | 200 | 300 |

At the hard limit, **stop and split into multiple PRs.** A 40-file PR is not a PR -- it's a deployment risk.

### PR Hygiene
- **One concern per PR.** Don't mix refactors with features with fixes.
- **Each commit is atomic** -- one logical change that compiles and passes tests.
- **Never `git add .`** -- stage specific files by name. Prevents committing `.env`, debug logs, editor config.
- **Never force push.** No `--force`. No `reset --hard`. No exceptions.
- **PR description** must include: what changed, why, test plan, ticket reference.

---

## Testing Rules

### Coverage
- **Every source file change ships with a test.** No "I'll add tests later."
- **Test behavior, not implementation.** If you refactor internals and tests break, the tests were testing the wrong thing.

### Assertion Quality
- **No weak assertions.** Ban `.toBeDefined()`, `.toBeTruthy()`, `.not.toBeNull()` -- they pass for almost any value.
- **Assert the actual shape:** `.toEqual({...})`, `.toBe(true)`, `.toHaveLength(3)`.
- **Test names describe behavior:** `"should return 404 when user not found"`, not `"test getUser"`.

### Test Structure
```
describe("ModuleName", () => {
  describe("methodName", () => {
    it("should [expected behavior] when [condition]", () => {
      // Arrange - Act - Assert
    });
  });
});
```

### What to Test
- Happy path + primary error cases
- Boundary conditions (empty arrays, null, zero, max values)
- User-visible behavior and state transitions

### What NOT to Test
- Third-party library internals
- Trivial getters/setters with no logic
- Framework boilerplate

### Trust but Verify
After any AI writes tests, introduce a deliberate bug in the source and confirm the test catches it. If it doesn't, the assertions are too weak.

---

## Security Rules

- **Never commit secrets**, `.env` files, API keys, or credentials.
- **Parameterized queries only** -- never string interpolation into SQL or database queries.
- **Validate all user input** via schema (Zod, Joi, class-validator, etc.).
- **Tenant/org scoping on every query** -- derive tenant ID from auth context, never from request params.
- **No PII in logs.** No emails, names, tokens, or user-identifiable data in console output.

---

## Architecture Rules

- **Stateless services.** Never store state in memory (caches, counters, sessions). Use the database or an external store.
- **Bounded queries.** Every list query must have a `LIMIT`. No unbounded result sets. Paginate everything.
- **No confused deputy.** Secrets loaded at startup via environment injection, not fetched per-request.
- **Match existing patterns.** Before creating something new, find a similar file in the codebase and follow its structure. Don't invent new patterns without discussion.

---

## Deterministic workflow (phases)

Inspired by harness-style orchestration (e.g. [Archon](https://github.com/coleam00/archon)): **encode the sequence**, not just the coding rules. The model fills in the work at each step; the structure stays the same every time.

| Phase | What to do |
|-------|------------|
| **Classify** | Bug, feature, refactor, chore, docs, or investigation. If unclear, ask one short question before coding. |
| **Context** | Read this repo's `CLAUDE.md`, `.cursorrules`, and similar existing code before editing. |
| **Plan** | For 3+ files or cross-package work: list steps, files, and risks; keep the plan until the PR is ready. |
| **Implement** | Small steps; use scripts and test runners for verify/build/test. |
| **Validate** | Run type-check, lint, and tests locally before push. CI is not the first check. |
| **Review** | Re-read the diff; map every changed source file to a test or a justified exception. |
| **Ship** | Branch, commit, push, PR; follow the project's PR template and definition of done. |

**Isolation:** One branch per task. For parallel agent work, use **separate git worktrees** so runs do not conflict.

**Artifacts:** For non-trivial work, keep a short **plan** (session summary or `plan.md` if the team uses it) so implementation does not drift from scope.

**Loops:** **Implement until green** (fix and re-run until tests pass). **Review until done** (address feedback on the same branch before merge).

---

## Agent Behavior Rules

These 10 rules go in every context file. They are the behavioral contract between you and the AI:

1. **Read before writing.** Always read existing code first. Don't create a file that already exists.
2. **Plan before coding.** If a change touches 3+ files, write a plan first. List files, changes, order.
3. **Small PRs only.** Max 10 files, 300 lines. Split larger work into stacked or parallel PRs.
4. **Match existing patterns.** Find a similar file and follow its structure. Don't introduce new conventions.
5. **Test every change.** Every source file change gets a corresponding test. No exceptions.
6. **Run checks locally.** Type-check, lint, and test before pushing. CI is the safety net, not the first check.
7. **Never force push.** No `--force`. No `reset --hard`. No exceptions.
8. **Ask when uncertain.** Unsure about architecture, naming, or scope? Stop and ask. Don't guess.
9. **Parallel execution.** Independent tasks run simultaneously. Never serialize what can parallelize.
10. **Track the change budget.** Count files and lines. Warn at 200/7. Split at 300/10.

---

## Pre-Push Checklist

Before every push, verify:

- [ ] Type checking passes
- [ ] Linting passes (zero warnings in changed files)
- [ ] All existing tests pass
- [ ] New/changed source files have corresponding tests
- [ ] No `any` types introduced
- [ ] PR is under 10 files / 300 lines
- [ ] No secrets in the diff
- [ ] Commit messages follow conventional format
- [ ] Screenshots included for UI changes

---

## Rules vs. Enforcement: What Actually Works

Not all rules are equal. Some, agents follow reliably from context files alone. Others require CI gates.

| Rule | CLAUDE.md Alone? | Needs CI Gate? | Why |
|------|:---:|:---:|-----|
| Commit message format | ~80% | Yes | Agents drift in long sessions |
| Named exports only | ~95% | Optional | Easy to follow, rarely violated |
| No `any` types | ~90% | Yes | Agents introduce `any` under pressure |
| Test every change | ~60% | **Yes** | Biggest gap -- agents skip tests when task is complex |
| PR size limits | ~70% | Yes | Agents don't track their own scope |
| No force push | ~95% | Yes (branch protection) | Low frequency, catastrophic when violated |
| Import ordering | ~85% | Yes (ESLint) | Easy to automate with lint rules |
| Parameterized queries | ~90% | Optional | Agents are good at this, but code review catches edge cases |
| Run local checks | ~75% | Yes (pre-push hook) | Agents sometimes push before running tests |

**The principle:** Write the rule in CLAUDE.md for context. Enforce the rule in CI for compliance. Both are necessary. Neither is sufficient alone.

---

## Minimal Setup (15 minutes)

1. Copy the rules above into a `CLAUDE.md` at your repo root
2. Customize: your package manager, dev branch name, ticket prefix
3. Copy the same rules into `.cursorrules` if anyone uses Cursor
4. `git add CLAUDE.md .cursorrules && git commit -m "chore: add AI agent rules"`
5. Push to **both** `main` and your dev branch

That's it. Start a new AI session and ask it to build something. Compare the output to what you got before the rules. Whatever it still gets wrong, add that rule.

---

## Next Steps

- **[Phase 2: CI Enforcement](phase-2-ci.md)** -- Make the rules unbreakable with automated gates
- **[Phase 3: Testing Standards](phase-3-testing.md)** -- Stop AI-generated tests from being useless
- **[Phase 4: Workflow Skills](phase-4-workflows.md)** -- Encode your team's entire dev process
- **[Plugins & Skills Ecosystem](plugins-and-skills.md)** -- Extend AI capabilities with community plugins
