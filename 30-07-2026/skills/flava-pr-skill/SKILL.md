---
name: flava-pr-skill
description: Create pull requests for the LYCC flava-console project using **GitHub MCP only** (never `gh` CLI). Use whenever the user asks to "create a PR", "open a PR", "make a pull request", "submit my changes for review", or mentions pushing and creating a pull request. **Generates the PR description inline** (§4) by analyzing commits + diff and following the project's PR template — Summary, JIRA Ticket, Root Cause, Changes, Test Plan (with unit-test/coverage tables) — with an opt-in test-gating flow that can add missing specs and auto-fill test results. No separate description skill needed. This skill also knows how to extract context from commits and branch names, **assign the PR to the creator** and **add GitHub labels** after creation, and link the PR on Jira (remote link / `remotelink` when available — not `jira_create_issue_link`). **By default** (unless the user opts out): after the PR exists, **post exactly one Jira comment per commit-derived ticket** with the PR URL, **then transition that ticket** (default target **In Review** when the workflow allows). Never duplicate the PR link in `jira_transition_issue`'s `comment`. **Optionally** (opt-in only — "review after PR", "self-review this PR"): after the PR is created, chain the `flava-review-pr` skill for an **advisory, report-only** review (no auto-fix, no auto-post). Opt-out examples: "PR only", "don't comment Jira", "don't change Jira status", "leave ticket open", "don't assign me", "no labels".
---

# Flava PR Skill

Create pull requests for the LYCC flava-console monorepo via **GitHub MCP only**. The PR description follows a structured template that gives reviewers clear context on what changed, why, and how to verify.

## GitHub tooling (required)

| Use | Do not use |
| --- | --- |
| **GitHub MCP** (`user-github`) — `create_pull_request`, `list_pull_requests`, `search_pull_requests`, `pull_request_read`, etc. | **`gh` CLI** — not configured for `git.linecorp.com`; will fail or target the wrong host |
| **Git shell** — `git status`, `git diff`, `git pull --rebase`, `git push` | `gh pr create`, `gh pr view`, `gh api`, or any other `gh` subcommand |

**Before any GitHub MCP call:** Read the tool descriptor under `mcps/user-github/tools/<tool-name>.json` (required parameters, return shape).

**Host note:** The git remote is `git@git.linecorp.com:LYCC/flava-console.git`. GitHub MCP still creates PRs on that host; the returned **`url`** is typically `https://git.linecorp.com/LYCC/flava-console/pull/<number>` — use that exact URL in Jira comments and when reporting to the user.

## PR Description Template

```markdown
## Summary

[1-2 sentence high-level description of the change]

## JIRA Ticket

[Markdown link to Jira — see **JIRA ticket links** below]

## Root Cause

[Why the change is needed — what was broken, missing, or suboptimal. Skip this section for pure feature work where there is no "root cause".]

## Changes

[Numbered list of concrete changes, grouped by file or area. Each item should state *what* changed and *why*.]

## Test Plan

[How to verify the change — manual steps, unit tests, or "N/A" if trivial.]
```

### JIRA ticket links (required)

In the **## JIRA Ticket** section, **never** put only a bare ticket key. Always use a **clickable markdown link** to Workers Hub Jira:

- **URL pattern**: `https://jira.workers-hub.com/browse/<TICKET-KEY>`
- **Markdown**: `[<TICKET-KEY>](https://jira.workers-hub.com/browse/<TICKET-KEY>)`

Examples:

- `LYCC-1234` → `[LYCC-1234](https://jira.workers-hub.com/browse/LYCC-1234)`
- `CLOUDQA-83859` → `[CLOUDQA-83859](https://jira.workers-hub.com/browse/CLOUDQA-83859)`

If there are **multiple** tickets, use a short list of links (one per line). For **NO-JIRA**, write `NO-JIRA` as plain text (no link).

## Process

### 1. Gather context

Before composing the PR, collect everything you need:

