# Quiver

A curated collection of [Claude skills](https://docs.claude.com/en/docs/claude-code/skills) — modular capability units that Claude Code (and other Claude harnesses) loads on demand when their trigger conditions match what you're working on.

Each skill lives in its own folder under `skills/` with a `SKILL.md` that has YAML frontmatter (`name`, `description`) plus any supporting templates and scripts. The format follows Anthropic's standard skill convention.

## Installing

Three options, easiest first.

### Option 1 — install as a Claude Code plugin (recommended)

The repo ships its own one-plugin marketplace at `.claude-plugin/marketplace.json`, so you can add it as a marketplace and install the bundled plugin in two commands:

```text
/plugin marketplace add asrinivasan75/Quiver
/plugin install quiver@quiver-plugins
```

That's it. Claude Code installs the plugin under `~/.claude/plugins/`, registers all three skills automatically, and adds an entry to `enabledPlugins` in `~/.claude/settings.json`. The bundled `hooks/hooks.json` wires the SessionStart update-check hook for you. Open a new Claude Code session and the skills are available.

To upgrade to a newer Quiver release, run `/plugin upgrade quiver@quiver-plugins` (or use `/quiver-upgrade` from inside a session — it works for plugin installs too, but the plugin path uses Claude Code's update mechanism).

### Option 2 — clone once, symlink the skills you want (good for development)

This keeps a single working copy of the repo and lets you `git pull` to get updates. Symlinks mean the live skill files are always whatever Quiver has on disk — useful if you're contributing skills or want bleeding-edge changes.

```bash
git clone https://github.com/asrinivasan75/Quiver.git ~/src/Quiver
mkdir -p ~/.claude/skills
ln -s ~/src/Quiver/skills/parallel-blueprint ~/.claude/skills/parallel-blueprint
ln -s ~/src/Quiver/skills/test-craft         ~/.claude/skills/test-craft
ln -s ~/src/Quiver/skills/quiver-upgrade     ~/.claude/skills/quiver-upgrade
```

To install into a single project instead of globally, replace `~/.claude/skills/` with `<your-project>/.claude/skills/`. Claude Code reads both paths.

If you go this route, wire the SessionStart update notice manually by adding to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/skills/quiver-upgrade/scripts/check-updates.sh"
          }
        ]
      }
    ]
  }
}
```

### Option 3 — copy a single skill (pinned snapshot)

If you only want one skill and don't want it to update at all:

```bash
git clone https://github.com/asrinivasan75/Quiver.git /tmp/Quiver
cp -R /tmp/Quiver/skills/parallel-blueprint ~/.claude/skills/
rm -rf /tmp/Quiver
```

### Verifying it loaded

Open a new Claude Code session and run `/context`. The skills should appear in the Skills list. Or just describe a task that matches a skill's trigger description — Claude will surface it automatically.

### Don't double-install

If you switch from Option 2/3 to Option 1, remove the symlinks/copies first to avoid duplicate skill registrations:

```bash
rm ~/.claude/skills/parallel-blueprint ~/.claude/skills/test-craft ~/.claude/skills/quiver-upgrade
# also remove the manual SessionStart hook entry from ~/.claude/settings.json if you added one
```

## Skills shipped

| Skill | What it does |
|-------|--------------|
| [`parallel-blueprint`](skills/parallel-blueprint/) | Decomposes an idea or build prompt into a parallel-execution plan with frozen interface contracts, then produces a comprehensive PDF blueprint and a folder of per-terminal prompts (one per workstream + an integrator) ready to paste into separate Claude Code instances. |
| [`test-craft`](skills/test-craft/) | Authors comprehensive, behavior-focused tests via a 3-phase generate → critique → refine loop. Phase 2 spawns an adversarial subagent that reviews the suite for missing cases, implementation-detail testing, hidden-failure mocks, and determinism issues; phase 3 applies the critique. |
| [`quiver-upgrade`](skills/quiver-upgrade/) | Updates the local Quiver clone (`git fetch` + ff-only `git pull`) and reports which skills will pick up changes via symlink vs. need a manual re-copy. Pairs with a SessionStart hook (auto-wired by the plugin install path, manual under Option 2) that prints `🏹 Quiver: N updates available` in-session when new commits land on `origin/main`. The hot path is local-only; a background `git fetch` runs on a 4-hour cadence so the session is never blocked by network I/O. |

## Contributing a skill

1. Create a new folder under `skills/` named with a short, kebab-case verb-or-noun phrase (e.g. `release-notes`, `contract-freeze`, `synth-fixtures`).
2. Add a `SKILL.md` at its root with YAML frontmatter:

   ```markdown
   ---
   name: your-skill-name
   description: One paragraph that tells Claude exactly when to invoke this skill — include the user-facing trigger phrases and explicit anti-triggers (when NOT to use it). The description is the only thing Claude sees during skill selection, so make it specific.
   ---

   # Your Skill Name

   <instructions for Claude on what to do when invoked>
   ```

3. Put any supporting material the skill needs in subfolders alongside `SKILL.md`. Common conventions:

   ```
   skills/your-skill-name/
     SKILL.md
     templates/      # markdown templates the skill fills in
     scripts/        # helper scripts the skill invokes
     examples/       # reference outputs that demonstrate the target format
   ```

4. Open a PR. Include in the description: a one-sentence summary of the skill, its trigger phrases, and a sample input → output if you have one.

### Skill authoring tips

- **Describe behavior, not personality.** The body of `SKILL.md` is a procedure for Claude to follow, not a character brief.
- **Be opinionated about anti-triggers.** Listing what the skill should NOT match is as important as what it should match — it prevents accidental invocation on unrelated tasks.
- **Prefer templates over generated prose.** Templates with explicit placeholders produce more consistent output than free-form generation.
- **Keep dependencies self-contained.** If your skill needs a tool installed, document the install step in `SKILL.md` and have the skill check for the tool before using it.

## License

[MIT](LICENSE) © Aadithya Srinivasan
