---
title: "{{project_name}} — Build Plan"
author: "{{author_or_team}}"
date: "{{date}}"
---

# {{project_name}}

## 1. Executive summary

{{~150 words: the pitch, the target outcome, the bet you're making, and the one-sentence reason this plan can be parallelized at all (i.e. why the contract surface is small enough). End with the time budget and the headcount.}}

## 2. Problem statement

{{What are we solving? Who has the pain? Why now? Be specific about the gap between what exists and what we want to ship. Avoid generic motivation — name the user, name the moment.}}

## 3. Approach

### Roles

{{For each owner: one line — who they are, what they own. Mirror the workstream allocation table in §7 but in prose.}}

### One-cycle walkthrough

{{Hour 0 → demo, in plain prose. What happens first (almost always: contract freeze)? What hands off to what? When does the integrator step in? End at the demo moment.}}

## 4. Architecture

```
{{ASCII diagram OR a fenced ```mermaid block showing components and data flow.
   Put each owner's directory in its own box. Show every contract as a labeled
   edge between boxes.}}
```

### Key interfaces (in code)

```{{language}}
{{The most important interfaces, in real syntax. Not pseudocode. These are
  previews of §8; pick the 2–3 most load-bearing ones to surface here.}}
```

## 5. Tech stack

| Component | Choice | Why |
|-----------|--------|-----|
| {{e.g. Frontend}} | {{e.g. Next.js 14, Tailwind}} | {{one-line rationale}} |
| {{e.g. Backend}} | {{e.g. FastAPI + Postgres}} | {{one-line rationale}} |
| {{...}} | {{...}} | {{...}} |

## 6. Target repository structure

```
{{repo_root}}/
  {{owner_1_dir}}/        # owned by {{owner_1}}
  {{owner_2_dir}}/        # owned by {{owner_2}}
  {{...}}
  contracts/              # frozen contracts (read-only after freeze)
  integration/            # owned by integrator (if present)
  README.md
```

## 7. Workstream allocation

| Owner | Scope | Deliverables | Depends on (contracts only) |
|-------|-------|--------------|------------------------------|
| {{owner_1}} | {{one-sentence scope}} | {{concrete artifacts: files, services, datasets}} | {{frozen contracts cited by name from §8 — never another owner's code}} |
| {{owner_2}} | {{...}} | {{...}} | {{...}} |
| {{...}} | {{...}} | {{...}} | {{...}} |
| {{integrator}} | {{merge + e2e validation}} | {{integration glue, end-to-end test, demo runner}} | {{all contracts}} |

> **Contract violation check:** if any cell in the rightmost column cites another owner's code rather than a frozen contract, stop and redraw the plan. The contract surface is too thin.

## 8. Frozen interface contracts

> The contracts in this section are **frozen** at the start of the build. Owners read them, mock against them, and integrate through them — but do not modify them mid-build without a contracts huddle.

### 8.1 Data shapes

```{{language}}
{{e.g. TypeScript types, JSON Schema, protobuf, SQL DDL — the actual shape}}
```

### 8.2 Function & protocol signatures

```{{language}}
{{e.g. function signatures, gRPC service definitions, trait/interface declarations}}
```

### 8.3 API endpoints

| Method | Path | Request | Response | Errors |
|--------|------|---------|----------|--------|
| {{GET}} | {{/foo/:id}} | {{body shape or "—"}} | {{response body shape}} | {{error shapes}} |
| {{...}} | {{...}} | {{...}} | {{...}} | {{...}} |

### 8.4 Events

| Event | Producer | Consumers | Payload |
|-------|----------|-----------|---------|
| {{event.name}} | {{owner}} | {{owners}} | {{payload shape}} |

### 8.5 On-disk artifacts

{{If workstreams hand off through the filesystem: path conventions, file formats, naming rules. Omit if not used.}}

## 9. Timeline

{{For hackathons: hour-by-hour. For week-long builds: day-by-day. Each row names the hour/day, the milestone, the owner who drives it, and what's verifiable at the end of that block.}}

| {{Hour / Day}} | Milestone | Driver | Verifiable outcome |
|----------------|-----------|--------|---------------------|
| 0–1 | Contract freeze | all owners | §8 is locked; mocks committed |
| {{...}} | {{...}} | {{...}} | {{...}} |
| {{T-2}} | Integration window opens | integrator | end-to-end smoke passes |
| {{T-1}} | Demo dress rehearsal | all | full demo runs without manual intervention |
| {{T}} | Demo / ship | — | acceptance plan §12 passes |

## 10. Success criteria

{{Observable, falsifiable. "The user can do X" beats "the system supports X". Include performance/quality bars where they matter (latency, error rate, accuracy).}}

- {{criterion 1}}
- {{criterion 2}}
- {{criterion 3}}

## 11. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| {{e.g. contract drift mid-build}} | {{med}} | {{high}} | {{contracts huddle every N hours; integrator owns the freeze}} | {{integrator}} |
| {{e.g. third-party API down}} | {{...}} | {{...}} | {{cached fixtures + offline mode}} | {{owner}} |
| {{...}} | {{...}} | {{...}} | {{...}} | {{...}} |

## 12. Demo / acceptance plan

{{What you'll show, in what order, on what hardware. Include a fallback for each step: if X breaks, fall back to Y. The fallback is what separates a plan from a wish.}}

1. **{{Step 1 of demo}}** — {{what the audience sees; fallback if it breaks}}
2. **{{Step 2}}** — {{...}}
3. **{{...}}** — {{...}}

### Acceptance checklist

- [ ] {{thing 1 works end-to-end on the demo machine}}
- [ ] {{thing 2 works without manual intervention}}
- [ ] {{thing 3 has a documented fallback}}
