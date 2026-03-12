# Visual Regression Testing Guide

Visual regression testing catches UI bugs that unit tests miss. When an AI agent refactors a component, it can break layout, spacing, or styling without any test failing. Screenshot comparisons fix that.

This guide uses Playwright. The patterns adapt to any framework.

---

## Why Visual Tests Matter for AI-Assisted Development

AI tools are confident refactorers. They'll restructure a component, update the class names, and the unit tests still pass because the tests check behavior, not appearance. Meanwhile, the sidebar is now 400px wide instead of 240px.

Visual tests take screenshots of rendered pages and compare them against known-good baselines. If a single pixel changes beyond the threshold, the test fails. This is the only reliable way to catch CSS and layout regressions from AI-generated code.

---

## Three-Tier Strategy

Not every page needs the same level of coverage. Use tiers:

**@smoke (Tier 1):** Critical paths only. Login, dashboard, main CRUD pages. Run on every PR. 5-10 tests. Must complete in under 2 minutes.

**@core (Tier 2):** All major features. Settings, reports, secondary workflows. Run on every PR. 15-30 tests. Under 5 minutes.

**@full (Tier 3):** Everything including edge cases. Empty states, error pages, long content, mobile viewports. Run nightly. 50+ tests. Time is less constrained.

Tag tests so you can run subsets:

```typescript
test('dashboard renders correctly @smoke @visual', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard.png');
});

test('settings page renders correctly @core @visual', async ({ page }) => {
  await page.goto('/settings');
  await expect(page).toHaveScreenshot('settings.png');
});
```

---

## Self-Contained Test Infrastructure

Visual tests must be deterministic. That means no shared databases, no external APIs, no state leaking between tests.

**Database containers:** Use Docker or testcontainers to spin up a fresh database per test run.

```typescript
// global-setup.ts
import { execSync } from 'child_process';

export default async function globalSetup() {
  // Start a fresh database container
  execSync('docker compose -f docker-compose.test.yml up -d --wait', {
    stdio: 'inherit',
  });

  // Run migrations and seed data
  execSync('npx prisma migrate deploy', { stdio: 'inherit' });
  execSync('npx tsx tests/seed.ts', { stdio: 'inherit' });
}
```

**Auth emulators:** If you use Firebase, Supabase, or similar, run their local emulators. Don't hit production auth in tests.

**Seed data:** Create a minimal, deterministic dataset. Same users, same content, every time. Never use random data in visual tests -- it changes the screenshots.

---

## Playwright Visual Config

Lock down every variable that could cause pixel differences:

```typescript
// playwright.visual.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/visual',
  testMatch: '**/*.visual.spec.ts',

  // Only Chromium -- cross-browser visual tests are a maintenance nightmare
  projects: [
    {
      name: 'chromium',
      use: {
        browserName: 'chromium',
        viewport: { width: 1280, height: 720 },
        // Disable animations -- they cause flaky screenshots
        launchOptions: {
          args: ['--font-render-hinting=none'],
        },
      },
    },
  ],

  expect: {
    toHaveScreenshot: {
      // Allow tiny anti-aliasing differences
      maxDiffPixelRatio: 0.01,
      // Wait for fonts and images to load
      animations: 'disabled',
      caret: 'hide',
    },
  },

  // Longer timeout for visual tests -- pages need to fully render
  timeout: 30_000,

  // Retries help with flaky rendering
  retries: 1,

  globalSetup: './tests/global-setup.ts',
  globalTeardown: './tests/global-teardown.ts',
});
```

---

## Auth Setup Pattern

Most apps require login. Use Playwright's storageState to authenticate once and reuse across tests.

```typescript
// tests/auth-setup.ts
import { chromium, type FullConfig } from '@playwright/test';

export default async function authSetup(config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Log in as the test user
  await page.goto('/login');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'test-password-123');
  await page.click('button[type="submit"]');
  await page.waitForURL('/dashboard');

  // Save auth state
  await page.context().storageState({ path: './tests/.auth/user.json' });
  await browser.close();
}
```

