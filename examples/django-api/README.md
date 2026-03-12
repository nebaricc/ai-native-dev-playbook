# Django REST API Example

This example shows a filled-in AI-native configuration for a Python Django REST
API, demonstrating that this approach works beyond JavaScript/TypeScript stacks.

## Stack

- **Django 5.x** with Django REST Framework
- **PostgreSQL 16** as primary database
- **Poetry** for dependency management
- **pytest** for testing (with pytest-django)
- **Celery + Redis** for background tasks
- **Black + Ruff** for formatting and linting

## Key Choices

- Django apps organized under `apps/` directory
- ViewSets + Serializers + Filters pattern from DRF
- Custom user model from day one
- JWT authentication via `djangorestframework-simplejwt`
- Branch model: feature branches from `develop`, PRs to `develop`
- Jira ticket prefix: `API`

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code project instructions |
| `.cursorrules` | Cursor IDE rules |
| `.claude/settings.json` | Allowed/denied commands for Claude |
