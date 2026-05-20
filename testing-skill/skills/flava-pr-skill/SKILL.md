---
name: flava-pr-skill
description: Create pull requests for the LYCC flava-console project using **GitHub MCP only** (never `gh` CLI). Use whenever the user asks to "create a PR", "open a PR", "make a pull request", "submit my changes for review", or mentions pushing and creating a pull request. This skill knows the PR template format, how to extract context from commits and branch names, how to compose well-structured PR descriptions with Summary, JIRA Ticket, Root Cause, Changes, and Test Plan sections, how to link the PR on Jira (remote link / `remotelink` when available — not `jira_create_issue_link`). **By default** (unless the user opts out): after the PR exists, **post exactly one Jira comment per commit-derived ticket** with the PR URL, **then transition that ticket** (default target **Resolved** when the workflow allows). Never duplicate the PR link in `jira_transition_issue`'s `comment`. Opt-out examples: "PR only", "don't comment Jira", "don't change Jira status", "leave ticket open".
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
- **Ticket IDs for Jira comments (step 8)**: see **§8** — use **commit messages only**, not the branch name or optional extra links in the PR description unless the user explicitly tells you to comment on additional keys.
- **Jira after PR (default):** Unless the user opts out, run **§8** (one PR comment per commit-derived key) **then** **§9** (status transition). **§9** always runs **after** §8 for the **same** keys. Do not put the PR URL in **`jira_transition_issue`**’s `comment`.
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

### 4. Compose the PR body

Write each section following the template above. Guidelines:

- **Summary**: Concise — what does this PR accomplish from a user/reviewer perspective?
- **JIRA Ticket**: One markdown link per ticket using `https://jira.workers-hub.com/browse/<KEY>` (see **JIRA ticket links** above). Do not leave the key as plain text only.
- **Root Cause**: Explain _why_ the change is needed. For bug fixes, describe the bug mechanism. For features, describe what gap existed. Omit this section entirely for trivial changes (typos, dependency bumps, config tweaks).
- **Changes**: Numbered list. Group by area (e.g. "BFF", "Client", or by module). Include file paths when helpful. Each item should be a complete sentence.
- **Test Plan**: Be specific. "Tested locally" is OK but add details. Reference test commands if relevant (`npm run test`, `npm run test:unit`). For UI changes, describe the manual verification steps.

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
   | **body** | Full markdown PR body |
   | **head** | Current branch name |
   | **base** | `main` (or user-specified) |
   | **draft** | `true` only if user asked for draft/WIP |

3. **Capture the PR URL** from the MCP response (`url` field). Do **not** guess or construct the link from memory.

4. **If MCP fails:** Report the error and stop — do **not** fall back to `gh`. Ask the user to fix MCP auth or create the PR manually on `git.linecorp.com`.

### 7. Link the PR on the Jira ticket — remote link (Jira MCP, preferred for **Issue Links**)

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

6. **Comments are not a substitute for remote links** — a Jira **comment** (step 8) makes the PR visible in **activity**; it does **not** replace a remotelink for the **Issue Links** UI. Do step 7 when tooling allows; always still do step 8 for traceability unless the user opts out.

7. **When Git integration already works**: After push/open PR, the link may appear automatically under **Issue Links** or **Development**. If the PR is already listed, skip redundant remotelink writes; **still** do step 8 for **commit-derived** keys (§8) if those issues have no recent comment with this PR URL.

### 8. Add the PR to the ticket — Jira **comment** (only after the PR is created)

**Order:** Step **6** must finish successfully (you have the real PR URL) **before** any `jira_add_comment`. Never comment with a PR link before the PR exists.

**One comment per ticket — no duplicates:** For each issue key, call **`jira_add_comment` at most once** for this PR. Do **not** also paste the same PR URL inside **`jira_transition_issue`**’s `comment` argument; Jira will open a **second** activity entry and reviewers see duplicate noise (see **§9**).

Comment **only** on Jira issues that this PR **actually works on per git history** — i.e. issue keys present in **commit subject lines** on the branch being merged, not every ticket you mentioned in the PR markdown.

1. **Collect keys from commits**  
   Run something like `git --no-pager log --format=%s <base>..<head>` (e.g. `origin/main..HEAD`) and parse **unique** keys matching your commitlint ticket pattern, e.g. `(LYCC|CLOUDQA)-[0-9]+` in the **subject** (after `type(scope): `).  
   - **Ignore** `NO-JIRA` for commenting (skip that “ticket”).  
   - **Do not** add comments solely because a key appears in the **branch name** or in the **PR body’s JIRA section** if that key never appears in any merged commit subject — those are for human reviewers; automation would spam the wrong issues (e.g. branch `LYCC-10663` while commits only reference `LYCC-10007` and `LYCC-9774`).

