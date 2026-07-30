---
name: flava-jira-implement
description: Implement fixes/features from an approved flava-jira-check plan. Creates a git branch (ticket-based naming with auto-increment if branch exists), writes unit tests FIRST (TDD), then implements the solution, runs tests. Use after `/flava-jira-check` produces an approved plan. Triggers on "implement this", "apply the plan", "go ahead and fix", "implement LYCC-1234", or `/flava-jira-implement <TICKET-ID>`.
---

# Flava Jira Implement

Implement fixes/features from an **approved** `flava-jira-check` plan. This skill:

1. Reads the plan
2. Creates a git branch
3. Writes unit tests **first** (TDD)
4. Implements the solution
5. Runs tests + lint/type checks

## Prerequisites

- An approved plan file at `.claude/flava-jira-check/plans/<TICKET-ID>.plan.md`
- If no plan exists, tell user to run `/flava-jira-check <TICKET-ID>` first

## Workflow

| Step | Action |
|------|--------|
| **0** | **Read plan** — load and validate the plan file (§0). |
| **1** | **Create branch** — ticket-based naming with auto-increment (§1). |
| **2** | **Write tests first** — create unit tests from the plan's test section (§2). |
| **3** | **Implement solution** — apply changes described in the plan (§3). |
| **4** | **Run verification** — tests + lint + type check (§4). |
| **5** | **Code review** — run `codex exec review --uncommitted` (CLI) on the change (§5). |
| **6** | **Report results** — summary in chat (§6). |

---

## 0. Read the plan

Load the plan file:

```
.claude/flava-jira-check/plans/<TICKET-ID>.plan.md
```

If the file doesn't exist:
- Check if user provided a ticket ID → suggest running `/flava-jira-check <TICKET-ID>` first
- If user provides plan content inline → use that directly

Validate the plan has:
- Solution section with file-level changes
- Unit test plan with test cases

If missing critical sections, ask user before proceeding.

---

## 1. Create branch

**Naming convention:** Branch name based on ticket key with auto-increment if existing branches found.

**Procedure:**

1. Sync main: `git checkout main && git pull --rebase origin main`
2. Check for existing branches matching the ticket:
   ```bash
   git branch --list "<TICKET>*"
   ```
3. Determine branch name:
   - No existing branch → `<TICKET>` (e.g. `LYCC-11560`)
   - `<TICKET>` exists → `<TICKET>-1`
   - `<TICKET>-1` exists → `<TICKET>-2`
   - And so on...
4. Create and checkout: `git checkout -b <BRANCH_NAME>`

**If checkout/pull fails** (uncommitted changes, conflicts): tell user clearly, wait for resolution. Do not force destructive git operations.

---

## 2. Write tests first (TDD)

Before implementing the solution, write the unit tests from the plan's "Unit Test Plan" section.

**Order matters:** Tests are written BEFORE the implementation so they initially fail (red), then pass after implementation (green).

### Steps:

1. **Create test file(s)** as specified in the plan
2. **Write test cases** covering:
   - Bug reproduction test (would fail before fix, pass after)
   - Edge cases
   - Regression cases
3. **Use correct framework:**
   - Client/Vue: Vitest + jsdom + @testing-library/vue
   - BFF/NestJS: Jest
4. **Follow existing patterns** in the repo — check sibling spec files for import style, mock patterns
5. **Run tests** to confirm they fail (expected — implementation not done yet):
   ```bash
   pnpm --filter <pkg> run test:ci -- <pattern>
   ```
   - If tests that should reproduce the bug already pass → the test isn't testing the right thing. Fix the test.
   - Tests for new functionality should fail with "not found" / "undefined" errors — that's expected.

**If the plan's test section is incomplete:** Use your judgment to add reasonable test cases, but don't over-test. One regression + one edge case minimum.

---

## 3. Implement the solution

Apply changes from the plan's "Solution" section:

- **Minimal, focused changes** — fix the bug or add the feature, don't refactor the neighborhood
- **Follow existing code patterns:**
  - BFF: `@CommonData()` decorator, `BaseData` typing, `AppService` for endpoints
  - Client: TanStack Query patterns, `QUERY_KEY` constants, `createHttpClient()`
- **Extract testable logic** when inline computed/methods contain business logic — put in utils, test the utils
- **Match the plan** — if deviating from the plan, note why

---

## 4. Run verification

After implementation, run in order:

1. **Unit tests** (must all pass now):
   ```bash
   pnpm --filter <pkg> run test:ci -- <pattern>
   ```
2. **Lint** (on changed files):
   ```bash
   pnpm --filter <pkg> run lint
   ```
3. **Type check**:
   ```bash
   pnpm --filter <pkg> run type:check
   ```

If any fail → fix before reporting. If a test failure reveals a plan issue, note it in the results.

---

## 5. Code review

After verification passes, run a Codex review on the change using the Codex CLI (headless):

```bash
codex exec review --uncommitted
```

- Preflight: if `command -v codex` fails, skip and note "Codex CLI not installed"; don't block.
- `codex exec review` runs the built-in reviewer non-interactively against the repo. `--uncommitted` scopes it to staged + unstaged + untracked changes — exactly what you just wrote, before committing, so findings land in the same branch.
- Run it as the last step, foreground (one call). Capture stdout as the review.
- **Do not auto-fix** review findings. Surface Codex's output, then let the user decide what to address. If findings are clear bugs the user asks you to fix, apply them and re-run verification.
- Note: this is the standalone `codex` CLI, not a Claude Code plugin — no `/codex:*` slash command is required.

---

## 6. Report results

Chat summary:

- **Ticket**: `<TICKET-ID>` + one-line summary
- **Branch**: `<BRANCH_NAME>`
- **Files changed**: list with one-line description each
- **Tests**: pass count, what's covered
- **Status**: ready for commit / has issues

Do NOT auto-commit. User decides when to commit (suggest `/flava-commit-skill` or `/commit`).

---

## Tips

- **Tests first is non-negotiable.** Even if the fix is obvious, write the test, see it fail, then fix.
- **Extract before test.** If logic is inline in a Vue computed or template, extract to a pure util function. Test the util. Keep the component thin.
- **One branch per attempt.** If a previous branch exists for the same ticket, auto-increment (`-1`, `-2`) so previous work is preserved.
- **Don't over-scope.** Implement what's in the plan. If you notice other issues, note them but don't fix them unless the plan says to.

## Relationship to other skills

- **flava-jira-check**: investigate → plan → approval. Runs BEFORE this skill.
- **flava-jira-implement** (this): takes approved plan → branch → tests → implement → verify → `codex exec review`.
- **flava-commit-skill**: commit changes after implementation.
- **flava-pr-skill**: create PR after commit.

Typical flow: `/flava-jira-check LYCC-1234` → approve → `/flava-jira-implement LYCC-1234` → `codex exec review` → `/commit` → `/flava-pr-skill`
