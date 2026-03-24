---
name: flava-commit-skill
description: Generate and execute git commits following the LYCC flava-console commitlint conventions. Use whenever the user asks to "commit", "write a commit message", "prepare a commit", "commit my changes", or mentions committing staged changes — even if they don't say "LYCC" or "commitlint". The format is "type(scope): TICKET-ID: Sentence case description". This skill knows every valid scope, type, ticket pattern, and linting rule so commits pass commitlint on the first try.
---

# Flava Commit Skill

Generate and execute git commits that pass the project's commitlint (`commitlint.config.js` at the monorepo root, extending `@commitlint/config-conventional`).

## Commit Format

```
type(scope): TICKET-ID: Sentence case description
```

The full header (type + scope + ticket + description) must be **≤ 100 characters**.

## Types

Use the conventional-commits types. Pick the one that best describes the _intent_ of the change:

| Type       | When to use                                                  |
| ---------- | ------------------------------------------------------------ |
| `feat`     | New feature or enhancement                                   |
| `fix`      | Bug fix or error correction                                  |
| `refactor` | Code restructuring without behavior change                   |
| `chore`    | Maintenance, dependency bumps, config tweaks                 |
| `docs`     | Documentation only                                           |
| `style`    | Formatting, whitespace, missing semicolons (no logic change) |
| `test`     | Adding or updating tests                                     |
| `perf`     | Performance improvement                                      |
| `build`    | Build system or external dependency changes                  |
| `ci`       | CI/CD pipeline changes                                       |
| `revert`   | Reverting a previous commit                                  |

## Scopes (enforced by commitlint)

The scope **must** be one of these values — anything else will fail the lint:

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

To pick the right scope, look at which `apps/product-*` or `packages/*` directory the changes live in. If changes span multiple products, use `all`. If only `bff/` or `client/` within a single product changed, use the product scope (e.g. `lb` not `bff`).

## Ticket ID

Immediately after `type(scope): `, include one of:

- **LYCC-XXXX** — the JIRA ticket number (most common)
- **CLOUDQA-XXXXX** — for QA-originated tickets
- **NO-JIRA** — only when there is genuinely no ticket

If the user hasn't mentioned a ticket, check the current branch name — it often contains the ticket ID (e.g. `feat/LYCC-1234-something`). If you still can't determine it, ask the user.

## Description (subject)

- **Sentence case** (first letter uppercase, rest lowercase unless proper noun) — enforced by commitlint `subject-case` rule
- Start with an action verb: Add, Update, Fix, Remove, Implement, Refactor, Migrate, etc.
- No trailing period
- Be specific about _what_ changed, not _how_

## Process

1. **Check current state**

   - Run `git status` to see staged/unstaged changes
   - Run `git diff --cached --stat` for a summary of staged changes
   - If nothing is staged, run `git diff --stat` to see what could be staged

2. **Determine scope** from the changed file paths (map to valid scope above)

3. **Determine type** from the nature of the change

4. **Get ticket ID** — from user, branch name, or ask

5. **Compose the message** — verify it's ≤ 100 chars and sentence-case

6. **Stage if needed** — if the user wants to commit unstaged files, stage them (skip `.env`, credentials, secrets)

7. **Commit** — run `git commit -m "message"` and verify success

## Examples

```
feat(lb): LYCC-8687: Add network LB detail overview page
fix(mcp-hub): CLOUDQA-83659: Fix the style of manual config
refactor(api-gateway): LYCC-9430: Switch config actions to useModalManager flow
chore(api-gateway): LYCC-9430: Use in-development flava-ui
feat(service-connect): NO-JIRA: Open menu for traffic director in stage
feat(container-registry): NO-JIRA: Disable actions when no retention ID or rules data is available
```
