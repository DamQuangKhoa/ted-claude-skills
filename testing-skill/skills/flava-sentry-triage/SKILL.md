---
name: flava-sentry-triage
description: Run the Flava Console recurring Sentry triage workflow (list unresolved stage issues for flava-console-* in org ly, classify A–D, optional Confluence report matching the April-style storage template). Use when the user says /sentry-triage, “sentry triage”, “Flava Console Sentry issues”, “weekly Sentry triage”, “update the Sentry wiki report”, “categorize unresolved Sentry”, or wants stage-environment issue rollups before Jira/PR work. **Always use this skill first** for that work so you verify MCP before burning time on partial triage—if Sentry MCP is missing or broken, stop and point them at the FE3 integration wiki (link in body). Triggers even when the user only says “triage Sentry” without naming Flava.
---

# Flava Sentry Triage

Orchestrate triage of **Flava Console** Sentry issues (`flava-console-*` projects, org **`ly`**) and optionally publish a structured Confluence page that mirrors the **April 2026-style** report (summary table with Performance row, category tables, recommended actions, previous reports, footer).

---

## 0. MCP pre-flight (mandatory; do this before Sentry API work)

**Goal:** Confirm the **Sentry MCP** is configured and responsive. If the agent cannot use Sentry MCP tools, **do not** pretend to triage from memory or guess counts.

### 0a. Discover whether Sentry MCP is available

1. **Prefer:** Check the MCP tool descriptors for a Sentry server (in Cursor this often appears as **`user-sentry`**) under your workspace MCP tools folder—look for tools such as `whoami`, `find_organizations`, `list_issues`.
2. **If descriptors are missing** or the server is not listed → treat as **not installed** (go to **0c**).

### 0b. Smoke-check auth / connectivity

Before large queries:

- Read the **`whoami`** (or equivalent) tool schema, then call it **once**.
- **Success:** Continue to §1.
- **Failure** (tool missing, “not configured”, authorization expired, repeated 401/403, connection errors): go to **0c**—do **not** continue with triage steps.

### 0c. Stop and ask the user to configure MCP

**Do not** invent issue lists, counts, or URLs. Output a short, actionable message:

1. Explain that **Sentry MCP** is required for this workflow.
2. Ask them to configure it using the team guide: **[FE3 · AI · Sentry Integration Guide](https://wiki.workers-hub.com/display/LVN/FE3+-+AI+-+Sentry+Integration+Guide)** (`https://wiki.workers-hub.com/display/LVN/FE3+-+AI+-+Sentry+Integration+Guide`).
3. After they confirm MCP works, they can re-run the triage request.

**Optional publishing:** If the user wants **Confluence** updates, check for **`user-confluence`** (or your project’s Confluence MCP) the same way—if absent, say Confluence publish is blocked until that MCP is configured (the FE3 page may cover related setup; if not, use your team’s Confluence MCP docs).

---

## 1. Scope and defaults

| Item | Default |
|------|--------|
| **Sentry org** | `ly` |
| **Region / host** | `https://ly.my.sentry.io` (verify via `whoami` / org lookup if needed) |
| **Projects** | All `flava-console-*` clients/BFFs relevant to the cohort |
| **Environment** | **`stage`** unless the user specifies another |
| **Query note** | Org-wide `list_issues` may be required—**`project:flava-console-*` can be invalid** in some MCP/API paths; don’t fail silently: adjust query (e.g. org-wide filtered list) and document what you used in the report |

If the user passes a different org, environment, or date for the report title, follow their parameters but keep the same **classification** model.

---

## 2. Pull issues

1. Read **`list_issues`** tool schema (Sentry MCP) before calling.
2. Fetch **unresolved** issues for the chosen environment (typically `is:unresolved environment:stage`). Use pagination as supported.
3. Record **total count** and stash **short issue id**, **title**, **culprit**, **event/user counts**, and **permalink** for each row to be classified.

**Safety:** Do **not** bulk auto-resolve **prod-only** noise from a **stage** cohort unless the user explicitly orders it and understands impact.

---

## 3. Classification (A–D + performance callout)

Use the same **meaning** as historical Flava triage pages (tune wording to match the latest Confluence template):

| Category | Meaning (short) |
|----------|------------------|
| **A** | Actionable **front-end** bugs (routing, validation, null deref, duplicated client patterns, Sentry **N+1** on client-driven API sequences, etc.) |
| **B** | **API / BFF / backend** failures or payload shape bugs |
| **C** | **External / environmental / instrumentation** (HTTP/1.1 overhead, localhost dev, analytics third-party, blocked SDK, port bind noise, etc.) |
| **D** | **Stale / already fixed / safe to resolve** (only if you have evidence; default to *no* bulk resolve this pass) |

**Performance row (summary table):** Call out **N+1** and **HTTP overhead**-style rows explicitly in the summary (counts and where they landed in A vs C), matching the **[2026-04-16 sample](https://wiki.workers-hub.com/display/LVN/Flava+Console+-+Sentry+Triage+-+2026-04-16)** layout.

---

## 4. Report output (when Confluence is requested)

**Indexing:** Parent hub is typically **“Flava Console - Sentry Issues”**; child pages are dated **“Flava Console - Sentry Triage - YYYY-MM-DD”**.

**Body format:** Prefer **Confluence storage HTML** to match the April report: intro, **Summary** table (include **Performance** row), **Category A–D** tables with consistent columns, **Recommended actions**, **Previous triage reports** (link to last page), footer (generation date, Slack channel **`#pj-flava-console-alert`** if that’s still team practice).

**Publishing:** Use Confluence MCP **`confluence_update_page`** (read schema first). If the payload is large, shorten **repeated** boilerplate cells (e.g. many identical `&lt;unknown&gt;` analyses) **without** dropping rows or links—keep every **issue link** and numeric counts accurate.

**Hub row:** Update the parent triage index table with **date**, **issue total**, **A/B/C/D breakdown**, and notes (e.g. perf-related count, no bulk resolve).

---

## 5. Deliverables to the user

After a successful run, summarize:

1. **Total unresolved** (environment, query used).
2. **A/B/C/D counts** (+ performance-related count if tracked separately).
3. **Top 3–5 themes** (with example short issue ids).
4. **Confluence URLs** (child + parent) if published.
5. Reminder to **post or link in `#pj-flava-console-alert`** if that’s the team norm.

If MCP was missing: only **§0c**—link the **FE3 wiki**, no fabricated numbers.

---

## 6. Out of scope

- **No** reading or pasting `.env`, tokens, or DSN secrets into the report.
- **No** code fixes unless the user explicitly asks for implementation after triage (route that to normal product work / tickets).
- **No** claiming “Sentry is down” without an actual error from MCP or Sentry.

---

## 7. References (human)

- **Configure Sentry MCP:** [FE3 · AI · Sentry Integration Guide](https://wiki.workers-hub.com/display/LVN/FE3+-+AI+-+Sentry+Integration+Guide)
- **Report layout example:** [Flava Console - Sentry Triage - 2026-04-16](https://wiki.workers-hub.com/display/LVN/Flava+Console+-+Sentry+Triage+-+2026-04-16)
