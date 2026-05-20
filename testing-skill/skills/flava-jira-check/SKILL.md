---
name: flava-jira-check
description: Analyze Jira tickets, identify root causes, and (after explicit approval) implement fixes in the LYCC flava-console codebase. When the user asks to check a ticket, first sync default branch (checkout `main`, `git pull --rebase origin main`), then create or switch to a git branch named exactly like the ticket key (e.g. CLOUDQA-84652), then fetch Jira and investigate—so later commits and PRs stay on that branch without extra branching or rebasing. **Deliver findings as a Vietnamese HTML report** (via flava-md-to-html) with tabs for root cause, planned changes, and open questions—not a long markdown writeup in chat. Use whenever the user provides a Jira ticket ID (like LYCC-1234, CLOUDQA-12345) and wants to investigate, check, debug, analyze, or fix an issue — even if they just paste a ticket number without further instructions. Also triggers for phrases like "check this ticket", "investigate this bug", "what's this Jira about", "fix this issue", or "root cause analysis". Supports both single and multiple ticket IDs. After the HTML report and approval gate, do not edit code until the user approves or explicitly asks to implement.
---

# Flava Jira Check

Analyze Jira tickets to understand issues, identify root causes, and—**only after the user approves**—implement fixes in the flava-console codebase. This skill bridges Jira context with codebase investigation; code changes require an explicit go-ahead after the plan and todos are shared.

**Git branch (mandatory for “check ticket” flows):** As soon as you have a ticket key from the user, **sync `main` (checkout + `git pull --rebase origin main`), then create or switch to a branch whose name is exactly that key** (e.g. `CLOUDQA-84652`) *before* fetching Jira and continuing investigation (see **§0**). That way, new ticket branches start from an up-to-date default branch, and when the user later commits and opens a PR, they do so on the ticket branch—**do not** create another feature branch or rebase for this workflow unless the user explicitly asks.

## End-to-end workflow (required order)

Deliver work in this sequence. **Final user-facing deliverable** after investigation is an **HTML report file** (see §5–6), not a long markdown plan in chat.

**Approval gate (mandatory):** After §6, **do not modify product code** — no app/BFF edits, no commits for the fix — unless the user **explicitly approves** the plan or **explicitly asks you to implement** (e.g. “approved”, “go ahead”, “implement it”, “apply the plan”, “fix it now”). If the user is silent, only asked for analysis, or has not approved, **stop** and wait. Ambiguous replies (“ok”, “thanks”) are **not** approval to implement; ask briefly if they want you to proceed.

| Step | Action |
|------|--------|
| **0** | **Sync main + ticket branch** — Checkout `main`, `git pull --rebase origin main`, then create or checkout branch named like the ticket key (§0). |
| **1** | **Check Jira ticket** — Fetch full issue details (see §1). |
| **2** | **Root cause analysis** — Codebase search + synthesis (see §3–4). |
| **3** | **Draft fix plan** — File-level changes, approach, risks, verification (content for §5 HTML; do not paste full plan as markdown in chat). |
| **4** | **Todo tasks** — Checklist inside the HTML report (see §6). |
| **5** | **HTML report** — Generate investigation report via **flava-md-to-html** (§5). |
| **6** | **Stop for approval** — Short chat message + path to HTML; wait for approval before implementation. |
| **7** | **Implement** — Only after approval: execute todos on **current ticket branch** (§7). |
| **8** | **Results** — Update HTML report + brief chat summary (§8). |

If the user only wants analysis, stop after **§6** (no product code changes). **Still perform step 0** (ticket branch) so the repo is positioned for a future PR on that branch.

**Writing the HTML report is allowed** during investigation (step 5); that is not “implementing the fix.”

---

## 0. Sync default branch, then create or switch to the ticket branch

Run this **immediately after** you know the ticket key(s), **before** `jira_get_issue` and codebase work.

**Branch name:** Exactly the issue key, uppercase as in Jira (e.g. `CLOUDQA-84652`, `LYCC-1234`). No extra prefix/suffix unless the user explicitly requests a different name.

**Default branch:** Use **`main`** for `git checkout` and `git pull --rebase origin main` unless the repository’s default branch is clearly different (e.g. `master`); if unsure, check `git remote show origin` or team convention.

