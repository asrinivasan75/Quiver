---
name: test-craft
description: Author comprehensive, behavior-focused tests via a 3-phase generate → critique → refine loop. Phase 1 produces a first-cut test suite covering happy paths, edge cases, error paths, and boundary conditions in the project's existing test framework. Phase 2 spawns an adversarial critique subagent that reviews the suite for missing cases, implementation-detail testing, hidden-failure mocks, redundancy, and determinism issues. Phase 3 applies the critique and runs the suite. Use when the user says "write tests", "add tests", "test this code", "comprehensive tests", "generate tests with critique", "test-craft this", "I need tests for X", or otherwise asks for high-quality test coverage on a specific file, module, or feature. Do NOT use for one-off assertions, ad-hoc debugging tests, simple smoke checks, or when the user says "just write a quick test" — those should be done inline without ceremony.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Agent
  - Glob
  - Grep
---

# /test-craft

Three phases. Do them in order. Do not skip phase 2.

## What you produce

A test file (or files) for the target code, validated by an adversarial second pass and refined accordingly. The deliverable is the test suite plus a short note to the user on the critique findings and how they were addressed.

## Inputs you need

Before starting, you need to know:
- **Target** — file, module, function, or feature being tested.
- **Test framework** — usually inferable from the project (pytest, jest, vitest, mocha, rspec, go test, cargo test, JUnit, etc.). If unclear, look for `package.json`, `pyproject.toml`, `Gemfile`, `go.mod`, etc.
- **Existing test conventions** — read 1–2 existing test files in the repo to match style (file location, naming, fixture patterns, helper imports).

If the target is ambiguous ("write tests" with no specifics), ask the user one batched question to pin it down before starting Phase 1.

## Phase 1 — Generate

### 1a. Read the code under test

Read the target file end to end, plus any types/contracts it exports. Do not just skim — you need to understand what behaviors the code promises.

### 1b. Enumerate behaviors (write this list down)

For each public function/method/endpoint, write a list of behaviors to verify. Include:

- **Happy path** — typical inputs produce the expected outputs.
- **Edge cases** — empty inputs, single-element inputs, max-size inputs, unicode/whitespace, leading/trailing edges.
- **Boundary conditions** — off-by-one, inclusive/exclusive ranges, integer overflow if relevant.
- **Error paths** — invalid inputs, missing dependencies, permission denied, network failures, timeouts. For each, what error is raised? What state is left behind?
- **Concurrency** — if the code is concurrent, what happens with simultaneous calls?
- **Side effects** — what gets written to disk, sent over network, logged? Tests should verify these.
- **State transitions** — if the code has state, every transition deserves a test.
- **Documented contracts** — every behavior promised by docstrings/types/comments needs a test.

This list is the SPEC for the test suite. Refer back to it.

### 1c. Match the project's testing idiom

Read 1–2 existing test files in the repo. Match:
- File location (`tests/` vs `__tests__/` vs `*_test.go` next to source)
- Naming (`test_foo.py` vs `foo.test.ts` vs `FooSpec.scala`)
- Setup/teardown patterns (fixtures, beforeEach, etc.)
- Mock/stub conventions (`unittest.mock`, `vi.mock`, `gomock`, etc.)
- Assertion style (`assert x == y` vs `expect(x).toBe(y)` vs `x.should == y`)

Do not invent a new testing style if the project has an established one.

### 1d. Write the tests

Cover every behavior on the list from 1b. Each test:
- Tests one behavior. Multiple assertions about the same call are fine; testing two unrelated behaviors in one test is not.
- Has a name that describes the behavior, not the input ("rejects empty input", not "test_empty").
- Uses Arrange-Act-Assert structure. The arrange block sets up inputs and mocks; the act block calls the code under test once; the assert block checks outputs and side effects.
- Avoids testing implementation details. Test what the function returns, what it writes, what error it throws — not which internal helper it called (unless the helper is the public contract).

### 1e. Run the tests

