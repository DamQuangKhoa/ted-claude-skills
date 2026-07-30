---
name: flava-unit-test
description: >-
  Write unit tests that actually CATCH BUGS (not change-detector tests) for the
  LYCC/flava-console monorepo — Vitest for client packages, Jest for BFF. Use
  whenever the user asks to "write tests", "add unit tests", "test this
  function/composable/service/util", "cover this with tests", "add test cases",
  "TDD this", or when a plan/PR needs a test plan — even if they don't name a
  framework. Applies 12 principles (test behavior not methods, Given-When-Then,
  literal asserts, narrow asserts, deterministic, mock-only-what-you-own, public
  API only, parameterized cases, builders) and a what-to-check list (money, time,
  permissions, state transitions, idempotency, async/retry). Runs the scoped test
  gate (`pnpm --filter <pkg> run test:ci`) and reports pass/fail — never declares
  "done" without green. Do NOT use for e2e/integration tests that open sockets/DB
  (those are a different thing), or for non-test code changes.
---

# Flava Unit Test

Write unit tests that **fail for exactly one real reason** — tests that catch bugs, not tests that merely notice code changed. 100% coverage with green change-detector tests still ships bugs; this skill exists to prevent that.

**Stack (this repo):**
- **Client** (`apps/product-*/client`, `shared/`): **Vitest**. Specs are `*.test.ts` / `*.spec.ts`, often under `__tests__/` or beside the source. Mock the shell module (`vi.mock('@flava-federation/shell/index', ...)`) and TanStack Query (`vi.mock('@tanstack/vue-query', ...)`) — those throw at import in jsdom.
- **BFF** (`apps/product-*/bff`): **Jest**. Specs are `*.spec.ts` beside the service/controller.
- **Run (always, before "done"):** `pnpm --filter <workspace-pkg> run test:ci -- <pattern>` (name via `pnpm -r list --depth -1`). Some BFF packages have no `test:ci` — grep `package.json` first.

**Prefer testing pure logic** — utils, helpers, validators, composable logic, BFF services. UI-only SFC markup rarely needs a unit test; extract logic to a util and test that.

---

## The 12 principles

1. **Test behavior, not methods.** A method with 3 outcomes → 3 tests, one scenario each. If a test name needs "and", split it.
2. **Given-When-Then, no logic in assertions.** Setup → act → verify. Assert **literal** expected values (`toBe(30)`, never `toBe(price * qty)` — that just re-implements the bug).
3. **Narrow asserts.** Assert only the field the behavior is about. Don't `toEqual` a whole object when you're testing one property.
4. **Failures must be actionable.** Test name + failure message should locate the bug without reading the test body.
5. **Parameterized for one behavior × many inputs.** Same logic, many inputs → one `it.each` with **named** cases so you know which row failed.
6. **Keep cause next to effect.** Setup that matters lives in the test, not in a far-away `beforeEach`.
7. **Test through the public API, not private methods.** Private methods are implementation detail — cover them via the public method that uses them.
8. **Deterministic.** No real clock / network / random in a unit test. Inject or stub them. Same input → same output, every run.
9. **Mock only what you own, as little as possible.** Preference: **real > fake > mock**. Wrap third-party types behind your own interface and mock that. Stub queries (return data); `verify()` only the state-changing commands.
10. **Clean test data via builders/factories.** Each test states only the fields it cares about; a builder fills the rest.
11. **A good test is Clear, Complete, Concise, Resilient** — and can fail for **exactly one** real reason.
12. **Don't call it an "integration test" when you don't need one.** Unit tests open no socket/file/DB. If you genuinely need those, it's an integration test — say so explicitly.

## What to check (don't stop at the happy path)

The happy-path test is the easy 20%. These are where the bugs live — cover the ones the code touches:

1. **Money / amounts** — rounding, precision, negative, zero, currency mismatch.
2. **Time / timezone** — UTC vs local, DST, midnight rollover, leap year. (Inject the clock — principle 8.)
3. **Permissions** — every role × action, and the **deny** paths, not just allow.
4. **State transitions** — legal transitions AND illegal ones (rejected).
5. **Idempotency** — duplicate submit, unique-constraint violation, retry of a completed op.
6. **Async / retry** — timeout, retry behavior, cancellation, partial failure.

For a **bug fix**: write the test that **reproduces the bug first** (red), then fix (green). That test is the regression guard — it must fail before the fix.

## Anti-patterns — do NOT do these

| Anti-pattern | Do instead |
|---|---|
| Boot full framework / DB for a unit test | Isolate; stub the boundary |
| Logic in the assertion | Assert a literal value |
| Setup in a far-away `beforeEach` | Keep cause next to effect |
| One test asserting many behaviors | Split into one-behavior tests |
| Over-verifying mock args | Verify only what the behavior needs |
| Mocking a third-party type directly | Wrap it; mock your own interface |
| Testing private methods | Go through the public API |
| N copy-pasted near-identical tests | One parameterized `it.each` |
| Declaring "done" without running | Run `test:ci`, show green — or say plainly it wasn't run |

## Workflow

1. **Find the unit under test + its existing spec.** Grep for a sibling `*.test.ts`/`*.spec.ts`; extend it rather than making a parallel file. Match the file's existing mock setup (shell, TanStack Query).
2. **Enumerate behaviors** — list the distinct outcomes (principle 1). One test per outcome; group inputs that share logic into an `it.each` (principle 5).
3. **Pick the what-to-check categories that apply** — if the code touches money/time/permissions/state/idempotency/async, add those edge cases; don't just test the happy path.
4. **Write Given-When-Then**, literal asserts, narrow (principles 2-3), deterministic (principle 8), builders for data (principle 10).
5. **Run the gate:** `pnpm --filter <pkg> run test:ci -- <pattern>`. For a bug fix, confirm the new test **fails before** the fix, passes after.
6. **Report** pass/fail counts. Never say "done" on an unrun suite (principle 12 / last anti-pattern) — if you couldn't run it, say so and why.

## Examples

**Behavior not method (principle 1):**
```
// BAD: one test for the whole function
it('calculates storage', () => { ... three asserts for three cases ... })

// GOOD: one behavior each
it('counts local disk against the disk quota', () => { ... })
it('counts NVMe against the block-storage quota', () => { ... })
it('ignores storage for non-data node groups', () => { ... })
```

**Literal assert (principle 2):**
```
// BAD — re-implements the logic under test:
expect(usage.disk).toBe(size * NODE_FOR_3_AZ);
// GOOD — a value a human verified:
expect(usage.disk).toBe(600);
```

**Parameterized with named cases (principle 5):**
```
it.each([
  ['fke-controller', false],   // control-plane → suppressed
  ['addon-lb-controller', true],
  [undefined, true],
])('provisioner %s → isUserResource %s', (provisioner, expected) => { ... });
```

## Related skills
- **flava-jira-implement** — writes tests-first when implementing a plan; use this skill's principles there.
- **flava-review-pr** §8.4 — judges whether a PR's tests are meaningful (not change-detectors); shares this rubric.
- **flava-lb-skill / flava-blueprint-skill** — product test conventions + existing spec locations.
