---
name: quiver-upgrade
description: Update the local Quiver clone (the source-of-truth for all Quiver skills) to the latest version. Detects the clone path, fetches origin/main, shows the changelog of new commits, and pulls if the user confirms. Skills installed via symlink pick up the new version immediately. Use when asked to "upgrade quiver", "update quiver", "pull quiver", "get the latest quiver skills", "are there new quiver updates", or whenever the SessionStart hook prints a "Quiver: N updates available" notice.
allowed-tools:
  - Bash
  - Read
---

# /quiver-upgrade

Pulls the latest Quiver from `origin/main` and shows what changed. Skills installed via the recommended symlink approach pick up the new version with no further action; copy-installed skills need to be re-copied (the script will tell you which).

## Procedure

### Step 1 — Find the Quiver clone

The clone path is, in order of preference:

1. The `QUIVER_DIR` environment variable, if set.
2. `$HOME/Projects/Quiver` (default location).
3. `$HOME/src/Quiver` (alternative documented in the README).
4. The result of `find $HOME -maxdepth 4 -type d -name Quiver -path '*/.git/..' 2>/dev/null | head -1`.

Run this resolution in bash, store the result in `$QUIVER_DIR`, and verify the directory contains a `.git` folder. If you can't find it, ask the user where their Quiver clone lives.

```bash
QUIVER_DIR="${QUIVER_DIR:-}"
for candidate in "$QUIVER_DIR" "$HOME/Projects/Quiver" "$HOME/src/Quiver"; do
  if [[ -n "$candidate" && -d "$candidate/.git" ]]; then
    QUIVER_DIR="$candidate"
    break
  fi
done

if [[ -z "$QUIVER_DIR" || ! -d "$QUIVER_DIR/.git" ]]; then
  # Fall back to a search
  QUIVER_DIR=$(find "$HOME" -maxdepth 4 -type d -name Quiver 2>/dev/null | head -1)
fi
```

### Step 2 — Fetch and diff

```bash
cd "$QUIVER_DIR"
git fetch --quiet origin main
local_sha=$(git rev-parse HEAD)
remote_sha=$(git rev-parse origin/main)
```

If `local_sha == remote_sha`, tell the user "Quiver is already up to date." and exit.

Otherwise, list the incoming commits:

```bash
git --no-pager log --pretty=format:"  %h %s (%ar)" "${local_sha}..${remote_sha}"
```

Also list any files that will change (especially in `skills/`):

```bash
git --no-pager diff --name-status "${local_sha}..${remote_sha}"
```

### Step 3 — Confirm and pull

Show the user the list of incoming commits and changed files. Ask whether to apply (a single yes/no question). If yes:

```bash
git pull --ff-only origin main
```

If `--ff-only` fails (local commits ahead), surface the conflict and stop — do not force or rebase without explicit instruction.

### Step 4 — Verify symlinks still resolve

For each subdirectory of `$QUIVER_DIR/skills/`, check whether `~/.claude/skills/<name>` points to it. Report which skills are linked (will pick up changes automatically) and which are copied (the user must re-copy):

```bash
for skill_dir in "$QUIVER_DIR"/skills/*/; do
  name=$(basename "$skill_dir")
  target="$HOME/.claude/skills/$name"
  if [[ -L "$target" ]]; then
    actual=$(readlink "$target")
    if [[ "$actual" == "$skill_dir"* || "$skill_dir" == "$actual"* ]]; then
      echo "  ✓ $name (symlinked, picked up)"
    else
      echo "  ! $name (symlinked, but to a different path: $actual)"
    fi
  elif [[ -d "$target" ]]; then
    echo "  ⚠ $name (copy-installed — re-copy to pick up changes)"
  else
    echo "  · $name (not installed)"
  fi
done
```

### Step 5 — Report

Summarize for the user:
- Old SHA → new SHA
- N commits applied
- Skills that picked up changes vs. those that need a manual re-copy
- Any new skills that aren't installed yet (offer to symlink them)

If new skills appeared in `skills/` that aren't in `~/.claude/skills/`, ask whether to install them with a symlink.

## How notifications happen

A small script at `skills/quiver-upgrade/scripts/check-updates.sh` runs as a Claude Code SessionStart hook. It:
1. Compares `git rev-parse HEAD` to `git rev-parse origin/main` locally (no network).
2. In the background, asynchronously runs `git fetch` if the last fetch was more than 4 hours ago.
3. If local is behind the remote, prints `🏹 Quiver: N updates available. Run /quiver-upgrade to apply.`

The notice goes into the SessionStart context where Claude can see it and surface it to the user. The hook is wired in `~/.claude/settings.json` under `hooks.SessionStart`.

## Hard rules

1. Never `git pull --rebase` or `git reset --hard` automatically — only fast-forward.
2. Never delete a copy-installed skill folder during upgrade — the user may have local edits.
3. If the user has uncommitted changes in the Quiver clone, surface them and ask before doing anything else (their local work might matter).
