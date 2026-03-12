# Phase 3: Testing Standards -- Implementation Guide

AI tools can write tests faster than any human. That is the problem. Speed without standards produces a test suite that looks comprehensive and catches nothing. This guide covers how to enforce test quality in AI-assisted codebases, from assertion rules to visual regression infrastructure to retrofitting tests into legacy code.

---

## Why AI-Generated Tests Need Special Attention

AI-generated tests have a unique failure mode: they describe what the code does, not what it should do. The AI reads the implementation, then writes assertions that mirror it. If the implementation is wrong, the tests pass anyway.

Three patterns show up repeatedly:

**1. Tautological testing.** The AI reads a function that calculates `price * quantity * 0.9` and writes a test asserting the result equals `price * quantity * 0.9`. If the discount should be 0.85, both the code and the test are wrong together.

**2. Over-mocking.** The AI mocks every dependency, including the thing being tested. A database service test that mocks the database is testing mock behavior, not query logic. The real query could have a syntax error and the test would pass.

**3. Weak assertions.** The AI confirms something exists rather than confirming it is correct. `expect(result).toBeDefined()` passes for literally any non-undefined value. It tells you nothing about correctness.

These patterns are insidious because the test suite looks healthy. Coverage is high. All tests pass. But introduce a real bug and nothing catches it.

The fix is standards: explicit rules about what constitutes a valid test, enforced in CI and in code review.

---

## Test Quality Rules

The table below lists the most common weak patterns and their replacements. Add these rules to your CLAUDE.md so AI tools follow them during generation.

### Bad vs Good Assertion Patterns

| Bad Pattern | Why It Is Bad | Good Pattern |
|---|---|---|
| `expect(result).toBeDefined()` | Passes for any value, including wrong ones | `expect(result).toEqual({ id: 1, name: 'Alice' })` |
| `expect(result).toBeTruthy()` | Passes for `1`, `"yes"`, `[]`, `{}` -- none of which may be correct | `expect(result).toBe(true)` or `expect(element).toBeInTheDocument()` |
| `expect(result).not.toBeNull()` | Only rules out one value | `expect(result).toHaveLength(3)` or assert on specific shape |
| Empty test body (`it('should work', () => {})`) | Gives false coverage signal, tests nothing | Delete it or write a real assertion |
| `expect(fn).not.toThrow()` as the only assertion | Confirms no crash, not correctness | Assert on the return value or side effects |
| `expect(wrapper).toMatchSnapshot()` | Snapshot of entire component is brittle and rarely reviewed | Target specific elements or use visual regression |

### Structural Anti-Patterns

**Testing implementation instead of behavior:**

```typescript
// Bad -- tests internal state, breaks on refactor
it('sets loading to true', () => {
  const { result } = renderHook(() => useFetchUsers());
  act(() => result.current.fetch());
  expect(result.current.loading).toBe(true);
});

// Good -- tests what the user sees
it('shows a loading spinner while fetching users', async () => {
  render(<UserList />);
  await userEvent.click(screen.getByRole('button', { name: /load/i }));
  expect(screen.getByRole('progressbar')).toBeInTheDocument();
});
```

**Over-mocking:**

```typescript
// Bad -- mocks the database in a database service test
it('returns user by id', async () => {
  prismaMock.user.findUnique.mockResolvedValue({ id: 1, name: 'Alice' });
  const user = await userService.getById(1);
  expect(user).toEqual({ id: 1, name: 'Alice' });
  // This only tests that your mock returns what you told it to return
});

// Good -- uses a real database (via testcontainers or similar)
it('returns user by id', async () => {
  await db.user.create({ data: { id: 1, name: 'Alice' } });
  const user = await userService.getById(1);
  expect(user).toEqual(expect.objectContaining({ id: 1, name: 'Alice' }));
});
```

**Missing negative cases:**

```typescript
// Bad -- only tests the happy path
describe('validateEmail', () => {
  it('accepts valid email', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });
});

// Good -- tests both valid and invalid inputs
describe('validateEmail', () => {
  it('accepts valid email', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  it('rejects email without @ sign', () => {
    expect(validateEmail('userexample.com')).toBe(false);
  });

  it('rejects email without domain', () => {
    expect(validateEmail('user@')).toBe(false);
  });

  it('rejects empty string', () => {
    expect(validateEmail('')).toBe(false);
  });
});
```

