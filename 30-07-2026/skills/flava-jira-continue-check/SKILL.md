---
name: flava-jira-continue-check
description: Continue work on a Jira ticket that ALREADY has code changes and an open PR, but needs updates because the spec changed or QA found a bug. Use whenever the user says a ticket "needs rework", "QA found a bug", "spec changed", "reopen", "PR needs update", "there's a new comment on the ticket", "fix the review feedback", or provides a ticket ID that already has an in-progress branch/PR (LYCC-1234, CLOUDQA-12345). This differs from flava-jira-check (first-time investigation): here the branch and PR already exist, so the skill auto-detects the existing branch + PR, reads the current diff, reconciles it against the NEW spec/QA/reviewer feedback, plans only the incremental delta, and — after approval — amends the existing branch and updates the PR. Prefer this skill over flava-jira-check whenever the ticket is already coded and a PR exists.
---

# Flava Jira Continue-Check

Continue an **already-in-progress** ticket. Unlike `flava-jira-check` (fresh investigation → new branch), this ticket already has committed code and an **open PR**. Something changed after the PR was opened — the **spec was updated**, **QA reported a bug**, or a **reviewer left feedback**. The job is to find what's already done, figure out the **delta** the new information requires, plan it, and — after approval — update the existing branch and PR.

Why the delta framing matters: the existing diff is context, not scope. Re-planning the whole ticket wastes effort and risks reverting reviewed work. Plan only what the new spec/QA/feedback demands, on top of what's already shipped.

## End-to-end workflow (required order)

Deliver in this sequence. Final output before any code change = **delta plan + todos** (§5–6). Then implement on the **existing branch** after approval.

**Approval gate (mandatory):** After §5–6, do **not** modify code — no edits, no commits, no PR update — unless the user **explicitly approves** or **asks to implement** ("approved", "go ahead", "apply it", "update the PR"). Silence, "ok", "thanks" are **not** approval — ask briefly before proceeding.

| Step | Action |
|------|--------|
| **1** | **Fetch ticket + what's new** — Full issue, focus on recent comments / updated spec / QA report (§1). |
| **2** | **Detect existing work** — Find the ticket's branch + open PR; read the current diff (§2). |
| **3** | **Reconcile** — Compare "what's already done" vs "what the new info now requires" → the delta (§3). |
| **4** | **Delta plan** — Concrete file-level plan for ONLY the incremental change (§4). |
| **5** | **Todo tasks** — Break the delta into small verifiable items (§5). |
| **6** | **Stop for approval** — Present plan + todos; wait (see gate above). |
| **7** | **Implement** — On the existing branch: apply delta, add/adjust tests, run lint/type/test (§6). |
| **8** | **Code review** — run `codex exec review --uncommitted` (CLI) on the delta before committing (§7). |
| **9** | **Update PR** — Commit, push, update PR description/comment; note Jira status (§8). |

If the user only wants analysis, stop after §5.

---

## 1. Fetch ticket + identify what's new

Use the **Jira MCP** `jira_get_issue` with full comments — both the **new requirement** and the **PR link** almost always live in **recent comments**, not the original description. Read the comments carefully: they carry the PR URL (used in §2) and the QA/spec/reviewer change that defines the delta.

```
jira_get_issue(issue_key="LYCC-1234", fields="*all", comment_limit=20)
```

Pin down the **change trigger** — this is the whole point of the skill:

- **QA bug**: a comment describes a repro / wrong behavior / screenshot. What behavior is now expected vs what shipped?
- **Spec change**: description edited or a comment adds/removes/alters a requirement. What's the new requirement?
- **Reviewer feedback**: PR review comments requesting changes (read them in §2 from the PR too).
- **Status signal**: ticket moved back (e.g. In Review → In Progress / Reopened) — confirms rework.

Write one line: *"New requirement/bug: ___ (source: comment by X on DATE / PR review / edited spec)."* Everything downstream serves this line.

## 2. Detect the existing branch + PR

The code exists — find it, don't restart.

