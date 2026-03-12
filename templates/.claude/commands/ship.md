# /ship -- Validate, commit, and open a PR for current changes

## Workflow

### 1. Map Tests
- Identify all changed source files.
- For each changed source file, find or create the corresponding test file.
- Write missing tests to cover the new/changed behavior.

### 2. Quality Gate
Run all checks and fix issues before proceeding:
```
{PACKAGE_MANAGER} run type-check
{PACKAGE_MANAGER} run lint
{PACKAGE_MANAGER} run test
```
If any check fails, fix the issue and re-run. Do not skip checks.

### 3. Commit
- Stage specific files (never `git add .` or `git add -A`).
- Use conventional commit format: `type(scope): description`
- Group related changes into logical commits if appropriate.

### 4. Push and Create PR
```
git push -u origin HEAD
```
Create PR targeting `{DEV_BRANCH}`:
- Title: `type(scope): description ({TICKET_PREFIX}-ID)`
- Body: Summary of what/why, list of changes, test plan.
- Keep PR under 10 files. If over, suggest splitting.

### 5. Report Summary
Output a summary table:
| Metric | Value |
|--------|-------|
| Files changed | N |
| Tests added/modified | N |
| Type-check | pass/fail |
| Lint | pass/fail |
| Tests | pass/fail |
| PR URL | link |
