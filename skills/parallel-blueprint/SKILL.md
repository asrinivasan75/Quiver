---
name: parallel-blueprint
description: Decompose an idea or build prompt into a parallel-execution plan and emit two artifacts — (1) a comprehensive PDF blueprint and (2) a folder of ready-to-paste prompts (one per workstream plus an integrator) for separate Claude Code terminals. The methodology centers on frozen interface contracts (data schemas, function signatures, event shapes, API endpoints) negotiated up front so each owner works asynchronously against mocked contracts in a directory they alone own. Use when the user says "plan this for parallel execution", "split into agents", "decompose into workstreams", "hackathon plan", "build plan with multiple Claude Code terminals", "parallelize this across N Claudes", or otherwise asks to fan a build out across multiple Claude sessions. Do NOT use for single-threaded coding tasks, simple scripts, single-file edits, debugging sessions, code review, refactors, or anything that fits comfortably in one terminal.
---

# Parallel Blueprint

This skill turns a build prompt into a plan that multiple Claude Code terminals can execute in parallel without stepping on each other. The output is two things, always:

1. **`BLUEPRINT.pdf`** — a comprehensive build plan in a fixed 12-section format.
2. **`prompts/`** — a folder of per-terminal prompts. One file per workstream owner, plus an integrator prompt for the merge step. The user pastes each into its own Claude Code instance.

The plan succeeds or fails on one thing: whether the **frozen interface contracts** are good enough that each owner can finish their workstream against mocks, without ever reading another owner's code.

## When this skill is the right tool

Use it when:
- The user has a build idea (hackathon, prototype, feature shipped under a deadline) and wants to fan it out across multiple Claude Code terminals.
- The user uses any of the trigger phrases in the frontmatter.
- The user mentions "agents", "workstreams", "owners", "terminals", or "in parallel" in the context of planning a build.

Do NOT use it for:
- Tasks small enough for one terminal (most coding tasks).
- Pure analysis, code review, or debugging.
- Refactors that touch many files but don't decompose into independent workstreams.
- Anything where the user hasn't asked for parallelism.

If unsure, ask the user one question: "How many parallel Claude Code terminals do you want to run?" If the answer is 1, this skill is the wrong tool.

## The methodology (this is what you encode in every plan)

### 1. Frozen interface contracts — the central pattern

The first phase of any plan is **freezing the contracts that connect workstreams**:

- Data schemas (e.g. JSON shapes, database tables, protobuf messages).
- Function signatures and protocol definitions.
- Event shapes (what gets emitted, by whom, when).
- API endpoints (path, method, request body, response body, error shapes).
- File paths and on-disk artifact formats when workstreams hand things off through the filesystem.

Once frozen, owners integrate ONLY through these contracts. They never read each other's internals. They never depend on another owner's implementation details. **This is what makes the workstreams genuinely parallel and asynchronous.**

If during decomposition you find that a workstream needs another workstream's code to make progress, that's a **contract violation** — the contract surface is too thin. Widen the contract or redraw the workstream boundary, and re-validate before continuing.

### 2. One directory per owner

Each workstream owns exactly one directory in the target repository and is responsible for everything inside it. Owners do not edit files outside their directory, full stop. Cross-cutting concerns (shared types, integration glue) either:
- Live in a directory the integrator owns, or
- Are encoded as frozen contracts that everyone reads but only one owner writes.

### 3. Mock from day one

Every owner mocks against the frozen contracts on the first commit. No owner waits on another owner's progress. If owner B's workstream consumes data produced by owner A, owner B builds against a hand-written fixture that matches the frozen schema — and continues to use that fixture until integration. This is non-negotiable; without it, the parallelism collapses into a chain.

### 4. The integrator role

A final owner whose job is reconciliation: read each workstream's outputs, run the merge, validate end-to-end behavior, write the integration glue.

**Default to including an integrator.** Omit the integrator only when the workstream outputs **coexist** rather than **compose** — e.g. four independent skills shipped as four independent files, no glue needed. If the deliverable is a working system that has to run end-to-end, an integrator is required.

### 5. The workstream allocation table

The heart of the document. Columns are exactly:

| owner | scope | deliverables | depends-on-contracts |
|-------|-------|--------------|----------------------|

- `owner` — short identifier (e.g. `data`, `ui`, `infra`, `model`).
- `scope` — one sentence on what this workstream is responsible for.
- `deliverables` — concrete artifacts produced by this workstream (files, services, datasets).
- `depends-on-contracts` — the frozen contracts this workstream reads or writes. **This column may only cite frozen contracts. Never another owner's code.** If you find yourself writing "depends on the auth module" or "depends on owner X's parser", stop and redraw.

## Procedure

When invoked, execute these steps in order. Do not skip the validation step.

### Step 1 — Clarify the brief