**Where:** From the **repository root** of the work (for this monorepo, the `flava-console` git root—not an app subfolder unless the user’s workspace is only that sub-repo).

**Procedure (shell):**

1. Confirm git is available and you are inside a work tree (`git rev-parse --is-inside-work-tree`).
2. If **multiple** ticket IDs are given in one request, use the **first** key as the branch name unless the user specifies which issue the branch should track.
3. **Sync `main` before branching:** `git checkout main` then `git pull --rebase origin main`. This ensures a **new** ticket branch is created from an up-to-date base.
4. Let `TICKET` be the branch name (the issue key).
   - If branch `TICKET` exists locally: `git checkout TICKET` (you are already on updated `main`; switching to an existing branch does not auto-merge `main` into it—note that if the branch was created long ago, the user may want to rebase or merge `main` separately).
   - Else: `git checkout -b TICKET` (creates the branch from the current `HEAD`, i.e. latest `main` after step 3).
5. If checkout, pull, or branch creation fails (e.g. uncommitted changes that block checkout, pull conflicts, or network errors), tell the user clearly and either wait for a clean state or use their preferred approach (stash/commit, resolve rebase) **without** forcing destructive git operations.

**Do not** create a second “feature” branch for the same ticket workflow. After step 0, **all** later implementation commits and the PR target branch should be **`TICKET`**—no automatic rebase and no new branch for “the fix” unless the user asks.

---

## 1. Fetch ticket details

For each provided Jira ticket ID, use the **Jira MCP** tool `jira_get_issue` (read the tool schema under the `user-jira` MCP descriptors before calling). Example:

```
jira_get_issue(issue_key="LYCC-1234", fields="*all", comment_limit=10)
```

Extract and note:

- **Summary & description**: What's the reported problem?
- **Status & priority**: How urgent is this?
- **Labels & components**: Which part of the system?
- **Comments**: Often contain reproduction steps, stack traces, or clues from other engineers
- **Linked issues**: Related tickets that provide additional context

### 2. Analyze the ticket

From the ticket information, identify:

- **Error messages or stack traces** — these are your best leads for codebase search
- **Reproduction steps** — helps understand the user flow
- **Screenshots or logs** — visual clues about what's wrong
- **Environment details** — stage vs real, specific regions affected
- **Related tickets** — patterns across multiple reports

### 3. Search the codebase

Based on what you found in the ticket, search the codebase methodically:

- **Error messages** → use `grep` to find where they originate
- **API endpoints mentioned** → trace the request flow through BFF controllers → services → upstream calls
- **Components/pages mentioned** → find the relevant Vue components, composables, and stores
- **Function or class names** → use `codebase_search` to understand the context

For this monorepo, remember the structure:

- `bff/src/modules/` — BFF modules by domain (instance, application, revision, vpc, etc.)
- `client/src/pages/` — Vue pages (application/, network/)
- `client/src/composables/` — feature composables with TanStack Query hooks
- `client/src/apis/` — API modules (e.g. `apis/index.ts` or domain-specific api files)
- `client/src/utils/` — utility functions including UI-to-API payload converters

### 4. Root cause analysis

Synthesize your findings into a clear analysis:

- **Direct cause**: What specifically triggers the issue?
- **Contributing factors**: Configuration, timing, environment, API changes
- **Impact scope**: Which users/environments/flows are affected?
- **Confidence level**: Are you certain, or is this a hypothesis that needs verification?

---

## 5. Generate investigation report (HTML)

After §4, **always** produce the investigation deliverable as a **standalone HTML file** by following **flava-md-to-html**:

1. Read `.claude/skills/flava-md-to-html/SKILL.md` (language, layout, validation).
2. Use `references/starter-template.html` from that skill as the shell (tabs, dark theme).
3. See `references/jira-check-report.md` in **this** skill for required tabs and content.

**Output path (default):**

```
.claude/flava-md-to-html/docs/<TICKET-ID>-jira-check.html
```

Create the `docs` directory if missing. For multiple tickets in one session, use one file per ticket key.