Run the test suite. Make sure they pass (or fail in a meaningful way if you're doing TDD-style red-first). Fix any issues — broken tests, broken imports, wrong fixtures.

## Phase 2 — Critique (spawn a subagent)

This is the load-bearing phase. Do NOT critique your own work — spawn a subagent. The subagent has not seen your reasoning during generation and will catch things you'd rationalize away.

Use the `Agent` tool with `subagent_type: general-purpose` and the following prompt:

```
You are an adversarial test reviewer. You are reviewing tests written by another
agent. Your job is to find every weakness in the test suite. Do not be
diplomatic — find real problems.

CONTEXT
The code under test is at: <absolute path(s)>
The tests are at: <absolute path(s)>
The framework is: <pytest|jest|vitest|...>

WHAT TO READ
1. Read the source file(s) end to end — understand the contract being tested.
2. Read the test file(s) end to end.
3. Read 1–2 sibling test files in the repo to understand local conventions.

WHAT TO LOOK FOR (be thorough)
- Tests that exercise implementation details rather than observable behavior.
  Specifically: tests that check which internal helper was called when the
  caller doesn't care; tests that mirror the structure of the implementation;
  tests that break when refactoring without changing behavior.
- Missing edge cases: empty inputs, single-element, max-size, unicode/whitespace,
  null/None/undefined, negative numbers, zero, off-by-one boundaries.
- Missing error paths: what happens with invalid input? Network failure?
  Permission denied? Timeout? Concurrent access?
- Mocks that hide real failures: an HTTP client mocked to always succeed;
  a database mock that doesn't enforce constraints; a time mock that doesn't
  advance.
- Non-deterministic tests: depending on system time, random, network, file
  system order, dict ordering (in older runtimes), or test execution order.
- Redundant tests: multiple tests asserting the same behavior with trivially
  different inputs.
- Vague assertions: assertTrue, expect(x).toBeDefined(), checking only that
  no exception was raised when a specific shape was expected.
- Missing negative cases: only happy paths covered; no tests for "this should
  fail when X".
- Tests that don't actually run (skipped, commented out, broken imports).
- Tests with poor names that don't describe the behavior.
- Setup/teardown leaking state between tests.
- Tests for documented behavior that's missing — read the docstrings/types
  and check every promise has a test.

OUTPUT
Return a markdown document with three sections:

## Critical (must fix before shipping)
- ...

## Major (should fix — risk of false confidence)
- ...

## Minor (nice to have)
- ...

For each issue, cite the specific test by name and explain WHY it's a problem
and WHAT to change. Do NOT edit any files. Reviewing only.

If the tests are actually good, say so explicitly under each section ("None
identified") rather than padding with weak nitpicks.
```

Save the subagent's response. This is your critique document.

## Phase 3 — Refine

Read the critique. For each issue:

- **Critical** — fix every one. These are issues that mean the tests don't catch real regressions.
- **Major** — fix every one unless there's a specific reason not to (and document why).
- **Minor** — fix unless they conflict with project conventions.

Apply the fixes:
- Add tests for missing cases.
- Replace implementation-detail tests with behavior tests.
- Replace over-eager mocks with real implementations or integration-level fixtures.
- Tighten vague assertions.
- Fix non-determinism (freeze time, seed random, sort sets before comparing, etc.).
- Remove redundant tests.

### Run the suite again

Run the whole suite. It must pass. If it doesn't, fix the failures — don't ship a broken refinement.

### Run with coverage if the project has it

If the project has a coverage tool wired up (pytest-cov, c8, jest --coverage, go test -cover, etc.), run it. Report coverage numbers but treat them as a lagging indicator — coverage is a floor, not a ceiling. The critique above is the real quality bar.

## Phase 4 — Report

Tell the user:

1. **What was tested** — file/module/feature.
2. **Phase 1 outcome** — N tests written, all passing.
3. **Phase 2 critique summary** — count of Critical / Major / Minor issues found.
4. **Phase 3 refinement** — what was added, removed, or rewritten in response. If you chose not to address a Major or Critical issue, explicitly justify it.
5. **Final state** — N tests, all passing, [coverage numbers if applicable].

Keep this report tight — one short section per item, not an essay.

## Hard rules

1. **Always run the tests.** A test you didn't run isn't a test, it's a wish.
2. **Phase 2 is non-negotiable.** Do not skip the subagent critique. Self-critique is weaker than independent critique.
3. **Test behavior, not implementation.** If you find yourself asserting "this internal helper was called", ask whether the caller cares. Usually they don't.
4. **Match the project's idiom.** A test suite that doesn't fit the project's existing style is technical debt regardless of how good the tests are.
5. **One behavior per test.** Tests that fail should fail for one reason.
6. **No flaky tests.** If a test depends on time, network, randomness, or filesystem ordering, fix it before shipping. A flaky test is worse than no test — it teaches the team to ignore failures.