---

## Naming Conventions

Test names should describe behavior from the user's perspective, not implementation details. A reader should understand what the feature does by reading test names alone.

**Format:** `[action] when [condition]` or `shows [element] when [state]`

```typescript
// Bad -- describes implementation
it('calls handleSubmit', () => { /* ... */ });
it('sets state to true', () => { /* ... */ });
it('renders component', () => { /* ... */ });

// Good -- describes behavior
it('submits the form when all required fields are filled', () => { /* ... */ });
it('shows error message when email is invalid', () => { /* ... */ });
it('redirects to dashboard after successful login', () => { /* ... */ });
it('disables submit button while request is in flight', () => { /* ... */ });
```

**Describe blocks** should mirror the module or component, not the internal method names:

```typescript
// Bad
describe('UserForm', () => {
  describe('handleChange', () => { /* ... */ });
  describe('handleSubmit', () => { /* ... */ });
});

// Good
describe('UserForm', () => {
  describe('field validation', () => { /* ... */ });
  describe('form submission', () => { /* ... */ });
  describe('error display', () => { /* ... */ });
});
```

---

## Visual Regression Testing Overview

Unit tests catch logic bugs. Visual tests catch layout bugs. If your project has a UI, you need both.

This section covers the essentials. See [visual-testing.md](visual-testing.md) for the full deep dive including Playwright config, auth setup, baseline management, and framework-specific guidance.

### Three-Tier Strategy

Not every page needs the same coverage frequency:

- **@smoke (Tier 1):** Login, dashboard, primary CRUD pages. Run on every PR. 5-10 tests, under 2 minutes.
- **@core (Tier 2):** Settings, reports, secondary workflows. Run on every PR. 15-30 tests, under 5 minutes.
- **@full (Tier 3):** Empty states, error pages, mobile viewports, edge cases. Run nightly. 50+ tests.

Tag tests so CI can run the right subset:

```typescript
test('dashboard renders correctly @smoke @visual', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard.png');
});
```

### Linux-Only Baselines

Font rendering differs between macOS, Windows, and Linux. If a developer generates baselines on a Mac and CI runs on Ubuntu, every screenshot comparison fails due to sub-pixel font differences.

The solution: baselines are generated and compared only in CI, on Linux. Developers write visual tests locally but never commit locally-generated screenshots. A dedicated CI workflow generates baselines on push to the main development branch.

### Self-Contained Infrastructure

Visual tests must be deterministic. That means:

- **Database containers:** Spin up a fresh Postgres (or equivalent) per test run using Docker Compose or testcontainers. No shared databases.
- **Auth emulators:** Use Firebase Local Emulator Suite, Supabase local, or equivalent. Never hit production auth in tests.
- **Seed data:** A fixed, minimal dataset. Same users, same content, every run. Never use `Math.random()` or `faker` in visual test seed data.
- **Frozen timestamps:** Hide or mock relative dates ("3 minutes ago") and clocks. They change between runs.

### Playwright Config Essentials

Lock down the variables that cause flaky screenshots:

- Single browser (Chromium only -- cross-browser visual tests are a maintenance burden)
- Fixed viewport (1280x720)
- Animations disabled globally
- Caret hidden
- Anti-aliasing tolerance set to ~1% pixel ratio
- Retries set to 1 for rendering jitter

See [visual-testing.md](visual-testing.md) for the full config.

---

## Coverage Enforcement

Coverage thresholds without CI enforcement are suggestions. Wire them into your pipeline.

### CI Job: test-coverage-check

```yaml
# .github/workflows/ci.yml (excerpt)
test-coverage-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with: { node-version: '20' }
    - run: npm ci
    - run: npx vitest run --coverage --coverage.reporter=json-summary
    - name: Check coverage threshold
      run: |
        COVERAGE=$(node -e "
          const c = require('./coverage/coverage-summary.json');
          console.log(Math.round(c.total.lines.pct));
        ")
        echo "Line coverage: ${COVERAGE}%"
        if [ "$COVERAGE" -lt 70 ]; then
          echo "Coverage ${COVERAGE}% is below 70% threshold"
          exit 1
        fi
```

Adjust the threshold to match your project. 70% is a reasonable starting point. Raise it as test quality improves, but never lower it to make a failing build pass.

### Pre-Push Hook

