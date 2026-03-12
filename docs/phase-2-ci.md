# Phase 2: CI Enforcement

Rules without CI gates are suggestions. AI agents follow context-file rules about 80% of the time. That sounds high until you realize the remaining 20% lands in your PR review queue, wastes your time, and occasionally ships. CI enforcement converts suggestions into guarantees.

This guide covers: automated PR review, pre-push hooks, repository settings, PR title formatting, stack adaptation, and verification.

---

## 1. Why Enforcement Matters

An AI agent told "always write tests" will write tests most of the time. But when it is juggling a complex refactor across six files, it will sometimes skip the test file. When it is generating a new API route, it will sometimes forget the coverage requirement. These are not failures of the AI -- they are failures of the system around it.

CI enforcement catches these gaps mechanically. The agent learns nothing from the catch, but the codebase stays clean regardless. That is the point. You are not training the agent. You are protecting the repository.

Three principles:

1. **Block, don't nag.** A CI check that posts a warning and passes anyway teaches agents (and humans) to ignore it. If something matters, fail the build.
2. **Fast feedback.** Every CI check should finish in under two minutes. Slow checks get ignored or worked around.
3. **Actionable errors.** "CI failed" is useless. "Missing test file for src/services/billing.ts -- expected src/services/billing.test.ts" tells the agent exactly what to fix.

---

## 2. PR Review Automation

Create `.github/workflows/ci-review.yml`. This workflow runs on every pull request and enforces three checks: PR size, test coverage mapping, and an automated review checklist.