2. **If no ticket keys** appear in any commit subject (all `NO-JIRA` or unparsable), **skip** §8 and **§9** unless the user explicitly names keys to notify (comments / transitions apply only to those keys if provided).

3. For **each** key from step 1, call **`jira_add_comment` exactly once** with a short body that includes the **full PR URL** (and optional PR title). Use one consistent template, for example:

   ```text
   Pull request opened: <paste full PR URL here>

   <PR title as one line, optional>
   ```

4. Keep comments minimal — no full PR description.

5. **User override**: If the user says “comment on LYCC-XYZ too”, add that key even if not in commits.

6. **Opt out / partial opt-out:**  
   - **No Jira at all** (e.g. “PR only”, “don’t touch Jira”): **skip §8** and **§9**.  
   - **Comment only, no status change** (e.g. “don’t change Jira status”, “leave ticket open after PR link”): run **§8**, **skip §9**.

### 9. Transition Jira status — **default**, **after** §8 only

**Default behavior:** For **each issue key** that received a **`jira_add_comment` in §8** (commit-derived or user-override keys), transition the ticket **immediately after** that comment succeeds — **unless** the user opted out of status changes (see §8 step 6, “Comment only”).

1. **Prerequisite:** Step **8** has completed for that key. Do **not** transition before the PR exists and the comment step has run (unless the user clearly wants otherwise).

2. **No duplicate PR comment:** Call **`jira_transition_issue`** with **`comment` omitted / null**. Do not pass a second message that repeats the PR URL or “PR opened: …”.

3. **If Jira rejects the transition without a comment:** Use a **non-duplicate** one-liner that does **not** include the PR link (e.g. “Status update per workflow; PR link is in the previous comment.”). Never re-post the PR URL here.

4. **Which transition (default order):** Call **`jira_get_transitions`**. Prefer, in order: (**a**) a transition named **`Resolved`**, (**b**) if missing, **`In Review`**, (**c**) if the user named a target status in the chat, that name. If none apply, **skip** transition for that key and list available transition **names** in the summary to the user.

5. Set **`fields`** (e.g. resolution) only when the transition screen requires it **and** the MCP allows it.

### 10. Confirm to the user

Share the **PR URL**. Report separately: (a) whether **remote link / Issue Links** step succeeded or was skipped, (b) which **issue keys** received **one** **Jira comment** (commit-derived set unless overridden) or that Jira was skipped by user request, and (c) **default** **status transitions** applied after commenting (or that transitions were skipped — opt-out, no eligible transition, or error). Ask them to confirm **Issue Links** on the ticket when applicable.

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
- **Draft PR**: If the user says "draft PR" or "WIP", set `draft: true` in **`create_pull_request`**.
- **Existing PR**: Use **`list_pull_requests`** / **`search_pull_requests`** before **`create_pull_request`**; if a PR exists for the branch, inform the user instead of creating a duplicate.
- **`gh` unavailable or user mentions `gh`**: Do not use `gh`. Use GitHub MCP only; explain that this repo lives on `git.linecorp.com`, not `github.com`.
- **GitHub MCP unavailable**: Stop after push; tell the user to enable/fix `user-github` MCP or open the PR manually on `git.linecorp.com`.
- **Jira MCP cannot remotelink**: If no remote-link tool exists and no writable PR URL field is documented for LYCC, tell the user to add **`POST .../remotelink`** to the Jira MCP (or use Jira UI **Link** → web/GitHub PR so **Issue Links** shows **`repo#NNNN`**). **Still post one PR comment per ticket** via **`jira_add_comment`** (step 8) for **commit-derived** ticket keys only — never duplicate that link in **`jira_transition_issue`** (step 9).
- **Duplicate Jira comments**: If you see two comments with the same PR link, you combined step 8 with a transition `comment` that repeated the URL. Fix the automation: **§8 only** announces the PR; **§9** transitions without repeating it.
- **Opt out of Jira**: **“PR only”** / **“don’t touch Jira”** → **skip §8 and §9** (still open the PR in §6). **“Don’t change Jira status”** / **comment only** → **§8 yes, §9 no**.
