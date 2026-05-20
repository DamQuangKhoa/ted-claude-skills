---
name: flava-sentry-check
description: Deep-dive a single Sentry issue for Flava Console using Sentry MCP—fetch issue and events, map to code, produce root cause and a concrete fix plan. Use when the user pastes a Sentry issue URL, a short issue id like FLAVA-CONSOLE-*-CLIENT-#, says "check this Sentry", "analyze Sentry issue", "Sentry RCA", "why is PROJECT-XYZ failing", `/sentry-check`, or wants a repair plan driven by telemetry before coding. **Always open this skill** for one-off Sentry investigations in this repo instead of improvising—you must verify MCP first; if unavailable, stop and send them to FE3 docs (linked below). Matches flava-console org defaults (ly).
---

# Flava Sentry Check

Use **Sentry MCP** plus the **flava-console** codebase to understand one issue end-to-end: what Sentry sees, where it originates in source, root cause hypotheses, verification steps, and a **fix plan** (file-level).

**Approval gate:** After you share root cause analysis, plan, and todos, **do not edit code or run formatting refactors** until the user **explicitly asks to implement** (e.g. “go ahead”, “apply the plan”, “fix it now”). “OK” alone is ambiguous—confirm if needed.

---

## 0. MCP pre-flight

Before touching Sentry data:

1. Confirm the **Sentry MCP** (`user-sentry` or equivalent) is present and tools like `whoami`, `find_organizations`, **`get_sentry_resource`**, and **`list_issue_events`** are available (read MCP tool schemas from the descriptor folder before calling).
2. Smoke-check: call **`whoami`** (read schema first). If missing, unauthorized, or connection errors repeatedly → **stop**.

**Blocked state:** Tell the user Sentry MCP is required, and point them to **[FE3 · AI · Sentry Integration Guide](https://wiki.workers-hub.com/display/LVN/FE3+-+AI+-+Sentry+Integration+Guide)** (`https://wiki.workers-hub.com/display/LVN/FE3+-+AI+-+Sentry+Integration+Guide`). Do **not** fabricate stacks, fingerprints, or event counts.

---

## 1. Normalize the user input

Accept any of:

- Full **issue URL** (preferred): `https://ly.my.sentry.io/organizations/ly/issues/<SHORT_OR_NUMERIC>/`
- Short **issue id** (examples: `FLAVA-CONSOLE-SHELL-CLIENT-30`, `FLAVA-CONSOLE-OVERVIEW-CLIENT-1`)
- Partial paste from triage docs (strip markdown; keep the canonical id)

**Flava defaults** (unless the user overrides):

| Field | Default |
|--------|---------|
| `organizationSlug` | `ly` |
| `regionUrl` | Often `https://ly.my.sentry.io` — confirm via `find_organizations` / issue URL hostname if unsure |

---

## 2. Fetch issue details (Sentry MCP)

**Always read tool schemas immediately before invoking.**

Suggested order:

1. **`get_sentry_resource`** — Primary envelope for the issue.
   - If the user gave a URL: pass `url=...`. If that fails parsing, retry with explicit `resourceType='issue'`, `organizationSlug`, `resourceId` (short id).
   - Capture: title, culprit, counts, environments, releases, regression metadata, grouping, permalink.
2. **`list_issue_events`** — Recent events inside the issue (adjust `statsPeriod`, `limit`, filters). Use stack traces and breadcrumbs here when the envelope is thin.
3. **`list_issues`** — Only when you cannot resolve metadata by URL/id (e.g. narrow by `issue:`/`shortId`-style queries per Sentry docs for your MCP version)—do not spam wide queries without need.

Cross-check **release / dist / filenames** hints against **source maps**: minified filenames may mention `app`/chunk IDs—combine with breadcrumbs and culprit route names.

**Seer (`analyze_issue_with_seer`):** Optional. Per tool guidance, **do not** call automatically after `get_sentry_resource`. Use only when **the user explicitly asks** for Seer / AI RCA, or when normal evidence is insufficient **and** the user agrees to the slower/analysis path after you explain.

---

## 3. Root cause analysis in repo

Treat Sentry clues as hypotheses; verify against code.

Search tactics (examples):

| Signal | Repo action |
|--------|--------------|
| Error text / assertion | `grep` exact message in `apps/`, `shared/` |
| Route / culprit string | Locate Vue routes, loaders, breadcrumbs |
| BFF/project prefix in slug | Narrow to matching `apps/product-*/bff` / `apps/product-*/client` |
| Component name in stack | Find SFC/composable |
| Repeated API spans | Inspect TanStack/query hooks + batching |

This monorepo is large—**scope to the emitting product** inferred from issue project slug (`flava-console-<product>` naming) unless evidence points to **flava-shell** shared code.

Record:

- Likely failing layer (micro-frontend shell vs remote vs BFF vs third-party snippet).
- Data assumptions (null/undefined, validator missing, routing param omission).
- Regress risk and blast radius.

---

## 4. Deliverables

Structure the reply so reviewers can skim:

1. **Issue summary** — id, permalink, severity/volume shorthand, culprit, environments.
2. **What Sentry shows** — 2–6 bullets citing concrete fields (titles, culprit, breadcrumb cues)—no secrets.
3. **Code mapping** — key files/functions with short rationale.
4. **Root cause** — one concise paragraph plus bullet proof points.
5. **Fix plan** — ordered steps, files to touch, test ideas (`pnpm --filter … run …` scoped to touched packages).
6. **Todos** — small verifiable checklist.
7. **Stop for implementation** unless the user already explicitly requested code changes before you started—then reconcile before editing.

Git branch naming is **team choice** unless the ticket links to Jira (`LYCC-xxxx` workflows may use ticket branches separately). Optionally suggest something like `sentry/<normalized-issue-short-id>` **only when useful**—do not contradict team branch rules already in other skills.

---

## 5. Out of scope

- No `.env`/token/DSN scraping; no MCP secrets pasted into chat output.
- **No** silently closing or resolving the issue via `update_issue` unless the user explicitly asks—and even then summarize what status change means.
- **No** rewriting unrelated products or drive-by cleanup while “fixing” the issue unless approved.

---

## 6. Optional cross-links

- **Bulk unresolved triage rollups / Confluence reports:** use **`flava-sentry-triage`** (`.cursor/skills/flava-sentry-triage/`) instead of this single-issue checklist.