```yaml
name: PR Review Gate

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write

jobs:
  pr-size-check:
    name: PR Size Check
    runs-on: ubuntu-latest
    steps:
      - name: Check file count
        uses: actions/github-script@v7
        with:
          script: |
            const { data: files } = await github.rest.pulls.listFiles({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
              per_page: 100,
            });

            const fileCount = files.length;
            const WARN_THRESHOLD = 10;
            const BLOCK_THRESHOLD = 30;

            if (fileCount > BLOCK_THRESHOLD) {
              core.setFailed(
                `PR touches ${fileCount} files (limit: ${BLOCK_THRESHOLD}). ` +
                `Split this into smaller PRs. Large PRs are harder to review ` +
                `and more likely to introduce regressions.`
              );
            } else if (fileCount > WARN_THRESHOLD) {
              core.warning(
                `PR touches ${fileCount} files. Consider splitting if these ` +
                `changes are not tightly coupled.`
              );
            } else {
              core.info(`PR touches ${fileCount} files. Looks good.`);
            }

  test-coverage-check:
    name: Test Coverage Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Map changed files to test files
        uses: actions/github-script@v7
        with:
          script: |
            const { data: files } = await github.rest.pulls.listFiles({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
              per_page: 100,
            });

            const fs = require('fs');
            const path = require('path');

            // Source directories that require tests
            const SOURCE_DIRS = ['src/'];
            // Directories inside src/ that are exempt from test requirements
            const EXEMPT_PATTERNS = [
              /^src\/types\//,
              /^src\/styles\//,
              /^src\/assets\//,
              /\.d\.ts$/,
              /^src\/.*\/index\.(ts|js)$/,  // barrel files
            ];

            // Map source file to expected test file paths
            function testPathsFor(filePath) {
              const ext = path.extname(filePath);
              const base = filePath.replace(ext, '');
              return [
                `${base}.test${ext}`,
                `${base}.spec${ext}`,
                `${base}.test.tsx`,
                `${base}.spec.tsx`,
                // Co-located test directory
                `${path.dirname(filePath)}/__tests__/${path.basename(base)}${ext}`,
                `${path.dirname(filePath)}/__tests__/${path.basename(base)}.test${ext}`,
              ];
            }

            const changedSourceFiles = files
              .filter(f => f.status !== 'removed')
              .map(f => f.filename)
              .filter(f => SOURCE_DIRS.some(d => f.startsWith(d)))
              .filter(f => !EXEMPT_PATTERNS.some(p => p.test(f)))
              .filter(f => !f.includes('.test.') && !f.includes('.spec.') && !f.includes('__tests__'));

            const missing = [];

            for (const srcFile of changedSourceFiles) {
              const candidates = testPathsFor(srcFile);
              const hasTest = candidates.some(c => fs.existsSync(c));
              // Also check if a test file for this source was added in the PR
              const addedInPR = files.map(f => f.filename);
              const coveredByPR = candidates.some(c => addedInPR.includes(c));

              if (!hasTest && !coveredByPR) {
                missing.push({ source: srcFile, expected: candidates[0] });
              }
            }

            if (missing.length > 0) {
              const list = missing
                .map(m => `  - ${m.source} -> expected ${m.expected}`)
                .join('\n');
              core.setFailed(
                `Missing test files for ${missing.length} changed source file(s):\n${list}\n\n` +
                `Every source file in src/ needs a corresponding test file. ` +
                `Add tests or mark the file as exempt in ci-review.yml.`
              );
            } else if (changedSourceFiles.length > 0) {
              core.info(`All ${changedSourceFiles.length} changed source files have test coverage.`);
            } else {
              core.info('No source files changed that require tests.');
            }

  ai-review:
    name: AI Review Checklist
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate and post review checklist
        uses: actions/github-script@v7
        with:
          script: |
            const { data: files } = await github.rest.pulls.listFiles({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
              per_page: 100,
            });

            const filenames = files.map(f => f.filename);
            const checks = [];

            // 1. Missing tests
            const srcFiles = filenames.filter(f =>
              f.startsWith('src/') &&
              !f.includes('.test.') &&
              !f.includes('.spec.') &&
              !f.includes('__tests__')
            );
            const testFiles = filenames.filter(f =>
              f.includes('.test.') || f.includes('.spec.') || f.includes('__tests__')
            );
            if (srcFiles.length > 0 && testFiles.length === 0) {
              checks.push('- [ ] **Missing tests** -- source files changed but no test files in this PR');
            } else if (testFiles.length > 0) {
              checks.push('- [x] **Tests included** -- test files present in this PR');
            }

            // 2. UI changes without screenshots
            const uiExtensions = ['.tsx', '.jsx', '.css', '.scss', '.vue', '.svelte'];
            const hasUIChanges = srcFiles.some(f => uiExtensions.some(ext => f.endsWith(ext)));
            if (hasUIChanges) {
              checks.push('- [ ] **UI screenshot needed** -- this PR changes UI files, add a before/after screenshot to the description');
            }

            // 3. Config or secret exposure
            const sensitivePatterns = ['.env', 'secret', 'credential', 'token', 'apikey', 'api_key'];
            const sensitiveFiles = filenames.filter(f =>
              sensitivePatterns.some(p => f.toLowerCase().includes(p))
            );
            if (sensitiveFiles.length > 0) {
              checks.push(
                `- [ ] **Sensitive file changed** -- verify no secrets exposed: ${sensitiveFiles.join(', ')}`
              );
            }

            // 4. Scope check for large PRs
            if (filenames.length > 10) {
              checks.push(
                `- [ ] **Large PR (${filenames.length} files)** -- confirm all changes are related to a single concern`
              );
            }

            // 5. Migration or schema changes
            const hasMigration = filenames.some(f =>
              f.includes('migration') || f.includes('schema') || f.includes('.prisma')
            );
            if (hasMigration) {
              checks.push('- [ ] **Schema/migration changed** -- confirm migration is reversible and tested');
            }

            if (checks.length === 0) {
              core.info('No review items flagged.');
              return;
            }

            const body = [
              '## Automated Review Checklist',
              '',
              'The following items were flagged by CI. Address each before merging.',
              '',
              ...checks,
              '',
              '---',
              '*Posted by ci-review workflow. Updated on each push.*',
            ].join('\n');

            // Upsert: find existing comment from this workflow, update or create
            const MARKER = '## Automated Review Checklist';
            const { data: comments } = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
            });

            const existing = comments.find(c =>
              c.user.type === 'Bot' && c.body.startsWith(MARKER)
            );

            if (existing) {
              await github.rest.issues.updateComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: existing.id,
                body,
              });
              core.info('Updated existing review checklist comment.');
            } else {
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
                body,
              });
              core.info('Posted new review checklist comment.');
            }
```

Key design decisions in this workflow:

- **Upsert pattern for comments.** The ai-review job searches for an existing comment starting with the `## Automated Review Checklist` marker. If found, it updates rather than creating a new one. This prevents comment spam when the PR is pushed to multiple times.
- **`per_page: 100` on file listing.** GitHub paginates at 30 by default. PRs with more than 30 files would silently miss coverage checks without this.
- **Exempt patterns are explicit.** Type definition files, barrel exports, and style files do not require tests. Add to `EXEMPT_PATTERNS` as your project dictates.

---

## 3. Pre-push Hooks

CI catches problems after a push. Pre-push hooks catch them before. This saves time and keeps the commit history clean.

Create `.githooks/pre-push`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Running pre-push checks..."

# Type checking (skip if no tsconfig)
if [ -f "tsconfig.json" ]; then
  echo "  Type checking..."
  npx --no-install tsc --noEmit --pretty 2>&1 | tail -20
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "FAILED: Type errors found. Fix before pushing."
    exit 1
  fi
  echo "  Types OK."
fi

# Run tests related to changed files
CHANGED_FILES=$(git diff --name-only HEAD @{upstream} 2>/dev/null || git diff --name-only HEAD~1)
TEST_FILES=""

