# Quiver

A curated collection of [Claude skills](https://docs.claude.com/en/docs/claude-code/skills) — modular capability units that Claude Code (and other Claude harnesses) loads on demand when their trigger conditions match what you're working on.

Each skill lives in its own folder under `skills/` with a `SKILL.md` that has YAML frontmatter (`name`, `description`) plus any supporting templates and scripts. The format follows Anthropic's standard skill convention.

## Installing a skill

Claude Code looks for skills in two places:

| Scope | Path | Available in |
|-------|------|--------------|
| User  | `~/.claude/skills/<skill-name>/`           | every project |
| Project | `<your-project>/.claude/skills/<skill-name>/` | that project only |

A skill is "installed" simply by placing its folder at one of those paths. The folder must contain a `SKILL.md` at its root; Claude reads the frontmatter to decide when to surface the skill.

### Option 1 — clone Quiver once, symlink the skills you want (recommended)

This keeps a single working copy of the repo and lets you `git pull` to get updates. Symlinks mean the live skill files are always whatever Quiver has on disk.

```bash
# Clone the collection somewhere stable
git clone https://github.com/asrinivasan75/Quiver.git ~/src/Quiver

# Make sure your skills directory exists
mkdir -p ~/.claude/skills

# Symlink a specific skill into your user-level skills directory
ln -s ~/src/Quiver/skills/parallel-blueprint ~/.claude/skills/parallel-blueprint
```

To install into a single project instead of globally:

```bash
mkdir -p /path/to/your/project/.claude/skills
ln -s ~/src/Quiver/skills/parallel-blueprint /path/to/your/project/.claude/skills/parallel-blueprint
```

### Option 2 — copy a single skill (no symlink)

If you'd rather pin a snapshot and avoid pulling updates accidentally:

```bash
git clone https://github.com/asrinivasan75/Quiver.git /tmp/Quiver
cp -R /tmp/Quiver/skills/parallel-blueprint ~/.claude/skills/
rm -rf /tmp/Quiver
```

### Verifying it loaded

Open a Claude Code session and run `/skills` (or whatever your harness uses to list available skills). The skill should appear by name. Or simply describe a task that matches its trigger description — Claude will surface it automatically.

## Skills shipped

| Skill | What it does |
|-------|--------------|
| [`parallel-blueprint`](skills/parallel-blueprint/) | Decomposes an idea or build prompt into a parallel-execution plan with frozen interface contracts, then produces a comprehensive PDF blueprint and a folder of per-terminal prompts (one per workstream + an integrator) ready to paste into separate Claude Code instances. |
| [`test-craft`](skills/test-craft/) | Authors comprehensive, behavior-focused tests via a 3-phase generate → critique → refine loop. Phase 2 spawns an adversarial subagent that reviews the suite for missing cases, implementation-detail testing, hidden-failure mocks, and determinism issues; phase 3 applies the critique. |
| [`quiver-upgrade`](skills/quiver-upgrade/) | Updates the local Quiver clone (`git fetch` + ff-only `git pull`) and reports which skills will pick up changes via symlink vs. need a manual re-copy. Pairs with a SessionStart hook that quietly checks for updates and prints a one-line notice in the session when new commits land on `origin/main`. |

### Stay current automatically

Wire `skills/quiver-upgrade/scripts/check-updates.sh` into your Claude Code SessionStart hook and you'll get a one-line `🏹 Quiver: N updates available. Run /quiver-upgrade to apply.` whenever there are new commits on `origin/main`. The check is local-only on the hot path; a background `git fetch` runs on a 4-hour cadence so the session is never blocked by network I/O.

Add to `~/.claude/settings.json`:

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
