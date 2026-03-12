# Firebase App Example

This example shows a filled-in AI-native configuration for a Firebase-backed
application with multiple frontends and Cloud Functions.

## Stack

- **apps/web** -- Next.js 14 (customer-facing web app, hosted on Firebase Hosting)
- **apps/functions** -- Cloud Functions v2 (TypeScript, event-driven backend)
- **apps/bot** -- Discord bot (Node.js, uses shared Firestore access)
- **databases/** -- Firestore security rules and indexes

## Key Choices

- **npm workspaces** for dependency management
- **Firestore** as primary database
- **Firebase Auth** with custom claims for role-based access
- **Cloud Functions v2** (2nd gen, based on Cloud Run)
- **Vitest** for unit tests, Firebase Emulator Suite for integration tests
- Branch model: feature branches from `dev`, PRs to `dev`
- Jira ticket prefix: `SIG`

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code project instructions |
| `.cursorrules` | Cursor IDE rules |
| `.claude/settings.json` | Allowed/denied commands for Claude |
| `.cursor/rules/components.mdc` | React component + design system rules |
| `.cursor/rules/firestore-rules.mdc` | Firestore security rules conventions |