Catch coverage regressions before they reach CI. This saves round-trip time.

```bash
#!/bin/sh
# .husky/pre-push

echo "Running tests with coverage check..."
npx vitest run --coverage --coverage.reporter=json-summary 2>/dev/null

COVERAGE=$(node -e "
  const c = require('./coverage/coverage-summary.json');
  console.log(Math.round(c.total.lines.pct));
")

THRESHOLD=70

if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "BLOCKED: Line coverage is ${COVERAGE}%, minimum is ${THRESHOLD}%."
  echo "Add tests before pushing."
  exit 1
fi

echo "Coverage: ${COVERAGE}% (threshold: ${THRESHOLD}%). Proceeding."
```

### CLAUDE.md Rule

Add this to your project's CLAUDE.md so AI tools know about the requirement:

```markdown
## Testing
- All new code must include tests. No exceptions.
- Coverage must not decrease. Run `npx vitest run --coverage` before committing.
- Never use .toBeDefined(), .toBeTruthy(), or .not.toBeNull() as primary assertions.
- Test behavior, not implementation. Test what the user sees, not internal state.
- Include at least one negative test case per function (error input, edge case).
```

---

## How to Retrofit Tests Into an Existing Codebase

Retrofitting tests into a codebase that has few or none is a project in itself. The wrong approach is to ask an AI to "write tests for everything." That produces hundreds of weak tests in a single PR that nobody reviews carefully.

### Step 1: Audit

Identify what exists and what is missing.

```bash
# Generate a coverage report without writing any new tests
npx vitest run --coverage --coverage.reporter=html
# Open coverage/index.html and review
```

Categorize files into:

- **Critical, untested:** Auth, payments, data mutations. These get tests first.
- **Complex, untested:** Business logic with branching. High bug risk.
- **Simple, untested:** CRUD operations, straightforward data transforms. Lower priority.
- **Already tested:** Review existing tests for quality (see weak patterns below).

### Step 2: Prioritize

Order by risk, not by size. A 50-line auth module with no tests is more dangerous than a 500-line utility file.

Prioritization criteria:
1. Code that handles money, auth, or user data
2. Code that has had bugs filed against it
3. Code with high cyclomatic complexity
4. Code that changes frequently (check git log)
5. Everything else

### Step 3: Chunk Into PRs

One PR per module or feature area. Each PR should:

- Add tests for one bounded area (e.g., "user service," "invoice calculations")
- Include 10-30 tests, not 100
- Be reviewable in a single sitting (under 500 lines of test code)
- Not change production code unless fixing a bug discovered during testing

### Step 4: Use Parallel Agents

If you are using AI agents to write tests, parallelize the work. Three independent modules can be tested by three agents simultaneously, each on its own branch. This cuts wall-clock time by 3x.

Each agent should:

1. Read the source file and any existing tests
2. Write tests following the rules in CLAUDE.md
3. Run the tests and verify they pass
4. Verify coverage improvement for that module
5. Push and create a PR

Coordinate by assigning non-overlapping file sets. Agents working on overlapping files will create merge conflicts.

### Step 5: Review Ruthlessly

AI-generated retrofit tests are especially prone to weak patterns because the AI has no specification to work from -- it can only describe what the code already does. Review every test and ask: "If I introduced a bug here, would this test catch it?"

---

## Common Weak Test Patterns AI Produces

These are the patterns to search for during code review of AI-generated tests. Each one looks like a valid test but provides little or no protection against regressions.

### 1. Existence Checks

```typescript
// Weak -- passes for literally any non-undefined return value
it('returns a user', async () => {
  const user = await getUser(1);
  expect(user).toBeDefined();
});
```

**Fix:** Assert on the shape, the specific values, or both.

### 2. Snapshot Overuse

```typescript
// Weak -- snapshot of entire component output; nobody reviews snapshot diffs
it('renders correctly', () => {
  const { container } = render(<UserProfile user={mockUser} />);
  expect(container).toMatchSnapshot();
});
```

**Fix:** Replace with targeted assertions on specific elements, or use visual regression tests for layout verification.

### 3. Implementation Mirroring

```typescript
// Weak -- the test duplicates the production logic
it('calculates total', () => {
  const items = [{ price: 10, qty: 2 }, { price: 5, qty: 3 }];
  const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  expect(calculateTotal(items)).toBe(expected);
});
```

