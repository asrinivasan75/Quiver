#!/usr/bin/env bash
# check-updates.sh — wired into Claude Code's SessionStart hook.
#
# Compares the local Quiver clone's HEAD to origin/main and, if behind,
# prints a one-line notice that Claude surfaces in the session.
#
# Behavior:
#   - Local-only check on the hot path (no network wait).
#   - Async background `git fetch` on a 4-hour cadence so the local origin/main
#     reference stays fresh without blocking the session.
#
# Environment:
#   QUIVER_DIR   — path to the Quiver clone. If unset, tries common locations.
#   QUIVER_QUIET — set to "1" to suppress all output.

set -e

[[ "${QUIVER_QUIET:-}" == "1" ]] && exit 0

# Resolve the Quiver clone path: env var, then common locations, then symlink-walk.
quiver_dir="${QUIVER_DIR:-}"
if [[ -z "$quiver_dir" || ! -d "$quiver_dir/.git" ]]; then
  for candidate in "$HOME/Projects/Quiver" "$HOME/src/Quiver" "$HOME/code/Quiver"; do
    if [[ -d "$candidate/.git" ]]; then
      quiver_dir="$candidate"
      break
    fi
  done
fi

# Last resort: walk the symlink chain from this script back to the clone root.
if [[ -z "$quiver_dir" || ! -d "$quiver_dir/.git" ]]; then
  script="$0"
  while [[ -L "$script" ]]; do
    link="$(readlink "$script")"
    if [[ "$link" == /* ]]; then
      script="$link"
    else
      script="$(dirname "$script")/$link"
    fi
  done
  script_dir="$(cd "$(dirname "$script")" 2>/dev/null && pwd)"
  if [[ -n "$script_dir" && -d "$script_dir/../../../.git" ]]; then
    quiver_dir="$(cd "$script_dir/../../.." && pwd)"
  fi
fi

[[ -d "$quiver_dir/.git" ]] || exit 0

cd "$quiver_dir"

# Async fetch on a 4-hour cadence so the session isn't blocked by network I/O.
fetch_marker="$quiver_dir/.git/quiver-last-fetch"
should_fetch=1
if [[ -f "$fetch_marker" ]]; then
  age=$(($(date +%s) - $(stat -f %m "$fetch_marker" 2>/dev/null || echo 0)))
  [[ $age -lt 14400 ]] && should_fetch=0
fi
if [[ "$should_fetch" -eq 1 ]]; then
  ( git fetch --quiet origin main >/dev/null 2>&1 && touch "$fetch_marker" ) &
fi

# Local check against the cached origin/main reference.
local_sha=$(git rev-parse HEAD 2>/dev/null || true)
remote_sha=$(git rev-parse origin/main 2>/dev/null || true)
[[ -z "$local_sha" || -z "$remote_sha" || "$local_sha" == "$remote_sha" ]] && exit 0

behind=$(git rev-list --count "${local_sha}..${remote_sha}" 2>/dev/null || echo 0)
[[ "$behind" -eq 0 ]] && exit 0

s=""
[[ "$behind" -gt 1 ]] && s="s"
echo "🏹 Quiver: ${behind} new update${s} available on origin/main. Run /quiver-upgrade to apply."
