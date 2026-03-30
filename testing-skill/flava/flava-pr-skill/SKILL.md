---
name: flava-pr-skill
description: Create pull requests for the LYCC flava-console project using GitHub MCP tools. Use whenever the user asks to "create a PR", "open a PR", "make a pull request", "submit my changes for review", or mentions pushing and creating a pull request — even if they don't explicitly say "GitHub MCP". This skill knows the PR template format, how to extract context from commits and branch names, and how to compose well-structured PR descriptions with Summary, JIRA Ticket, Root Cause, Changes, and Test Plan sections.
---

# Flava PR Skill

Create pull requests for the LYCC flava-console monorepo via GitHub MCP tools. The PR description follows a structured template that gives reviewers clear context on what changed, why, and how to verify.

## PR Description Template

```markdown
## Summary

[1-2 sentence high-level description of the change]

## JIRA Ticket

[Markdown link to Jira — see § JIRA ticket links below]

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
- **Ticket ID**: extract from branch name, commit messages, or ask the user
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

### 6. Create the PR via GitHub MCP

Use the GitHub MCP `create_pull_request` tool (check the tool schema in the MCP descriptors):

- **owner**: parsed from git remote (e.g. `LYCC`)
- **repo**: parsed from git remote (e.g. `flava-console`)
- **title**: the composed PR title
- **body**: the composed PR body (full markdown)
- **head**: current branch name
- **base**: `main` (or whatever the user specifies)

### 7. Confirm to the user

After creation, share the PR URL and a brief summary of what was included.

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
- **Draft PR**: If the user says "draft PR" or "WIP", set `draft: true` in the create call.
- **Existing PR**: If a PR already exists for the branch, inform the user instead of creating a duplicate.