- **Branch name**: `git branch --show-current` — often contains the ticket ID (e.g. `feat/LYCC-1234-something`)
- **Commits on branch**: `git --no-pager log --oneline origin/main..HEAD` — shows all commits being merged
- **Diff summary**: `git --no-pager diff --stat origin/main..HEAD` — shows files changed
- **Detailed diff** (if needed): `git --no-pager diff origin/main..HEAD -- <specific-file>` — for understanding specific changes
- **Ticket IDs for PR title/body**: extract from branch name, commit messages, or ask the user.
- **Ticket IDs for Jira comments (§9)**: see **§9** — use **commit messages only**, not the branch name or optional extra links in the PR description unless the user explicitly tells you to comment on additional keys.
- **Jira after PR (default):** Unless the user opts out, run **§9** (one PR comment per commit-derived key) **then** **§10** (status transition). **§10** always runs **after** §9 for the **same** keys. Do not put the PR URL in **`jira_transition_issue`**’s `comment`.
- **Assignee + labels after PR (default):** Unless the user opts out, run **§7** immediately after **§6** (see below).
- **Target branch**: usually `main` unless the user specifies otherwise

### 2. Determine the target repository

The remote is `git@git.linecorp.com:LYCC/flava-console.git`, which means:

- **Owner**: `LYCC`
- **Repo**: `flava-console`

If the remote URL is different, parse accordingly. The format is `git@<host>:<owner>/<repo>.git` or `https://<host>/<owner>/<repo>.git`.

### 3. Compose the PR title

Use the same format as commit messages:

```
type(scope): TICKET-ID: Sentence case description
```

If the branch has multiple commits with the same ticket, combine them into a single descriptive title. The title should describe the overall change, not repeat individual commit messages.

**Valid types**: feat, fix, refactor, chore, docs, style, test, perf, build, ci, revert

**Valid scopes** (same as commitlint — pick based on which `apps/product-*` directory changed):

```
rollout-manager, catalog, api-gateway, langfuse-service, blueprint, lb,
file-storage, dbs-for-mysql, object-storage, vpc, egress-proxy, dns,
server, kubernetes-engine, cdn, project, overview, iam, service-connect,
batch, dbs-for-mongodb, dbs-for-vector-search, mcp-hub, ai-assistant,
app-runner, gslb, certificate-manager, cloud-shell, dbs-for-opensearch,
dbs-for-postgresql, dbs-for-cassandra, operation-log, secret-manager,
dbs-for-redis, function, mq-for-pulsar, boilerplate, shell, flava-shell,
all, monitoring, container-registry, frontend-proxy, ml-runner,
event-bridge, style
```

### 4. Generate the PR body (inline — do it here, don't skip)

Compose the PR body yourself in this step by analyzing the branch's commits and diff. This used to delegate to a separate `flava-gen-pr-desc` skill, but that hand-off was routinely skipped, so the logic now lives here — there is nothing to call out to. The one thing that must not be lost is the **template correctness**: every PR gets the full structure below, including the unit-test / coverage tables.

Read the diff you gathered in §1 (`git --no-pager diff origin/main..HEAD`) to understand what actually changed — which areas (BFF / Client), the change type (feature / fix / refactor), and the impact. Then fill in the template. Guidelines per section:

- **Summary**: Concise — what does this PR accomplish from a user/reviewer perspective? Imperative mood ("Add …", not "Added …"). Focus on WHAT, not HOW.
- **JIRA Ticket**: One markdown link per ticket using `https://jira.workers-hub.com/browse/<KEY>` (see **JIRA ticket links** above). Never leave the key as plain text only.
- **Root Cause**: Explain _why_ the change is needed. For bug fixes, describe the bug mechanism. For features, describe what gap existed. Omit this section entirely for trivial changes (typos, dependency bumps, config tweaks).
- **Changes**: Numbered list grouped by area (BFF / Client / module). Include file paths when helpful. Each item a complete sentence stating _what_ changed and _why_.
- **Test Plan**: Be specific — manual steps for UI, plus the **Unit tests** subsection with the two tables below. See **§4a (test-gating flow)** for how the numbers get filled.

#### PR body template (use this exact structure)