**PR link is usually already in a Jira comment.** Teams here typically drop the PR URL as a comment on the ticket (often the user's own comment). So **read the ticket comments from §1 first** and pull the PR link/number straight from there — that's the fastest and most reliable path. Only fall back to git/GitHub search below if no PR link is present in the comments.

**Branch:** ticket-based naming (same convention as `flava-jira-implement`). Search:

```
git branch -a --list "*LYCC-1234*"        # or the ticket id
git log --all --oneline --grep="LYCC-1234"
```

If multiple branches match (auto-increment suffixes), pick the one tied to the open PR. If none found locally, `git fetch` first, then check remote.

**PR:** use **GitHub MCP** (never `gh` CLI — see `flava-pr-skill`). Find the open PR for that branch/ticket:

- `search_pull_requests` with the ticket id, or `list_pull_requests` filtered by head branch.
- Read the PR: `pull_request_read` for description, and the **diff** + **review comments** (unresolved review threads are often the "what's new").

**Read the current diff** so you know what's already implemented:

```
git diff main...<branch>          # full delta of the PR vs base
git log main..<branch> --oneline  # commits already on the branch
```

State plainly: *"Branch `<name>`, PR #<n>, already implements: ___."*

## 3. Reconcile — compute the delta

Now hold two things side by side:

- **Already done** (from §2 diff): what the PR currently changes.
- **Now required** (from §1): what the new spec/QA/feedback demands.

The **delta** is the gap. Categorize each item:

- **Add** — new behavior not yet in the diff.
- **Change** — shipped code that's now wrong per the new spec / QA repro.
- **Remove** — code that the spec change makes obsolete.
- **Already covered** — new requirement the current diff *already* satisfies (say so; don't touch it).

For a **QA bug**, trace root cause in the *already-changed* code first — the bug usually lives in the new code, not the old codebase. If it's in pre-existing code the PR touched, fix at the shared root (grep other callers), not just the reported path.

Monorepo map (same as flava-jira-check): `bff/src/modules/` (BFF by domain), `client/src/pages/`, `client/src/composables/`, `client/src/apis/`, `client/src/utils/`. Product-specific conventions live in the per-product skills (e.g. `flava-lb-skill`, `flava-vector-search-skill`) — load the matching one before editing.

## 4. Present the delta plan

```markdown
## Continue Plan for [TICKET-ID] (PR #<n>, branch `<name>`)

### What changed
New requirement / QA bug: ___ (source: ___)

### Already implemented (PR #<n>)
- Short recap of what the current diff does (so we don't redo it)

### Delta — only what to change now
1. **file/path.ts** — [Add|Change|Remove] what & why
2. **another/file.ts** — ...

### Already covered (no change)
- New requirement item X is already satisfied by the current diff

### Risk assessment
- Low/Medium/High — why. Watch for regressions on already-reviewed code.
```

Do not edit after posting this unless already approved (see gate).

## 5. Create todo tasks from the delta

Turn the **Delta** into a small numbered checklist — only the incremental items. Use the editor todo tool **after approval**. User gets plan (§4) + todos before any code change.

If no explicit approval to implement → **stop**.

## 6. Implement on the existing branch

Only after approval. Key difference from a fresh implement: **stay on the existing branch — do not create a new one.**

```
git switch <branch>    # the detected PR branch, not a new one
```

Then:

- Apply **only the delta**. Don't refactor reviewed code that the new spec doesn't touch.
- **Tests**: update existing tests that the delta breaks; add tests covering the new spec / the QA repro so it can't regress. (Follow product skill test conventions — e.g. vector-search `processorSerialization.test.ts`.)
- Run scoped checks on touched packages: `pnpm --filter <pkg> run lint`, `type:check`, `test:ci` (see AGENTS.md).

## 7. Code review the delta

After the delta passes lint/type/test, run a Codex review with the Codex CLI (headless) before committing:

```bash
codex exec review --uncommitted
```

- Preflight: if `command -v codex` fails, skip and note "Codex CLI not installed"; don't block.
- `codex exec review --uncommitted` runs the built-in reviewer non-interactively against staged + unstaged + untracked changes — exactly the incremental delta you just made, before committing, so findings land in the same push. Run foreground (one call).
- **Do not auto-fix** findings. Surface Codex's output; if the user asks to address a finding, apply it and re-run the §6 scoped checks. Keep fixes inside the delta — don't let a review finding pull in already-reviewed code (that invites re-review churn).
- Note: standalone `codex` CLI, not a Claude Code plugin — no `/codex:*` slash command required.

## 8. Update the PR (not a new one)

The PR already exists — update it, don't open another.

- Commit with the same commitlint format (`flava-commit-skill`): `type(scope): TICKET-ID: message`. Stage only shared code paths.
- Push to the existing branch → PR updates automatically.
- Update the PR description/Test Plan if the changes are material, or add a PR comment summarizing the rework ("Addressed QA: … / Spec change: …"). Use **GitHub MCP** only.
- Jira: add a comment noting the rework + push; if the ticket was moved back for rework, transition it forward again (e.g. → In Review) only if the user wants (`flava-pr-skill` conventions). Ask if unsure.

## 9. Present results

```markdown
## [TICKET-ID] rework complete — PR #<n>

**Trigger**: QA bug | Spec change | Review feedback
### What was already done
Recap of prior PR state
### Delta applied
1. file — change & why
### Tests
- New/updated tests covering the new spec / QA repro
### Code review
- Codex review run (`codex exec review`); findings addressed / none
### Verification
- How to verify the rework
```

## Tips

- The new requirement is usually in a **recent Jira comment or PR review thread** — read those first, not just the original description.
- Never start a new branch or new PR — the value here is *continuing* existing work.
- If the "new" requirement turns out to already be satisfied by the current diff, say so and stop — don't invent work.
- If the branch/PR can't be found, the ticket may not actually be in-progress → suggest `flava-jira-check` (fresh) instead.
- Amending already-reviewed code beyond the delta invites re-review churn — keep the diff tight.