Ask the user (in one batched message — don't ping-pong) for whatever you need to fill out the plan:

- What is being built? (One paragraph elevator pitch.)
- What's the time budget? (Hours, days, sprint.)
- How many parallel workstreams / Claude Code terminals? (If unspecified, propose a number based on the natural decomposition and confirm.)
- What's the target tech stack, if known?
- Are there constraints on the deliverable (must demo X, must run on Y, must use Z)?
- Where should the plan be written? (Default: `./plan/` in the current working directory.)

If the user already provided enough, skip questions and confirm your read of the brief in one paragraph before proceeding.

### Step 2 — Identify the frozen contracts

Before decomposing, list every interface that will connect workstreams. For each, write the actual shape — schema, signature, endpoint definition. Be concrete. "An API for users" is not a contract. `GET /users/:id → {id: string, email: string, created_at: ISO8601}` is.

Group contracts by type: data shapes, function signatures, events, endpoints, on-disk artifacts. Keep the list small but rigid — every contract you write here becomes load-bearing.

### Step 3 — Decompose into workstreams

Using the frozen contracts, propose the workstream allocation. Aim for:
- One directory per owner, named so its purpose is obvious from the path.
- Roughly even effort across owners.
- Every `depends-on-contracts` entry citing only frozen contracts from Step 2.

### Step 4 — Validate the decomposition (do not skip)

Walk through the table and check, for each workstream:
- Can this owner make progress on hour 1 with only the frozen contracts and a mock? If not, the contract is too thin — go back to Step 2.
- Does any workstream need to read another workstream's source? If yes, that's a contract violation — redraw.
- Is the integrator's job clear, or are integration responsibilities scattered? If scattered, consolidate into the integrator.

Iterate Steps 2–4 until the table passes. Do not proceed to Step 5 until it does.

### Step 5 — Compose the blueprint markdown

Read `templates/blueprint-outline.md` and fill in every section. Maintain section order exactly (this is what readers expect):

1. **Executive summary** (~150 words; pitch + outcome + bet).
2. **Problem statement** (what we're solving and why now).
3. **Approach** (the roles and a one-cycle walkthrough — what happens between hour 0 and the demo).
4. **Architecture** (ASCII or mermaid diagram of the system, plus key interfaces in code blocks).
5. **Tech stack table** (component → choice → rationale).
6. **Target repository structure** (`tree`-style listing showing each owner's directory).
7. **Workstream allocation table** (the methodology section above; this is the heart of the doc).
8. **Frozen interface contracts** (separate, prominent section — every contract reproduced verbatim, in code blocks, in the same form a workstream prompt will quote it).
9. **Hour-by-hour or day-by-day timeline** (granularity matches the time budget; hour-by-hour for hackathons, day-by-day for week-long builds).
10. **Success criteria** (what "done" looks like — observable, falsifiable).
11. **Risks & mitigations** (table: risk → likelihood → mitigation → owner).
12. **Demo / acceptance plan** (what you'll show, in what order, on what hardware, with what fallback if something breaks).

Write the result to `plan/BLUEPRINT.md`.

### Step 6 — Generate per-terminal prompts

For each workstream owner, read `templates/workstream-prompt.md` and produce `plan/prompts/workstream-{N}-{owner}.md`, where `N` is 1-indexed and `owner` matches the table.

For the integrator (if present), read `templates/integrator-prompt.md` and produce `plan/prompts/integrator.md`.

Each prompt must contain:
- Project context (1–2 paragraph summary from the executive summary and problem statement).
- Identity: this owner's name and assigned directory.
- Scope, copied verbatim from the allocation table.
- Deliverables, copied verbatim.
- The frozen contracts this owner reads or writes — **reproduced in full, verbatim, in code blocks.** Do not summarize. Do not link. Paste the schema/signature/endpoint definition directly into the prompt. (The owner won't have access to the rest of the plan.)
- Hard rule: "Do not modify any file outside `<assigned directory>`. If you need something from another workstream, the contract is the only place to get it; build a mock if needed."
- Definition of done for this workstream.

The integrator prompt additionally contains:
- The list of workstream output paths (e.g. `services/auth/`, `services/data/`, ...).
- All frozen contracts (the integrator validates everyone respects them).
- An explicit validation checklist: how to run the merge, what end-to-end test must pass, what to do if a contract is violated.

### Step 7 — Render the PDF

Run `scripts/render_pdf.sh plan/BLUEPRINT.md plan/BLUEPRINT.pdf` from the skill directory. The script auto-detects an installed PDF engine. If none is installed it prints clear install instructions; in that case, leave `BLUEPRINT.md` in place and tell the user how to render it themselves rather than abandoning the artifact.

### Step 8 — Report

Tell the user:
- Where the plan lives (`plan/BLUEPRINT.pdf` and `plan/BLUEPRINT.md`).
- The list of prompt files written under `plan/prompts/`.
- A one-line instruction: "Open one Claude Code terminal per prompt file. Paste the contents of the corresponding `workstream-*.md` into each, and the integrator prompt into the last terminal once workstreams are complete."

## Output layout

```
plan/
  BLUEPRINT.md
  BLUEPRINT.pdf
  prompts/
    workstream-1-{owner}.md
    workstream-2-{owner}.md
    ...
    workstream-N-{owner}.md
    integrator.md            # omit only when outputs coexist rather than compose
```

## Templates referenced by this skill

- `templates/blueprint-outline.md` — the 12-section markdown skeleton.
- `templates/workstream-prompt.md` — per-terminal prompt template for a workstream owner.
- `templates/integrator-prompt.md` — prompt template for the integrator.

When filling templates, replace every `{{placeholder}}` with concrete content. Do not leave placeholders in the final output. Do not invent sections that aren't in the template. Do not rearrange the section order.

## PDF rendering

The bundled `scripts/render_pdf.sh` wraps `pandoc` with sensible defaults (1-inch margins, table of contents, syntax highlighting, link colors). It auto-detects an installed PDF engine in this order:

1. `xelatex` (best output; install with `brew install --cask basictex` then `sudo tlmgr install xetex`)
2. `wkhtmltopdf` (lighter; `brew install --cask wkhtmltopdf`)
3. `weasyprint` via pandoc (`pip install weasyprint`)

If pandoc itself is not installed, the script prints install instructions (`brew install pandoc`) and exits non-zero. Do not silently fall back to "just markdown" — surface the issue to the user.

## Reference example

`examples/cubist-hackathon.pdf` — a 24-hour hackathon proposal that demonstrates the target format and tone. Its methodology (Hour 0–1 interface freeze; 5 owners with one directory each; mocked contracts everywhere) is the pattern this skill systematizes. Read it before authoring a blueprint to calibrate the level of detail and the rigor of the contract section.
