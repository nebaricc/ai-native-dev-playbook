# Skill: Quality Standards

## Testing Requirements

### Coverage
- All new code must ship with tests. Target: {COVERAGE_THRESHOLD}% line coverage.
- Prioritize testing behavior over implementation details.
- Critical paths (auth, payments, data mutations) require integration tests.

### Test Structure
- **Unit tests**: Co-located with source (`Component.test.tsx` or `__tests__/`).
- **Integration tests**: `tests/integration/` directory.
- **E2E tests**: `tests/e2e/` directory, organized by user flow.
- **Visual regression**: `tests/visual/` with Playwright screenshot comparisons.

### Test Naming
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
- Happy path and primary error cases.
- Boundary conditions and edge cases.
- User-visible behavior, not internal implementation.
- State transitions and side effects.

### What NOT to Test
- Third-party library internals.
- Trivial getters/setters with no logic.
- Framework boilerplate.

## Design Principles

### Clean Code
- **Max 40 lines per function.** If longer, extract helpers. This is a hard limit.
- **One responsibility per function.** A function that fetches, transforms, and writes should be three functions.
- **Descriptive names.** `isLoading`, `handleSubmit`, `getUserById` -- not `x`, `tmp`, `data2`.
- **No dead code.** No commented-out blocks, no unused imports, no unreachable branches. Delete it.
- **No magic numbers.** Extract to named constants: `const MAX_RETRIES = 3`, not bare `3`.
- **No nested ternaries.** If the logic needs nesting, use early returns or a helper function.

### DRY (Don't Repeat Yourself)
- Extract shared logic into utility functions or hooks.
- Use generics to avoid duplicating type-safe patterns.
- But: prefer duplication over the wrong abstraction. Wait for 3 instances before extracting.

### SOLID
- **Single Responsibility**: Each module/function does one thing. If you need "and" to describe it, split it.
- **Open/Closed**: Extend via composition (hooks, middleware, decorators), not by modifying existing functions.
- **Liskov Substitution**: Subtypes must be substitutable for their base types.
- **Interface Segregation**: Prefer small, focused interfaces. `UserAuth` and `UserProfile` over a `User` god-type.
- **Dependency Inversion**: Depend on abstractions, not concrete implementations. Inject dependencies, don't import singletons.

### Code Organization
- Co-locate related code (component + styles + tests + types).
- Keep modules shallow -- avoid deeply nested directory trees.
- Barrel exports at module boundaries, not everywhere.
- **Max file length: 300 lines.** If a file grows beyond this, it's doing too much. Split it.

## Security Rules

- Never commit secrets, API keys, or credentials.
- Validate all external input (user input, API responses, URL params).
- Use parameterized queries -- never interpolate into SQL/queries.
- Sanitize data before rendering in HTML contexts.
- Apply principle of least privilege for API permissions and scopes.
- Keep dependencies updated. Audit with `{PACKAGE_MANAGER} audit` regularly.
- Use environment variables for configuration. Never hardcode URLs or secrets.

## Performance Guidelines

- Lazy-load routes and heavy components.
- Memoize expensive computations and stable references.
- Avoid unnecessary re-renders (React.memo, useMemo, useCallback where measured).
- Optimize images (proper formats, sizing, lazy loading).
- Monitor bundle size -- flag significant increases in PR review.

## Accessibility

- All interactive elements must be keyboard accessible.
- Use semantic HTML elements (`button`, `nav`, `main`, not div-for-everything).
- Provide alt text for images. Use aria-labels where semantics are insufficient.
- Test with screen readers for critical user flows.