**Required tabs (Vietnamese labels, `lang="vi"`):**

| Tab | Content |
|-----|---------|
| **Tổng quan** | Ticket summary, status, priority, component, Jira link, repro environment, 1–2 sentence issue recap |
| **Nguyên nhân** | Direct cause, contributing factors, impact, confidence; optional SVG flow if it helps |
| **Kế hoạch thay đổi** | Numbered file-level changes, approach, risk (Low/Medium/High), manual test plan, **implementation todo checklist** (checkboxes) |
| **Cần làm rõ** | Open questions for user/QA/PM before or during implementation; unknowns, missing logs, env access, product decisions |

**Content rules:**

- Pull facts from Jira + codebase investigation; do not invent APIs or paths.
- Keep code paths, ticket keys, error strings, and snippets in **English**; explain in **Vietnamese**.
- If the user asked for English (`in English`, `tiếng Anh`), set `lang="en"` and English tab labels instead.

**Do not** paste the full plan as a large markdown block in chat. The HTML file is the primary artifact.

---

## 6. Chat message and approval

Reply in chat with a **short** summary only, for example:

- Ticket + one-line verdict
- **Full report:** path to `<TICKET-ID>-jira-check.html` and `open <path>` (macOS)
- Ask explicitly whether to **implement** the plan (approval gate)
- If anything is blocking in tab **Cần làm rõ**, call out the top 1–2 questions

Use the editor **todo** tool when available to mirror the HTML implementation checklist **after** the user approves — not as a substitute for the HTML report.

**After §6:** If there is **no** explicit approval to implement, **stop**. Do not edit product code.

---

## 7. Implement the fix

**Only enter this section after the user approves the plan or explicitly asks you to implement** (see **Approval gate** in the workflow table). Then execute the todos:

- **Stay on the ticket branch** from §0 (`TICKET`). Commit and open the PR from this branch—do **not** create another branch or rebase as part of this skill unless the user explicitly asks.
- Make focused, minimal changes — fix the bug, don't refactor the neighborhood
- Follow existing code patterns and conventions (see copilot-instructions.md)
- For BFF changes: use `@CommonData()` decorator, `BaseData` typing, and `AppService` for endpoints
- For client changes: use TanStack Query patterns, `QUERY_KEY` constants, and `createHttpClient()`

After making changes:

- Check for lint/type errors on edited files
- Suggest verification steps the user can follow

---

## 8. Present results

After implementation:

1. **Update the same HTML file** (`.claude/flava-md-to-html/docs/<TICKET-ID>-jira-check.html`):
   - Add or refresh a **Kết quả** section (new tab or expand **Kế hoạch thay đổi**) with: changes made, PR link if any, verification done/pending.
   - Mark todo checkboxes completed where applicable.
2. **Chat:** Brief summary (ticket, root cause one-liner, PR URL, path to updated HTML).

Do not replace the HTML deliverable with a markdown-only results post.

---

## Multiple tickets

When given multiple ticket IDs:

1. **Branch:** Use the **first** ticket key as the branch name (§0), or ask which issue should own the branch if the user is fixing several unrelated items in one session.
2. Analyze each individually first
3. Look for common root causes across tickets
4. Suggest a prioritization order if relevant
5. Identify opportunities for batch fixes
6. One **HTML report per ticket** (`<TICKET-ID>-jira-check.html`); one combined implementation pass only if a single fix addresses several tickets

## Tips

- **HTML over markdown in chat** — Investigators skim tabs in the browser; keep chat to links + approval ask.
- **Sync `main`, then ticket branch** — §0 checks out `main`, runs `git pull --rebase origin main`, then creates or checks out `TICKET` before Jira fetch so new work starts from current `main` and the branch matches the issue for the whole lifecycle (investigate → implement → commit → PR).
- Always read the ticket comments — engineers often leave critical debugging context there
- Check git history of affected files (`git log --oneline -10 -- path/to/file`) to see recent changes that may have introduced the bug
- If the ticket mentions a specific environment (stage/real), keep that in mind when looking at endpoint resolution and feature flags
- When the ticket references a UI issue, trace from the Vue component → composable → API function → BFF controller → BFF service to understand the full data flow