Reference it in your config:

```typescript
use: {
  storageState: './tests/.auth/user.json',
},
```

Add `tests/.auth/` to `.gitignore`.

---

## Baseline Management

**Linux-only baselines.** Font rendering differs between macOS, Windows, and Linux. If developers generate baselines on their Macs and CI runs on Linux, every test fails. Solution: only generate and compare baselines on Linux (in CI).

**CI workflow for baseline generation:**

```yaml
# .github/workflows/visual-baselines.yml
name: Update Visual Baselines
on:
  workflow_dispatch:
  push:
    branches: [dev]
    paths: ['tests/visual/**', 'src/components/**']

jobs:
  update-baselines:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npx playwright install chromium --with-deps
      - run: npx playwright test --config=playwright.visual.config.ts --update-snapshots
      - uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: 'test: update visual baselines'
          file_pattern: '**/*.png'
```

**Local development:** Developers don't run visual comparisons locally. They write the tests, push, and CI generates or compares baselines. If you must run locally for debugging, use `--update-snapshots` and don't commit the results.

---

## Nightly Regression Workflow

Run the full visual suite nightly to catch regressions from dependency updates or cumulative small changes:

```yaml
# .github/workflows/visual-nightly.yml
name: Nightly Visual Regression
on:
  schedule:
    - cron: '0 6 * * *'  # 6 AM UTC daily

jobs:
  visual-regression:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npx playwright install chromium --with-deps
      - run: npx playwright test --config=playwright.visual.config.ts --grep @full
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: visual-regression-report
          path: test-results/
```

---

## Adding New Visual Tests

Decision tree for which tier:

1. Is this a page users see every session? (Login, dashboard, main list view) --> **@smoke**
2. Is this a page users see regularly? (Settings, detail views, forms) --> **@core**
3. Is this an edge case? (Empty states, error pages, long content, mobile) --> **@full**

Template for a new visual test:

```typescript
import { test, expect } from '@playwright/test';

test('invoice detail page @core @visual', async ({ page }) => {
  // Navigate to a deterministic URL (seeded data)
  await page.goto('/invoices/test-invoice-001');

  // Wait for dynamic content to settle
  await page.waitForLoadState('networkidle');

  // Hide non-deterministic elements
  await page.evaluate(() => {
    document.querySelectorAll('[data-testid="timestamp"]').forEach(el => {
      (el as HTMLElement).style.visibility = 'hidden';
    });
  });

  await expect(page).toHaveScreenshot('invoice-detail.png');
});
```

---

## Common Gotchas

**Font rendering:** Different OS versions render fonts differently. This is why baselines must be Linux-only, generated in CI. Even different Ubuntu versions can differ -- pin your runner image.

**Animations:** Disable them globally. CSS transitions, loading spinners, skeleton screens -- all cause flaky tests. Use `animations: 'disabled'` in Playwright config and add `* { transition: none !important; animation: none !important; }` to test stylesheets if needed.

**Network timing:** Use `waitForLoadState('networkidle')` or explicit waits for specific elements. Don't use fixed `sleep()` calls -- they're slow and still flaky.

**Timestamps and relative dates:** Hide or freeze them. "3 minutes ago" changes every time. Either mock the clock or hide these elements in screenshots.

**Third-party widgets:** Chat widgets, analytics banners, cookie notices -- block them in tests or hide them. They change without warning.

**Scrollbars:** Different OS settings show/hide scrollbars. Use `scrollbar-width: none` in test stylesheets or crop screenshots to avoid scrollbar areas.

---

## Adapting for Different Frameworks

**Next.js:** The setup above works directly. Use `webServer` in Playwright config to start `next dev` or `next start`.

**Django:** Use `manage.py testserver` with a fixture-loaded SQLite database. Playwright connects to it the same way.

**SvelteKit:** Similar to Next.js. Use `webServer` to start `vite preview` or the dev server.

**Rails:** Use `rails server -e test` with a seeded test database. Consider `database_cleaner` for isolation.

The Playwright config stays the same across frameworks. Only the server startup and seed data differ.