**Fix:** Use hardcoded expected values derived from the specification, not from recalculating.

```typescript
it('calculates total', () => {
  const items = [{ price: 10, qty: 2 }, { price: 5, qty: 3 }];
  expect(calculateTotal(items)).toBe(35);
});
```

### 4. No Edge Cases

The AI writes three happy-path tests and stops. No empty arrays, no null inputs, no boundary values, no concurrent access, no permission failures.

**Fix:** For every function, require at least one test for: empty input, invalid input, and the boundary between valid and invalid.

### 5. Asserting on Mock Calls Instead of Outcomes

```typescript
// Weak -- only verifies the function was called, not what happened
it('sends welcome email', async () => {
  await registerUser({ email: 'test@example.com' });
  expect(mockEmailService.send).toHaveBeenCalledWith(
    'test@example.com',
    expect.any(String)
  );
});
```

This test does not verify that the user was actually created, that the email content is correct, or that failures are handled. Mock-call assertions have their place, but they should not be the only assertion.

**Fix:** Also assert on the outcome (user exists in database, function return value).

### 6. Tests That Cannot Fail

```typescript
// Weak -- try/catch swallows the failure
it('handles errors', async () => {
  try {
    await riskyOperation();
  } catch (e) {
    expect(e).toBeDefined();
  }
});
```

If `riskyOperation` does not throw, the test passes silently. The catch block never runs, and no assertion executes.

**Fix:** Use the framework's built-in error assertion.

```typescript
it('throws on invalid input', async () => {
  await expect(riskyOperation()).rejects.toThrow('Invalid input');
});
```

### 7. Commented-Out or Skipped Tests

AI sometimes generates `it.skip(...)` or `xit(...)` blocks for cases it cannot figure out. These inflate the apparent test count without testing anything.

**Fix:** Add a lint rule to fail on `it.skip` and `xit` in CI. If a test is not ready, do not commit it.

---

## Verification: Does Your Test Suite Actually Work?

The ultimate test of a test suite is whether it catches bugs. Run this exercise after writing tests for a module.

### The Intentional Bug Test

1. Pick a function that has tests.
2. Introduce a specific, realistic bug:
   - Change a `>=` to `>`
   - Remove a null check
   - Swap two function arguments
   - Off-by-one an array index
   - Return early before a side effect
3. Run the tests.
4. If all tests pass, your tests are too weak. Strengthen them until the bug is caught.
5. Revert the bug.

### Automated Mutation Testing

For a more systematic approach, use a mutation testing tool:

```bash
# JavaScript/TypeScript
npx stryker run

# Python
mutmut run
```

Mutation testing automatically introduces many small bugs (mutations) and checks whether tests catch them. The mutation score tells you the percentage of bugs your tests would catch. Aim for 70%+ on critical modules.

### Ongoing Verification Checklist

After each batch of AI-generated tests, verify:

- [ ] No assertions use only `.toBeDefined()`, `.toBeTruthy()`, or `.not.toBeNull()`
- [ ] No test bodies are empty or contain only comments
- [ ] No tests are skipped (`it.skip`, `xit`, `xdescribe`)
- [ ] Each test has at least one assertion with a specific expected value
- [ ] At least one negative test case exists per public function
- [ ] Tests fail when the corresponding code is broken (intentional bug test)
- [ ] Coverage increased for the targeted module
- [ ] No new mocks were introduced for the module under test itself

---

## Putting It All Together

Phase 3 is not a one-time setup. It is an ongoing discipline. The sequence:

1. **Add test quality rules to CLAUDE.md** so AI tools generate better tests from the start.
2. **Set up coverage enforcement in CI** so untested code cannot merge.
3. **Add pre-push hooks** so developers catch coverage gaps before CI.
4. **Set up visual regression infrastructure** for projects with a UI (see [visual-testing.md](visual-testing.md)).
5. **Retrofit tests** into existing untested code, prioritized by risk.
6. **Review AI-generated tests** against the weak pattern list above.
7. **Run the intentional bug test** periodically to verify test suite effectiveness.
8. **Raise the coverage threshold** as test quality improves.

The goal is not 100% coverage. The goal is that when a bug is introduced, a test fails. Coverage is a proxy metric. Test quality is the real metric. A codebase with 60% coverage of strong, behavior-focused tests is better protected than one with 95% coverage of weak, implementation-mirroring tests.