for f in $CHANGED_FILES; do
  # Skip non-source files
  case "$f" in
    src/*.ts|src/*.tsx|src/*.js|src/*.jsx)
      base="${f%.*}"
      for candidate in "${base}.test.ts" "${base}.test.tsx" "${base}.spec.ts" "${base}.spec.tsx"; do
        if [ -f "$candidate" ]; then
          TEST_FILES="$TEST_FILES $candidate"
          break
        fi
      done
      ;;
  esac
done

if [ -n "$TEST_FILES" ]; then
  echo "  Running tests for changed files..."
  npx --no-install vitest run $TEST_FILES --reporter=verbose 2>&1 | tail -30
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "FAILED: Tests failed. Fix before pushing."
    exit 1
  fi
  echo "  Tests OK."
else
  echo "  No test files affected by changes. Skipping."
fi

echo "Pre-push checks passed."
```

### Setup

Configure git to use the project hooks directory:

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-push
```

Add a setup script in `package.json` so new contributors get hooks automatically:

```json
{
  "scripts": {
    "prepare": "git config core.hooksPath .githooks"
  }
}
```

### Husky Alternative

If your team already uses Husky, add the same logic to `.husky/pre-push` instead. The hook content is identical -- only the directory differs. Avoid running both systems simultaneously.

```bash
npx husky add .husky/pre-push "bash .githooks/pre-push"
```

---

## 4. GitHub Repository Settings

These settings are applied manually in the GitHub UI or via the GitHub API. They complement CI checks.

### Branch Protection on `dev`

Go to Settings > Branches > Add rule for `dev`:

- **Require status checks to pass before merging:** Enable. Add `PR Size Check`, `Test Coverage Check`, and your test suite workflow as required checks.
- **Require branches to be up to date before merging:** Enable. Prevents merging stale branches that pass CI but conflict with recent changes.
- **Require pull request reviews before merging:** At least 1 approval. For teams with AI agents, this ensures a human sees every change.
- **Do not allow bypassing the above settings:** Enable. This applies the rules to admins too.

### Auto-merge and Auto-delete

- **Allow auto-merge:** Enable. Once all checks pass and approvals are in, the PR merges without manual clicking. Keeps the queue moving.
- **Automatically delete head branches:** Enable. Merged branches clutter the branch list. Delete them automatically.

### CODEOWNERS

Create `.github/CODEOWNERS` to require specific reviewers for sensitive paths:

```
# Default owner for everything
* @your-org/engineering

# Infrastructure changes require platform team review
.github/         @your-org/platform
terraform/        @your-org/platform
docker-compose.*  @your-org/platform

# Database changes require backend lead
prisma/           @your-org/backend-lead
**/migrations/    @your-org/backend-lead
```

CODEOWNERS works with branch protection. When "Require review from Code Owners" is enabled, PRs touching these paths cannot merge without approval from the listed owners.

---

## 5. PR Title Formatting

Consistent PR titles make changelogs readable and help teams scan PR lists quickly. Use conventional commit format:

```
type(scope): description (TICKET-ID)
```

Examples:
```
feat(billing): add Stripe webhook handler (NEB-142)
fix(auth): handle expired refresh tokens (NEB-198)
chore(ci): add test coverage check to PR gate (NEB-201)
test(api): add integration tests for user endpoints (NEB-205)
```

### Auto-format from Branch Name

If your team uses branch names like `NEB-142-stripe-webhook`, a workflow can suggest or enforce the title format.

Add this to your CI review workflow or as a separate workflow:

```yaml
  pr-title-check:
    name: PR Title Format
    runs-on: ubuntu-latest
    steps:
      - name: Check conventional commit format
        uses: actions/github-script@v7
        with:
          script: |
            const title = context.payload.pull_request.title;
            const pattern = /^(feat|fix|chore|docs|test|refactor|style|perf|ci|build|revert)\(.+\): .+ \([A-Z]+-\d+\)$/;

            if (!pattern.test(title)) {
              core.setFailed(
                `PR title does not match format: type(scope): description (TICKET-ID)\n` +
                `Got: "${title}"\n` +
                `Example: feat(billing): add Stripe webhook handler (NEB-142)\n` +
                `Valid types: feat, fix, chore, docs, test, refactor, style, perf, ci, build, revert`
              );
            }
```

### Deriving from Branch Name

For AI agents that create branches from Jira tickets, you can extract the ticket ID automatically. In your CLAUDE.md, add:

```markdown
## Branch Naming
Branch names follow: TICKET-ID-short-description
Example: NEB-142-stripe-webhook

