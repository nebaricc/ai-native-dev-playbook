# Using this playbook as a central template

This repo is meant to be **copied from**, not installed as an npm package. You keep full control of files in each project. These are the practical ways to **bootstrap** a new repo and **refresh** templates over time.

---

## What gets synced

The authoritative copies live under `templates/` in this repository:

| Source | Destination in your project |
|--------|------------------------------|
| `templates/CLAUDE.md` | `./CLAUDE.md` |
| `templates/.cursorrules` | `./.cursorrules` |
| `templates/.claude/` | `./.claude/` |
| `templates/.cursor/rules/` | `./.cursor/rules/` |
| `templates/specs/_TEMPLATE.md` | `./specs/_TEMPLATE.md` |

Optional: `templates/.github/workflows/` → `./.github/workflows/` (use `--with-ci` in the script below).

**Not synced:** `examples/` (illustrations only). Pick an example as a starting point if you want a full reference app, but day-to-day projects use `templates/` plus your own stack details.

---

## Option A: One-command sync (recommended)

From the **root of your project** (not inside the playbook clone):

```bash
curl -fsSL https://raw.githubusercontent.com/nebaricc/ai-native-dev-playbook/main/scripts/sync-from-playbook.sh | bash
```

Or clone the playbook once and run the script from disk (no network on repeat runs):

```bash
git clone https://github.com/nebaricc/ai-native-dev-playbook.git ~/ai-native-dev-playbook
~/ai-native-dev-playbook/scripts/sync-from-playbook.sh
```

Environment variables:

| Variable | Default | Meaning |
|----------|---------|---------|
| `PLAYBOOK_URL` | `https://github.com/nebaricc/ai-native-dev-playbook.git` | Fork URL if you maintain your own |
| `PLAYBOOK_REF` | `main` | Branch or tag to sync from |

Flags:

| Flag | Meaning |
|------|---------|
| `--dry-run` | Show what would be copied |
| `--skip-root` | Do **not** overwrite `CLAUDE.md` or `.cursorrules` (only refresh `.claude/`, `.cursor/rules/`, `specs/`) |
| `--with-ci` | Also copy workflow templates into `.github/workflows/` |

Then customize `CLAUDE.md` and `.cursorrules` for your stack and commit.

---

## Option B: Git subtree (playbook history inside your repo)

Use this if you want **one git command** to pull upstream playbook changes into a subdirectory, without submodule checkout friction.

**One-time add** (from your project root):

```bash
git remote add playbook https://github.com/nebaricc/ai-native-dev-playbook.git
git fetch playbook
git subtree add --prefix _playbook playbook main --squash
```

**Copy templates out** (still manual or scripted):

```bash
cp _playbook/templates/CLAUDE.md ./CLAUDE.md
# … or rsync _playbook/templates/.claude ./.claude
```

**Update later** when the playbook moves forward:

```bash
git fetch playbook
git subtree pull --prefix _playbook playbook main --squash
```

Then re-copy or diff `templates/` into your real paths. Subtree keeps the playbook revision **auditable** in your history; copying is how you avoid editing files only under `_playbook/`.

---

## Option C: Manual copy (simplest mental model)

```bash
git clone --depth 1 https://github.com/nebaricc/ai-native-dev-playbook.git /tmp/playbook
cp /tmp/playbook/templates/CLAUDE.md ./CLAUDE.md
cp /tmp/playbook/templates/.cursorrules ./.cursorrules
rsync -a /tmp/playbook/templates/.claude/ ./.claude/
rsync -a /tmp/playbook/templates/.cursor/rules/ ./.cursor/rules/
mkdir -p specs && cp /tmp/playbook/templates/specs/_TEMPLATE.md ./specs/_TEMPLATE.md
```

Same as the README quick start; use it when you do not want a script.

---

## Updating over time without losing your project

1. **Project-specific content** belongs in `CLAUDE.md` and `.cursorrules` (stack, commands, branches). Treat upstream as a **starting point**, then edit.
2. **Refresh skills and rules** often: run the sync script with `--skip-root` so only `.claude/`, `.cursor/rules/`, and `specs/_TEMPLATE.md` update. Merge any local edits you made inside those trees (use `git diff` before committing).
3. **Track upstream in a fork** if you customize the playbook: fork on GitHub, set `PLAYBOOK_URL` to your fork, and merge `main` from this repo when you want new baseline templates.

---

## Submodule?

[Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) pin another repo at a path. They work, but every clone needs `git submodule update --init` and detached HEADs confuse many teams. Subtree or “copy + commit” usually causes fewer support issues. Use submodules only if you already standardize on them.

---

## See also

- [README.md — How to Apply This to Your Repo](../README.md#how-to-apply-this-to-your-repo)
- [Multi-tool setup](multi-tool-setup.md) — keeping `CLAUDE.md` and `.cursorrules` aligned
- [Phase 1: Context](phase-1-context.md) — full Phase 1 guide
