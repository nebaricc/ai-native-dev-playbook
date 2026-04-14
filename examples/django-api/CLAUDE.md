# CLAUDE.md -- Meridian API

## Project Overview

Meridian is a multi-tenant B2B platform API. It provides REST endpoints for
managing organizations, projects, and analytics data. The API serves a React
frontend and third-party integrations.

## Architecture

```
meridian/
  settings/
    base.py         -- Shared settings
    development.py  -- Dev overrides
    production.py   -- Production settings
    test.py         -- Test settings
apps/
  accounts/         -- User model, authentication, profiles
  organizations/    -- Org management, membership, invitations
  projects/         -- Project CRUD, permissions
  analytics/        -- Data ingestion, aggregation, reporting
  notifications/    -- Email, webhook, in-app notifications
  core/             -- Shared mixins, base classes, utilities
```

## Tech Stack

- Language: Python 3.12
- Framework: Django 5.1 + Django REST Framework 3.15
- Database: PostgreSQL 16
- Cache/Queue: Redis 7 (caching + Celery broker)
- Task queue: Celery 5.x
- Dependency management: Poetry
- Testing: pytest + pytest-django + factory-boy
- Linting: Ruff (replaces flake8, isort, pyflakes)
- Formatting: Black (88 char line length)
- Type checking: mypy (strict mode)

## Branch Strategy

- Default branch: `develop`
- Production branch: `main`
- Feature branches: `feat/API-123-short-description`
- Bug fix branches: `fix/API-456-short-description`
- Always branch from `develop`, PR back to `develop`

## Ticket System

- Jira project prefix: API
- Include ticket ID in branch names and PR titles
- PR title format: `type(scope): description (API-123)`

## Commands

```bash
# Dependencies and dev server
poetry install
poetry run python manage.py runserver

# Database
poetry run python manage.py migrate              # Apply migrations
poetry run python manage.py makemigrations        # Generate migrations
poetry run python manage.py seed_dev_data         # Seed dev data

# Testing
poetry run pytest                                 # All tests
poetry run pytest apps/accounts/                  # Test specific app
poetry run pytest -x                              # Stop on first failure
poetry run pytest --cov=apps --cov-report=term-missing

# Linting & Formatting
poetry run ruff check . --fix                     # Lint + auto-fix
poetry run black .                                # Format
poetry run mypy apps/                             # Type check

# Celery
poetry run celery -A meridian worker -l info      # Worker
poetry run celery -A meridian beat -l info        # Scheduler
```

## Deterministic agent workflow

Borrowed from harness-style agent orchestration: **fix the sequence**, let the model fill in the work at each step. Same phases every time reduces skipped tests and inconsistent PRs.

| Phase | Do |
|-------|-----|
| **Classify** | Decide: bug, feature, refactor, chore, docs, or investigation. If the ask is ambiguous, ask one clarifying question before coding. |
| **Context** | Read this file, project rules, and similar code in the repo before editing. |
| **Plan** | For 3+ files or cross-package changes: list steps, files, and risks; keep the plan in the session until the PR is up. |
| **Implement** | Small steps; prefer scripts and test commands over guessing outcomes. |
| **Validate** | Run type-check, lint, and tests locally before push. CI is a backstop, not the first check. |
| **Review** | Re-read the diff; map every changed source file to a test or a short reason it cannot be tested. |
| **Ship** | Branch, commit, push, open PR using the team template and definition of done. |

**Isolation:** Use a **dedicated branch** per task. For parallel agent work, use **separate git worktrees** so runs do not overwrite each other.

**Artifacts:** When investigation or planning matters, keep a short **plan** (session summary or `plan.md` if the team uses it) so implementation does not drift from agreed scope.

**Loops:** **Implement until green** (fix and re-run tests until they pass). **Review until done** (address feedback on the same branch before merge).

## Code Conventions

- All apps registered as `apps.accounts`, `apps.projects`, etc.
- Custom user model in `apps/accounts/models.py` -- never use Django's default User.
- ViewSets in `views/` directory (one file per resource), not a single `views.py`.
- Business logic in `services.py`, not in views or serializers.
- Database queries in `managers.py` or `querysets.py`, not in views.
- URL routing: app-level `urls.py` with DRF routers, included in root `urls.py`.

## Multi-Tenancy

- Org-scoping enforced at the queryset level via `OrgScopedMixin`.
- Never access unscoped querysets in views. Use `.for_org(org)` manager method.
- Admin users (`is_staff`) can access cross-org data for support tooling.

## API Design

- RESTful URLs: `/api/v1/projects/`, `/api/v1/projects/{id}/`.
- Pagination: cursor-based via `CursorPagination`. Filtering via `django-filter`.
- Versioning: URL-based (`/api/v1/`). Auth: JWT Bearer token.

## File Naming

- Views: `views/` directory, one file per resource (e.g., `views/projects.py`).
- Serializers: `serializers/` directory, mirroring views structure.
- Tests: `tests/` directory per app with `test_models.py`, `test_views.py`, `test_services.py`.

## Testing Requirements

- Use `pytest` with `pytest-django`, not Django's `TestCase`.
- Factories via `factory-boy` in `tests/factories.py` per app.
- API tests use DRF's `APIClient`: `self.client.post("/api/v1/projects/", data)`.
- Always test permissions: authenticated, unauthenticated, wrong org, admin.
- Mock external services (email, webhooks) with `unittest.mock.patch`.
- Minimum coverage: 80% on changed files.

## Error Handling

- Use DRF exception handler for consistent error responses.
- Custom exceptions in `apps/core/exceptions.py`.
- Error response format: `{ "detail": "message", "code": "ERROR_CODE" }`.
- Log errors with `structlog` including request ID for tracing.
- Celery tasks: use `autoretry_for` with exponential backoff for transient failures.
- Always review generated migrations before committing.
- Never edit a migration that has been merged to `develop`.