```markdown
## Summary

[1-2 sentence high-level description]

## JIRA Ticket

[LYCC-XXXXX](https://jira.workers-hub.com/browse/LYCC-XXXXX)

## Root Cause

[Why the change is needed — omit for pure feature work with no "root cause".]

## Changes

1. **[Area]** (`path/to/file`)
   - [what changed and why]

## Test Plan

[Manual verification steps — numbered, with expected results.]

### Unit tests

Run: `pnpm --filter <workspace-pkg> run test:ci` (and `test:coverage` if the package has that script).

[Optional 1-2 sentences: which new/changed specs were added and what they cover. Skip if no specs touched.]

**Suite result**

| Metric     | Value                                   |
| ---------- | --------------------------------------- |
| Test files | [N] passed                              |
| Test cases | [N] passed ([existing + new breakdown]) |
| Passing    | [N]                                     |
| Failing    | 0                                       |

**Coverage — touched files** (`test:coverage`)

| File              | Stmts | Branch | Funcs | Lines |
| ----------------- | ----- | ------ | ----- | ----- |
| `path/to/file.ts` | X%    | X%     | X%    | X%    |

> [Optional: if touched files are 100% but the aggregate is lower, note it is a pre-existing baseline and out of scope.]

## Impact & Risk

- Scope: [UI only / Logic / API / Database]
- Risk level: [Low / Medium / High]
- Breaking change: [Yes / No]
```

If the touched package has **no `test:coverage` script** (grep `package.json` first), keep the Suite result table and drop the Coverage table with one line: `Coverage: no coverage script in this package.` If **no spec files were touched**, still emit the section: "No new test files. Existing suite: [N] passed." The Coverage table lists **only diff-touched files**, never the whole product.

### 4a. Test-gating flow (run once, BEFORE writing the body)

This decides how the Unit tests tables get populated. Skip the whole flow only for a docs-only PR (no code files in the diff). Do not re-ask if the user already answered these earlier in the same session — respect the prior choice for the whole run.

**Step A — Detect changed code files worth testing.** From `git diff origin/main..HEAD --name-only`, keep logic-carrying paths (adapt globs to the product):
- Client: `src/composables/**/*.ts`, `src/helpers/**/*.ts`, `src/validators/**/*.ts`, `src/utils/**/*.ts`, `src/components/**/*.vue` (only if the SFC has meaningful `<script setup>` logic beyond markup)
- BFF: `src/**/*.service.ts`, `src/**/*.controller.ts`, `src/**/*.dto.ts` (validators only)

Drop: `*.spec.ts`, `*.test.ts`, `__tests__/**`, generated files (`swagger.json`, `dist/`, lockfiles), pure-markup SFCs, `main.ts`, config files.

