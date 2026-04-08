# Plugins & Skills Ecosystem

Claude Code supports a plugin and skill system that extends the AI's capabilities beyond code generation. Plugins add new tools (image generation, design systems, Firebase integration). Skills add domain knowledge and workflows (security checklists, code review processes, SRE runbooks).

This guide covers what's available, how to set it up, and what's worth using.

---

## How Plugins Work

Plugins are installed from marketplaces (GitHub repos that host plugin packages). They add new tools the AI can invoke during a session -- image generation, database operations, documentation lookups, etc.

### Installation

Plugins are configured in `~/.claude/settings.json` (global) or `.claude/settings.json` (per-project):

```json
{
  "enabledPlugins": {
    "firebase@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {
    "claude-plugins-official": {
      "source": {
        "source": "github",
        "repo": "anthropics/claude-plugins-official"
      }
    }
  }
}
```

The `enabledPlugins` map uses the format `plugin-name@marketplace-name`. The `extraKnownMarketplaces` section tells Claude Code where to find the marketplace.

### Plugin Categories

| Category | Plugins | What They Do |
|----------|---------|--------------|
| **Code Quality** | `code-review`, `superpowers` | Automated code review, TDD workflows, systematic debugging, plan-driven development |
| **Frontend** | `frontend-design`, `ui-ux-pro-max` | Design-quality UI generation, 50+ styles, color palettes, font pairings |
| **Infrastructure** | `firebase` | Firebase project management, Firestore rules, Cloud Functions |
| **Documentation** | `context7` | Live documentation lookup for any library/framework |
| **Creative** | `gemini-image` | AI image generation via Google Gemini (logos, mockups, assets) |
| **Workflow** | `ralph-loop` | Recurring task execution on intervals |

---

## Recommended Plugins

### Superpowers (claude-plugins-official)

The most impactful plugin for development workflow. Adds structured skills for:

- **Brainstorming** -- Forces exploration of requirements before implementation. Prevents the "AI immediately starts coding" problem.
- **Test-Driven Development** -- Enforces red-green-refactor cycle. Write failing tests first, then implementation.
- **Systematic Debugging** -- Structured root cause analysis before proposing fixes. Prevents shotgun debugging.
- **Writing Plans** -- Creates implementation plans from specs before touching code.
- **Executing Plans** -- Follows written plans with review checkpoints.
- **Verification Before Completion** -- Requires running actual verification commands before claiming work is done. Evidence before assertions.
- **Code Review** -- Structured review process for completed work.
- **Git Worktrees** -- Isolated feature development with smart directory selection.

