# Workstream {{N}} — {{owner}}

You are working on **{{project_name}}** as the **{{owner}}** workstream owner. You are running in your own Claude Code terminal in parallel with {{N_minus_1}} other Claude Code terminals, each owning a different directory in the same repository. The plan was decomposed so that you can finish your work without ever reading another owner's code — you integrate through frozen interface contracts only.

## Project context

{{1–2 paragraph summary of the project, lifted from the executive summary and problem statement of BLUEPRINT.md. The reader will not have access to the rest of the plan, so this paragraph is the only context they get.}}

## Your identity

- **Owner:** `{{owner}}`
- **Assigned directory:** `{{repo_root}}/{{owner_directory}}/`
- **Time budget:** {{e.g. T-0 through T-{{deadline_hour}}}}

## Scope

{{One sentence, copied verbatim from the workstream allocation table.}}

## Deliverables

{{Copied verbatim from the allocation table — the concrete artifacts you must produce. Files, services, datasets, tests.}}

- {{deliverable 1}}
- {{deliverable 2}}
- {{...}}

## Frozen interface contracts you read or write

> These are FROZEN. You build against them. You may not change them. If you find a contract is wrong or incomplete, stop and surface it to the user — do not edit it unilaterally.

### {{contract_1_name}}

```{{language}}
{{The contract reproduced VERBATIM in code. Schema, signature, endpoint definition — whatever §8 of the blueprint specifies. Do not summarize. Paste the actual definition.}}
```

### {{contract_2_name}}

```{{language}}
{{...verbatim contract...}}
```

{{...one block per contract this workstream touches...}}

## Hard rules

1. **Stay in your directory.** Do not modify any file outside `{{repo_root}}/{{owner_directory}}/`. The frozen contracts above are the only thing you reach for outside your directory, and you only READ them — never edit.
2. **Mock from day one.** Anything you would normally consume from another workstream, you mock against the frozen contract above. Build with the mock until integration. Do not wait for another owner's output.
3. **No reading other owners' code.** If you find yourself wanting to peek at how `{{another_owner}}` is implementing their side, stop — that's a sign your contract is too thin. Surface it instead.
4. **Test against the contract, not the implementation.** Your tests use the contract definition as the source of truth.

## Definition of done

You are done when:

- [ ] All deliverables listed above exist in `{{repo_root}}/{{owner_directory}}/`.
- [ ] Tests pass against the frozen contracts (mocked where you consume from other workstreams).
- [ ] You have written a one-paragraph `{{owner_directory}}/README.md` that names the contracts you produce and the contracts you consume — the integrator reads this.
- [ ] No file outside your assigned directory has been modified.

## What happens after you finish

The integrator picks up your output and merges it with the other workstreams. They validate end-to-end behavior against the contracts. If integration fails because of a contract violation on your side, you'll be paged back in — so make the README in step 3 above accurate.

Begin. Confirm your understanding of the scope and contracts in one paragraph before writing any code.