## PR Titles
Format: type(scope): description (TICKET-ID)
Extract the ticket ID from the branch name.
```

The agent will follow this most of the time. The CI check catches the rest.

---

## 6. Adapting for Different Stacks

The examples above assume a TypeScript project with Vitest. Here is how to adapt each piece for other stacks.

### Package Manager

Replace `npx --no-install` in hooks:

| Stack   | Type Check              | Test Command                          |
|---------|-------------------------|---------------------------------------|
| npm     | `npx tsc --noEmit`      | `npx vitest run`                      |
| pnpm    | `pnpm tsc --noEmit`     | `pnpm vitest run`                     |
| yarn    | `yarn tsc --noEmit`     | `yarn vitest run`                     |
| poetry  | `poetry run mypy .`     | `poetry run pytest`                   |
| cargo   | `cargo check`           | `cargo test`                          |

### Test File Conventions

Update `EXEMPT_PATTERNS` and `testPathsFor` in the CI workflow:

| Framework | Test File Pattern                  | Location                        |
|-----------|------------------------------------|---------------------------------|
| Vitest    | `*.test.ts`, `*.spec.ts`           | Co-located or `__tests__/`      |
| Jest      | `*.test.ts`, `*.spec.ts`           | Co-located or `__tests__/`      |
| pytest    | `test_*.py`, `*_test.py`           | `tests/` mirror of `src/`       |
| Go        | `*_test.go`                        | Same package                    |
| RSpec     | `*_spec.rb`                        | `spec/` mirror of `app/`        |

For pytest, the test path mapping function becomes:

```javascript
function testPathsFor(filePath) {
  // src/services/billing.py -> tests/services/test_billing.py
  const testPath = filePath
    .replace(/^src\//, 'tests/')
    .replace(/(\w+)\.py$/, 'test_$1.py');
  return [testPath];
}
```

### Pre-push Hook for Python

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Running pre-push checks..."

if [ -f "pyproject.toml" ]; then
  echo "  Type checking..."
  poetry run mypy src/ --ignore-missing-imports 2>&1 | tail -20
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "FAILED: Type errors found."
    exit 1
  fi
fi

CHANGED_FILES=$(git diff --name-only HEAD @{upstream} 2>/dev/null || git diff --name-only HEAD~1)
TEST_FILES=""

for f in $CHANGED_FILES; do
  case "$f" in
    src/*.py)
      test_path=$(echo "$f" | sed 's|^src/|tests/|' | sed 's|\([^/]*\)\.py$|test_\1.py|')
      if [ -f "$test_path" ]; then
        TEST_FILES="$TEST_FILES $test_path"
      fi
      ;;
  esac
done

if [ -n "$TEST_FILES" ]; then
  echo "  Running tests..."
  poetry run pytest $TEST_FILES -v 2>&1 | tail -30
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "FAILED: Tests failed."
    exit 1
  fi
fi

echo "Pre-push checks passed."
```

---

## 7. Verification

After setting up CI enforcement, verify that it actually catches violations. Do not trust that a workflow file is correct just because it committed cleanly.

### Test PR Size Check

Create a branch, generate a trivial change in 31+ files, open a PR, and confirm the check fails:

```bash
git checkout -b test/ci-size-check
for i in $(seq 1 31); do
  echo "// test" >> "src/test-file-${i}.ts"
done
git add . && git commit -m "test: verify PR size check blocks at 31 files"
git push -u origin test/ci-size-check
gh pr create --title "test(ci): verify size check" --body "Should fail size check."
```

Watch the PR checks. `PR Size Check` should fail with a message about exceeding 30 files. Close the PR and delete the branch when confirmed.

### Test Coverage Check

Create a source file without a corresponding test file:

```bash
git checkout -b test/ci-coverage-check
echo "export function uncovered() { return true; }" > src/services/uncovered.ts
git add . && git commit -m "test: verify coverage check blocks missing tests"
git push -u origin test/ci-coverage-check
gh pr create --title "test(ci): verify coverage check" --body "Should fail coverage."
```

The `Test Coverage Check` job should fail, listing `src/services/uncovered.ts` as missing a test file.

### Test PR Title Check

```bash
gh pr create --title "updated stuff" --body "Should fail title check."
```

The title check should reject this because it does not match `type(scope): description (TICKET-ID)`.

### Test Pre-push Hook

Introduce a type error locally and attempt to push:

```bash
echo "const x: number = 'not a number';" > src/type-error-test.ts
git add . && git commit -m "test: should be caught by pre-push"
git push  # Should fail with type error
```

If the hook does not fire, verify `git config core.hooksPath` returns `.githooks` and the hook file is executable.

### Ongoing Verification

Add a note to your CLAUDE.md:

```markdown
## CI Checks
All PRs must pass: PR Size Check, Test Coverage Check, PR Title Format.
If a check is failing incorrectly, fix the workflow -- do not skip the check.
```

This tells AI agents that the checks are intentional and should not be worked around.