**Why it matters:** Without Superpowers, agents jump straight to code. With it, they plan, verify, and follow structured workflows. This single plugin eliminates the most common failure mode in AI-assisted development.

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  }
}
```

### Context7 (claude-plugins-official)

Live documentation lookup for any library, framework, or SDK. Instead of relying on training data (which may be outdated), Context7 fetches current docs.

**When it helps most:**
- Working with recently updated libraries (Next.js 15/16, React 19, etc.)
- Using unfamiliar APIs for the first time
- Debugging library-specific issues where the API may have changed

```json
{
  "enabledPlugins": {
    "context7@claude-plugins-official": true
  }
}
```

### Code Review (claude-plugins-official)

Automated code review for pull requests. Can review PRs against your project's standards, check for security issues, and verify test coverage.

```json
{
  "enabledPlugins": {
    "code-review@claude-plugins-official": true
  }
}
```

### Firebase (claude-plugins-official)

For Firebase projects: manage projects, apps, security rules, SDK config, and environment variables directly from Claude Code.

```json
{
  "enabledPlugins": {
    "firebase@claude-plugins-official": true
  }
}
```

---

## Design and Creative Plugins

### UI/UX Pro Max

A design intelligence plugin that elevates AI-generated frontend from "generic Bootstrap look" to production-grade design. Includes:

- **50+ design styles** -- From minimalist to brutalist, glassmorphism to neomorphism
- **161 color palettes** -- Curated, ready-to-use color systems
- **57 font pairings** -- Tested heading + body combinations
- **161 product types** -- Design patterns for specific product categories (dashboards, e-commerce, SaaS, etc.)
- **99 UX guidelines** -- Accessibility, interaction patterns, responsive behavior
- **25 chart types** -- Data visualization components across multiple frameworks
- **10 framework stacks** -- React, Next.js, Vue, Svelte, SwiftUI, React Native, Flutter, Tailwind, shadcn, and more

**Why it matters:** AI-generated UIs tend to look the same -- safe, generic, forgettable. This plugin gives the AI a design vocabulary. Instead of "make a dashboard," you can say "make a dashboard with the Vercel aesthetic, Inter font pairing, and a cool-slate palette" and get something distinctive.

**Installation:**

```json
{
  "enabledPlugins": {
    "ui-ux-pro-max@ui-ux-pro-max-skill": true
  },
  "extraKnownMarketplaces": {
    "ui-ux-pro-max-skill": {
      "source": {
        "source": "github",
        "repo": "nextlevelbuilder/ui-ux-pro-max-skill"
      }
    }
  }
}
```

**Usage tips:**
- Specify a design style and palette upfront: "Build this with a minimal, monochrome aesthetic"
- Reference specific product types: "Design this like a developer tools dashboard"
- Let it suggest font pairings rather than specifying fonts manually

### Gemini Image Generation

AI image generation powered by Google Gemini. Creates images, logos, icons, mockups, and visual assets directly in your development workflow.

**Use cases:**
- Generating placeholder images that actually match your design aesthetic
- Creating logo concepts and icon sets during prototyping
- Producing mockup images for documentation or presentations
- Generating visual assets for landing pages and marketing sites

**Installation:**

The Gemini Image plugin connects via MCP (Model Context Protocol). Add it to your MCP server configuration:

```json
{
  "mcpServers": {
    "gemini-image": {
      "command": "npx",
      "args": ["-y", "@anthropic/gemini-image-mcp"],
      "env": {
        "GEMINI_API_KEY": "your-gemini-api-key"
      }
    }
  }
}
```

**Usage tips:**
- Be specific about style: "flat vector illustration" vs "photorealistic" vs "hand-drawn sketch"
- Include dimensions and format requirements in your prompt
- Use it alongside UI/UX Pro Max for cohesive visual design

---

## Skills vs. Plugins

These are different systems that complement each other:

| | Skills (`.claude/skills/`) | Plugins (`enabledPlugins`) |
|---|---|---|
| **What** | Markdown files with domain knowledge | Packages that add new tools |
| **Scope** | Per-project (committed to repo) | Global or per-project (settings.json) |
| **Loaded** | On-demand when relevant | Always available in session |
| **Examples** | Security checklist, code style guide, SRE runbook | Image generation, live docs, code review |
| **Who creates** | Your team | Plugin authors / community |

**Use skills for:** Project-specific knowledge that the AI should follow. Security requirements, architecture patterns, compliance rules, team conventions.

**Use plugins for:** Capabilities the AI doesn't have natively. Image generation, live documentation, structured workflows, external integrations.

---

## Project-Level vs. Global Configuration

### Global (`~/.claude/settings.json`)

Plugins you want in every project. Good candidates:
- `superpowers` -- structured workflows apply everywhere
- `context7` -- documentation lookup is always useful
- `code-review` -- code review applies to all repos

### Project-Level (`.claude/settings.json` in repo)

Plugins specific to this project:
- `firebase` -- only for Firebase projects
- `ui-ux-pro-max` -- only for projects with UI work

### Permission Gotchas

Some plugins need permissions you might not have enabled. If a plugin silently fails, check:

1. `permissions.allow` includes the tool names the plugin uses
2. `WebFetch` permissions include any domains the plugin accesses
3. `Bash` permissions include any commands the plugin runs

---

## Setting Up for Your Team

### Minimal Plugin Stack (Every Project)

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "code-review@claude-plugins-official": true
  }
}
```

### Frontend Projects (Add These)

```json
{
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": true,
    "ui-ux-pro-max@ui-ux-pro-max-skill": true
  }
}
```

### Firebase Projects (Add These)

```json
{
  "enabledPlugins": {
    "firebase@claude-plugins-official": true
  }
}
```

---

## MCP Servers: Beyond Plugins

Claude Code also supports MCP (Model Context Protocol) servers -- external services that provide tools via a standardized protocol. These go beyond plugins:

| MCP Server | What It Does |
|-----------|--------------|
| **Gemini Image** | AI image generation |
| **Chrome Automation** | Browser control, testing, scraping |
| **Slack** | Read/send messages, search channels |
| **Linear** | Issue tracking, project management |
| **Notion** | Read/write Notion pages and databases |
| **Gmail / Google Calendar** | Email and calendar integration |
| **Atlassian (Jira/Confluence)** | Issue tracking, wiki |

MCP servers are configured in your Claude Code settings or `claude_desktop_config.json`. They're most useful for:
- **Automated workflows**: Create a Jira ticket, implement the feature, create a PR, and link them together
- **Context gathering**: Read Slack discussions or Notion specs before starting work
- **Browser testing**: Automate Chrome for E2E testing or visual verification

### When to Use MCP vs. Plugins

- **Plugins** are best for capabilities you want the AI to have in every session (design, docs, review)
- **MCP servers** are best for integrations with external services (Slack, Jira, browsers)

---

## Discovering New Plugins

The plugin ecosystem is growing. To find what's available:

1. **Official marketplace**: `anthropics/claude-plugins-official` on GitHub
2. **Community marketplaces**: Added via `extraKnownMarketplaces` in settings
3. **MCP server directory**: Search for `mcp-server-*` packages on npm

When evaluating a plugin, check:
- Is it actively maintained?
- Does it require API keys or credentials?
- What permissions does it need?
- Does it work with your project's security requirements?