**Step B — Map each candidate to its spec.** For each `<path>/<name>.<ext>`, look for `<path>/__tests__/<name>.spec.ts`, `<path>/__tests__/<name>.test.ts`, or any `**/__tests__/**` file named `<name>.spec.ts`. Categorise: `covered` (spec exists AND diff touched it), `has-spec-untouched` (spec exists, diff didn't touch it — just note), `missing` (no spec anywhere).

**Step C — Decide via AskUserQuestion (at most two single-select questions; skip a question if its answer is forced).**

*Q1 (only if `missing` is non-empty):* "Diff touches N files without any spec: [list]. Add unit tests for these?"
- **Yes, generate them (Recommended)** — before writing the PR body, add specs matching the product's existing test convention, then run `pnpm --filter <pkg> run test:ci` yourself and iterate until green. Do not wait for the user to run them.
- **No, skip** — proceed; note the un-covered files under a "Known items" bullet in the PR body so review catches it.

*Q2 (always, once the test set is settled):* "Auto-run `test:ci` + `test:coverage` and fill the Unit tests tables, or leave slots to paste?"
- **Auto-run and fill (Recommended when a `test:coverage` script exists)** — run both, parse the summary line (Test files / Test cases / Passing / Failing) and the per-file coverage rows for touched files only, populate the tables. If a command fails or the coverage script is missing, fall back to slots and note the reason in one line.
- **Leave slots** — emit the tables with `[N]` / `X%` placeholders.

**Step D — Proceed with the body.** Only after Q1 (and any generated specs land + pass) and Q2, write the PR body. Reflect Q1's outcome in the Unit tests prose (new spec list, or the "no new tests" acknowledgement) and use real numbers or slots per Q2. **Do not** run `test:ci` / `test:coverage` outside the Q2=Yes branch — the flow is opt-in.

Optionally save the composed body to `.pr-description.md` (the repo ignores/untracks it) so you can review before passing it to `create_pull_request` in §6.

### 5. Rebase on main and push

Before pushing, always rebase on the latest `main` to catch conflicts early:

```bash
git pull --rebase origin main
```

- **No conflicts**: Proceed to push.
- **Conflicts detected**: Fix the conflicts in the affected files, then `git add <files>` and `git rebase --continue`. Repeat until the rebase completes. If the conflicts are complex or ambiguous, show the user the conflicting files and ask how to resolve them.

Then push the branch:

```bash
git push origin <branch>
```

If the rebase rewrote commits that were already pushed, you'll need a force push — ask the user for confirmation before running `git push --force-with-lease origin <branch>`.

### 6. Create the PR via GitHub MCP (never `gh`)

1. **Check for an existing PR** — call **`list_pull_requests`** or **`search_pull_requests`** on `user-github` with `owner`/`repo` and `head` = current branch (or search `head:<branch>`). If one exists, share its **`url`** and **do not** create a duplicate.

2. **Create the PR** — call **`create_pull_request`** (read schema first):

   | Parameter | Value |
   | --------- | ----- |
   | **owner** | Parsed from git remote (e.g. `LYCC`) |
   | **repo** | Parsed from git remote (e.g. `flava-console`) |
   | **title** | Composed PR title |
   | **body** | Full markdown PR body (see formatting warning below) |
   | **head** | Current branch name |
   | **base** | `main` (or user-specified) |
   | **draft** | `true` only if user asked for draft/WIP |

   **⚠️ Body formatting — CRITICAL:** The `body` parameter must contain **actual newlines**, not literal `\n` escape sequences. When passing the body to `create_pull_request`, read the `.pr-description.md` file content and pass it directly as the parameter value — do NOT manually construct the body string with `\n` characters. Literal `\n` will render as broken plaintext on GitHub instead of formatted markdown. If you must compose the body inline, use real line breaks in the parameter value, never escape sequences.

3. **Capture the PR URL** from the MCP response (`url` field). Do **not** guess or construct the link from memory.

4. **If MCP fails:** Report the error and stop — do **not** fall back to `gh`. Ask the user to fix MCP auth or create the PR manually on `git.linecorp.com`.

Save the returned **PR number** and **URL** — required for steps 7–11.

### 7. Assign the PR to the creator and add labels (default)

**When:** Immediately after step **6** succeeds. PRs on GitHub are also issues, so use the **`issue_write`** MCP tool (`method: "update"`) with the PR number as `issue_number`.

**Opt out:** Skip when the user says **“PR only”**, **“don’t assign me”**, **“no assignee”**, or **“no labels”** (partial opt-out: skip only the part they named).

#### Assignee (default)

1. Call **`get_me`** and read `login` — this is the GitHub user opening the PR (the creator).
2. If the user explicitly named someone else (e.g. “assign to hanh-nguyen”), use that username instead.
3. Include in **`issue_write`**:
   - `method`: `"update"`
   - `owner`, `repo`: same as step 6
   - `issue_number`: PR number from step 6
   - `assignees`: `["<login>"]`

Team convention: assignee should match the PR author (same person who pushed the branch).

#### Labels (default)

Derive labels from the commit **type** prefix in the PR title (same `type` as commitlint):

| PR / commit `type` | Label to apply |
| ------------------ | -------------- |
| `fix` | `bug` |
| `feat` | `enhancement` |
| `refactor`, `chore`, `docs`, `style`, `test`, `perf`, `build`, `ci`, `revert` | none (unless user requests) |

1. Build the `labels` array from the table above.
2. For each label, optionally confirm it exists with **`get_label`**; skip any label that 404s rather than failing the whole step.
3. Pass `labels` in the same **`issue_write`** call as assignee (one update is enough).

**Do not add by default:**

- **`translate`** — applied automatically by `.github/labelling.yml` after the PR is opened.
- **`auto-merge`** — only when the user explicitly asks.

**User overrides:** Extra labels (“add label auto-merge”), replace mapping, or skip labels only.

#### Example `issue_write` call

```json
{
  "method": "update",
  "owner": "LYCC",
  "repo": "flava-console",
  "issue_number": 6933,
  "assignees": ["ted-khoa"],
  "labels": ["bug"]
}
```

If assignee or labels fail (permissions, invalid username), report the error to the user but **do not** delete the PR — the PR from step 6 still stands.

### 8. Link the PR on the Jira ticket — remote link (Jira MCP, preferred for **Issue Links**)

Try to associate the PR so it can appear under the ticket’s **Issue Links** block (Git host label, **`LYCC/flava-console#NNNN`** style, PR title). That association is a **remote issue link** (REST **`POST /rest/api/3/issue/{issueKey}/remotelink`**, `object.url` + `object.title`). It is **not** the same as **`jira_create_issue_link`** (issue ↔ issue only).

1. **Skip** for **NO-JIRA**.

2. **Discover the right MCP tool first**  
   Inspect the Jira MCP tool list/descriptors for anything that creates **remote issue links** / **web links** / **GitHub PR links** (typically wrapping **`…/remotelink`**). **If it exists**, call it with **issue_key**, PR **`html_url`**, and PR **title**.

3. **If there is no remote-link tool** (minimal MCP installs often omit it):  
   - Use **`jira_search_fields`** (keywords such as `pull`, `merge`, `repository`, `URL`, `GitHub`) to find a **writable** custom field your team uses for PR URLs.  
   - Confirm with **`jira_get_issue`** on an issue that already shows a PR under **Issue Links** — note which **`customfield_*`** holds the URL, if any.  
   - Call **`jira_update_issue`** with `fields: { "<that_field_id>": "<pr_html_url>" }` only when step 2 confirms that pattern.

4. **Do not** try to “paste” the PR into **`customfield_10000`** (**Development** / `devsummary`) via **`jira_update_issue`** — on Workers Hub Jira that field is the development-integration summary type and is **not** set like a plain URL text box.

5. **`jira_create_issue_link`** links **issue ↔ issue** only — **never** for PR URLs.

6. **Comments are not a substitute for remote links** — a Jira **comment** (§9) makes the PR visible in **activity**; it does **not** replace a remotelink for the **Issue Links** UI. Do §8 when tooling allows; always still do §9 for traceability unless the user opts out.

7. **When Git integration already works**: After push/open PR, the link may appear automatically under **Issue Links** or **Development**. If the PR is already listed, skip redundant remotelink writes; **still** do §9 for **commit-derived** keys if those issues have no recent comment with this PR URL.

### 9. Add the PR to the ticket — Jira **comment** (only after the PR is created)

**Order:** Step **6** must finish successfully (you have the real PR URL) **before** any `jira_add_comment`. Never comment with a PR link before the PR exists.

**One comment per ticket — no duplicates:** For each issue key, call **`jira_add_comment` at most once** for this PR. Do **not** also paste the same PR URL inside **`jira_transition_issue`**’s `comment` argument; Jira will open a **second** activity entry and reviewers see duplicate noise (see **§10**).

Comment **only** on Jira issues that this PR **actually works on per git history** — i.e. issue keys present in **commit subject lines** on the branch being merged, not every ticket you mentioned in the PR markdown.

1. **Collect keys from commits**  
   Run something like `git --no-pager log --format=%s <base>..<head>` (e.g. `origin/main..HEAD`) and parse **unique** keys matching your commitlint ticket pattern, e.g. `(LYCC|CLOUDQA)-[0-9]+` in the **subject** (after `type(scope): `).  
   - **Ignore** `NO-JIRA` for commenting (skip that “ticket”).  
   - **Do not** add comments solely because a key appears in the **branch name** or in the **PR body’s JIRA section** if that key never appears in any merged commit subject — those are for human reviewers; automation would spam the wrong issues (e.g. branch `LYCC-10663` while commits only reference `LYCC-10007` and `LYCC-9774`).

2. **If no ticket keys** appear in any commit subject (all `NO-JIRA` or unparsable), **skip** §9 and **§10** unless the user explicitly names keys to notify (comments / transitions apply only to those keys if provided).

3. For **each** key from step 1, call **`jira_add_comment` exactly once** with a short body that includes the **full PR URL** (and optional PR title). Use one consistent template, for example:

   ```text
   Pull request opened: <paste full PR URL here>

   <PR title as one line, optional>
   ```

4. Keep comments minimal — no full PR description.

5. **User override**: If the user says “comment on LYCC-XYZ too”, add that key even if not in commits.

6. **Opt out / partial opt-out:**  
   - **No Jira at all** (e.g. “PR only”, “don’t touch Jira”): **skip §9** and **§10** (step **§7** assign/labels still runs unless user also opted out of that).  
   - **Comment only, no status change** (e.g. “don’t change Jira status”, “leave ticket open after PR link”): run **§9**, **skip §10**.

### 10. Transition Jira status — **default**, **after** §9 only

**Default behavior:** For **each issue key** that received a **`jira_add_comment` in §9** (commit-derived or user-override keys), transition the ticket **immediately after** that comment succeeds — **unless** the user opted out of status changes (see §9 step 6, “Comment only”).

1. **Prerequisite:** Step **9** has completed for that key. Do **not** transition before the PR exists and the comment step has run (unless the user clearly wants otherwise).

2. **No duplicate PR comment:** Call **`jira_transition_issue`** with **`comment` omitted / null**. Do not pass a second message that repeats the PR URL or “PR opened: …”.

3. **If Jira rejects the transition without a comment:** Use a **non-duplicate** one-liner that does **not** include the PR link (e.g. “Status update per workflow; PR link is in the previous comment.”). Never re-post the PR URL here.

4. **Which transition (default order):** Call **`jira_get_transitions`**. Prefer, in order: (**a**) a transition named **`In Review`**, (**b**) if missing, **`In Progress`**, (**c**) if the user named a target status in the chat, that name. If the ticket is **already** in the target status (e.g. already **In Review**), **skip** transition for that key. If none apply, **skip** transition and list available transition **names** in the summary to the user. **Do not** transition to **`Resolved`** by default — that status is for after merge/QA sign-off, not when opening a PR.

5. Set **`fields`** (e.g. resolution) only when the transition screen requires it **and** the MCP allows it.

### 11. Confirm to the user

Share the **PR URL**. Report separately:

- **Assignee** set (username) or skipped (opt-out / error)
- **Labels** applied (e.g. `bug`, `enhancement`) or skipped — note that `translate` may appear shortly via automation
- Whether **remote link / Issue Links** (§8) succeeded or was skipped
- Which **issue keys** received **one** **Jira comment** (§9, commit-derived set unless overridden) or that Jira was skipped by user request
- **Status transitions** (§10) applied after commenting, or skipped (opt-out, no eligible transition, or error)

Ask them to confirm **Issue Links** on the ticket when applicable.

### 12. Optional post-create review (advisory, report-only) — DEFAULT OFF

Chain the **`flava-review-pr`** skill on the PR just created. **Opt-in only** — do **not** run automatically on every PR. If the user just said "create a PR", finish at §11 and add **one line** noting this option exists ("Say 'review this PR' for an advisory self-review.") — then STOP.

**When to run (opt-in triggers):** "review after PR", "create PR and review", "self-review this PR", or similar.
**Opt-out (skip §12 entirely):** "PR only", "no review", "skip review".

**How:** invoke **`flava-review-pr`** on the **PR number from §6**. It re-fetches the PR, detects the product(s), runs jira-check + generic Flava code-rules + the real lint / type:check / build gates, and writes its HTML report — reference that skill, don't duplicate its logic here.

**Output:** show the review **verdict + findings summary + HTML report path** in chat, then **STOP**. The user decides what to do next.

**Hard rules:**
- Do **NOT** auto-fix any finding. Report only. Fixing a finding is a separate, explicit request.
- Do **NOT** auto-post the review to GitHub. `flava-review-pr`'s own ask-before-post gate is preserved — it asks separately; running §12 is not consent to post.
- Objective gate failures (lint / type:check / build fail) → call out clearly as **"fix before merge"**, but still do **not** auto-fix.

## Example PR

**Title**: `fix(lb): CLOUDQA-83781: Fix pagination and remove debug logs`

**Body**:

```markdown
## Summary

Fixes instance list pagination by converting `pageNum`/`pageSize` to `limit`/`offset` parameters expected by the upstream API, and removes debug logging that was added during bug investigation.

## JIRA Ticket

[CLOUDQA-83781](https://jira.workers-hub.com/browse/CLOUDQA-83781)

## Root Cause

The BFF was forwarding `pageNum` and `pageSize` query parameters directly to the upstream LB API, which expects `limit` and `offset` for pagination. Debug logs were temporarily added to trace the issue and need cleanup.

## Changes

1. **BFF Instance Service** (`bff/src/modules/instance/instance.service.ts`)
   - Convert `pageNum`/`pageSize` to `limit`/`offset` before forwarding to upstream API
2. **BFF App Service** (`bff/src/app.service.ts`)
   - Remove all `logger.debug` calls from endpoint resolution methods
   - Simplify return statements where temp variables were only used for debug logging
3. **BFF Middleware** (`bff/src/middleware/`)
   - Remove `logger.debug` calls from `TokenMiddleware`, `OpenstackTokenMiddleware`, and `AuthorizedTokenMiddleware`
   - Preserve `logger.error` calls in catch blocks

## Test Plan

- Verify instance list pagination works correctly with the converted parameters
- Confirm no debug logs appear in BFF output during normal operation
- Error logging still works when token exchange fails
```

## Edge Cases

- **No ticket found**: If the ticket ID can't be determined from branch name or commits, ask the user before proceeding.
- **Multiple scopes**: If changes span multiple products, use `all` as the scope.
- **Draft PR**: If the user says "draft PR" or "WIP", set `draft: true` in **`create_pull_request`**. Still assign and label unless opted out.
- **Existing PR**: Use **`list_pull_requests`** / **`search_pull_requests`** before **`create_pull_request`**; if a PR exists for the branch, inform the user instead of creating a duplicate. Optionally run **§7** on the existing PR if assignee/labels are missing.
- **Assignee fails**: Invalid username or missing repo permission — tell the user; they can assign manually in the PR UI.
- **Unknown label**: `get_label` 404 — skip that label; do not invent label names.
- **`gh` unavailable or user mentions `gh`**: Do not use `gh`. Use GitHub MCP only; explain that this repo lives on `git.linecorp.com`, not `github.com`.
- **GitHub MCP unavailable**: Stop after push; tell the user to enable/fix `user-github` MCP or open the PR manually on `git.linecorp.com`.
- **Jira MCP cannot remotelink**: If no remote-link tool exists and no writable PR URL field is documented for LYCC, tell the user to add **`POST .../remotelink`** to the Jira MCP (or use Jira UI **Link** → web/GitHub PR so **Issue Links** shows **`repo#NNNN`**). **Still post one PR comment per ticket** via **`jira_add_comment`** (§9) for **commit-derived** ticket keys only — never duplicate that link in **`jira_transition_issue`** (§10).
- **Duplicate Jira comments**: If you see two comments with the same PR link, you combined §9 with a transition `comment` that repeated the URL. Fix the automation: **§9 only** announces the PR; **§10** transitions without repeating it.
- **Opt out of Jira**: **“PR only”** / **“don’t touch Jira”** → **skip §9 and §10** (still open the PR in §6; **§7** assign/labels still runs unless user also said no assign/labels). **“Don’t change Jira status”** / **comment only** → **§9 yes, §10 no**.
- **Opt out of assign/labels**: **“don’t assign me”** / **“no labels”** → skip the relevant part of **§7** only.
