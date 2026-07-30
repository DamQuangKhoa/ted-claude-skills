---
name: flava-sentry-triage
description: Run Flava Console Sentry triage for ONE environment per invocation (default stage; optional dev/prod). Classify A–D, publish via **Sentry + Confluence MCP only**. Includes **§7 operational playbook** (why DEV is hard, Confluence `<unknown>` fix, publish timeouts). One env per run. Never invent counts or URLs.
---

# Flava Sentry Triage

Orchestrate triage of **Flava Console** Sentry issues (`flava-console-*`, org **`ly`**) and publish **one environment’s** Confluence child page per skill invocation.

**Critical:** One run = **one** Sentry `list_issues` query + **one** env wiki child. Default environment is **`stage`**.

---

## 0. Required MCP pre-flight (mandatory — do this first)

**Goal:** Confirm **Sentry MCP** and **Confluence MCP** are installed, listed as available servers, and responsive. Do **not** fetch issues, classify, or draft wiki content until **both** smoke checks pass (unless the user explicitly opts out of Confluence in **0d**).

**Never** invent issue lists, counts, classifications, or Confluence URLs from memory.

### 0a. Required tools checklist

| MCP | Typical server id | Must exist in MCP tool descriptors | Smoke-test call |
|-----|-------------------|-------------------------------------|-----------------|
| **Sentry** | `user-sentry` | `whoami`, `list_issues` (read schemas before calling) | `whoami` |
| **Confluence** | `user-confluence` | `confluence_get_page`, `confluence_create_page`, `confluence_update_page` (read schemas before calling) | `confluence_get_page` with hub `page_id` below |

**Discover descriptors:** Under the workspace MCP tools folder, e.g. `mcps/user-sentry/tools/` and `mcps/user-confluence/tools/`. If a server folder is missing, only has `STATUS.md` with an error, or the server is **not** in the agent’s available MCP server list → treat that MCP as **not configured**.

Run Sentry and Confluence discovery **in parallel** when possible, then run smoke tests.

### 0b. Sentry smoke test

1. Read **`whoami`** schema, then call **`whoami`** once.
2. **Success** → Sentry MCP is ready (note org/region from response if present).
3. **Failure** (tool missing, server unavailable, “not configured”, **authorization expired**, 401/403, connection errors) → go to **0d** for Sentry. Do **not** call `list_issues`.

**Note:** `whoami` may fail while `list_issues` still works; if `whoami` fails, retry **`list_issues`** with `limit: 1` on org `ly` before stopping—document which smoke test passed in the report intro.

### 0c. Confluence smoke test

1. Read **`confluence_get_page`** schema, then fetch the triage **hub**:
   - **`page_id`:** `4007182380`
   - **Title:** Flava Console - Sentry Issues
   - **URL:** https://wiki.workers-hub.com/pages/viewpage.action?pageId=4007182380
2. **Success** → Confluence MCP is ready; use this page as parent for date rollup pages.
3. **Failure** → go to **0d** for Confluence. Do **not** call `confluence_create_page` / `confluence_update_page`.

### 0d. When to stop and ask the user to configure

If **either** smoke test fails (and Sentry fallback `list_issues` also fails), **stop** and reply with a short, actionable message.

**Sentry not ready:** [FE3 · AI · Sentry Integration Guide](https://wiki.workers-hub.com/display/LVN/FE3+-+AI+-+Sentry+Integration+Guide). For **authorization expired**, re-authenticate in Cursor Settings → MCP.

**Confluence not ready:** Enable/restart Confluence MCP in Cursor Settings (often `@linecorp/flava-mcp-connector`).

**User opt-out:** Skip Confluence only if they say **no wiki** / **Sentry only** / **counts only**. Still require Sentry.

### 0e. Proceed only when

- [ ] Sentry `whoami` **or** `list_issues` smoke succeeded  
- [ ] Confluence hub `confluence_get_page` succeeded **or** user opted out of wiki  
- [ ] Tool schemas read for `list_issues` and Confluence write tools  

Then continue to **§1**.

---

## 1. Resolve target environment (one per run)

### 1a. Default and parsing

| Priority | Rule |
|----------|------|
| **Default** | **`stage`** if the user does not name an environment |
| **Parse from message** | `stage`, `dev` / `development`, `prod` / `production` (Sentry tag is **`prod`**, not `production`) |
| **One run** | Triage and publish **only** the resolved environment |

**Examples**

| User says | Target env |
|-----------|------------|
| `/sentry-triage` | `stage` |
| `sentry triage` | `stage` |
| `sentry triage dev` | `dev` |
| `triage prod` | `prod` |

### 1b. Ask when helpful (do not block on stage default)

If the request is ambiguous (e.g. “run triage”, “update wiki”) and no env is implied, ask **once**:

> Which environment should I triage? **stage** (default) · **dev** · **prod**  
> Reply with one name, or press enter / say nothing to use **stage**.

If the user does not answer, proceed with **`stage`**.

### 1c. Do NOT do all environments in one run

| User request | Agent behavior |
|--------------|----------------|
| No env mentioned | **stage** only |
| `stage` / `dev` / `prod` | That env only |
| `all`, `all envs`, `stage dev prod` | **Do not** fetch or publish three full reports in one response. Reply: run the skill **three times** — e.g. `/sentry-triage stage`, then `dev`, then `prod` — or ask which env to do **first**. |

**Why:** Full May-11-style issue tables are large; Confluence MCP updates for three envs at once are unreliable. Sequential single-env runs are required.

### 1d. Scope table

| Item | Value |
|------|--------|
| **Sentry org** | `ly` |
| **Region / host** | `https://ly.my.sentry.io` |
| **Projects** | All `flava-console-*` rows in the cohort |
| **Confluence space** | `LVN` |
| **Confluence hub** | [Flava Console - Sentry Issues](https://wiki.workers-hub.com/pages/viewpage.action?pageId=4007182380) (`page_id` **4007182380**) |

| Resolved env | Sentry query | Child page title suffix |
|--------------|--------------|-------------------------|
| **`stage`** (default) | `is:unresolved environment:stage` | `Flava Console - Sentry Triage - YYYY-MM-DD - STAGE` |
| **`dev`** | `is:unresolved environment:dev` | `… - YYYY-MM-DD - DEV` |
| **`prod`** | `is:unresolved environment:prod` | `… - YYYY-MM-DD - PROD` |

| Item | Value |
|------|--------|
| **Query note** | Org-wide `list_issues`; `project:flava-console-*` may be invalid—filter to `FLAVA-CONSOLE-*` and document the query |
| **Pagination** | MCP `limit` max is often **100**—if exactly 100 results, note **≥100 (MCP cap)** in the report |

### Environment-specific safety

| Environment | Bulk resolve | Notes |
|-------------|--------------|--------|
| **stage** | Default **no** bulk resolve | Primary integration signal |
| **dev** | **Never** bulk resolve | localhost, `EADDRINUSE`, federation chunks → bias **C** |
| **prod** | **Never** bulk resolve without explicit user order | User-impacting; escalate high-event issues |

---

## 2. Pull issues (single environment)

1. Read **`list_issues`** schema before calling.
2. **One** call: unresolved issues for the **resolved** environment only (§1d).
3. Record **total count**, **query string**, and per issue: short id, title, culprit, events, users, permalink.

---

## 3. Classification (A–D + performance callout)

| Category | Meaning (short) |
|----------|------------------|
| **A** | Actionable **front-end** bugs + client **N+1** performance issues |
| **B** | **API / BFF / backend** failures or payload shape bugs |
| **C** | **External / environmental** (`window.ya`, SessionExpiredModal, `EADDRINUSE`, HTTP/1.1 overhead, localhost) |
| **D** | **Stale / already fixed** (evidence required; default **no** bulk resolve) |

**Performance row:** Count **N+1** (usually in A) and **HTTP/1.1 Overhead** (usually in C) separately in the summary table.

Match report depth to [2026-05-11](https://wiki.workers-hub.com/pages/viewpage.action?pageId=4136143567): intro, Summary (incl. Performance row), **full** Category A/B/C/D tables (every issue with link, events/users, culprit, analysis, recommendation), Recommended Actions Summary, Previous reports, footer.

**DEV bias:** `EADDRINUSE`, `localhost`, `flava-dev.workers-hub.com` chunk failures → prefer **C**.

**PROD bias:** High-event `<unknown>` on OVERVIEW/SHELL, overview **N+1** clusters → **High** in recommended actions.

---

## 4. Publish Confluence (one env child per run)

Skip only if user opted out in **0d**.

Use **today’s date** as `YYYY-MM-DD` in all page titles unless the user names a different triage date.

### Page hierarchy (required)

```
Flava Console - Sentry Issues (hub, pageId 4007182380)
└── Flava Console - Sentry Triage - YYYY-MM-DD          ← date parent (rollup index ONLY)
    └── Flava Console - Sentry Triage - YYYY-MM-DD - STAGE   ← default for /sentry-triage
        (or - DEV / - PROD when user specifies that env)
```

**Never** put the full issue tables on the date parent or directly under the hub. **Never** create the env child before the date parent exists.

### Step 4a — Resolve or create the date parent (do this FIRST)

1. Read **`confluence_get_page_children`** and **`confluence_create_page`** schemas.
2. List children of the hub:

   ```
   confluence_get_page_children(parent_id: "4007182380")
   ```

3. Find a child whose title is exactly **`Flava Console - Sentry Triage - YYYY-MM-DD`** (today’s date).
   - **Found** → record its `page_id` as **`date_parent_id`**.
   - **Not found** → **create the date parent before any env child**:

   ```
   confluence_create_page(
     space_key: "LVN",
     title: "Flava Console - Sentry Triage - YYYY-MM-DD",
     parent_id: "4007182380",
     content_format: "markdown",
     content: "<rollup index body — see template below>"
   )
   ```

   Save the returned **`page_id`** as **`date_parent_id`**.

4. **Date parent body** (rollup only — no per-issue tables):

   - Short intro: triage date, link to [hub](https://wiki.workers-hub.com/pages/viewpage.action?pageId=4007182380).
   - Table: Environment | Report | Issues (count) | Notes.
   - Rows for STAGE / DEV / PROD: envs not triaged this run → “Not triaged yet” or “—”.
   - After this run, set the row for the **current env** to the child link + count.

**`/sentry-triage` with no env** → after Step 4c, the STAGE row must be filled; DEV/PROD may stay “Not triaged yet” until separate runs.

### Step 4b — Create or update the env child (SECOND)

Only after **`date_parent_id`** is known:

| Resolved env | Child title |
|--------------|-------------|
| `stage` (default) | `Flava Console - Sentry Triage - YYYY-MM-DD - STAGE` |
| `dev` | `… - YYYY-MM-DD - DEV` |
| `prod` | `… - YYYY-MM-DD - PROD` |

1. Optionally **`confluence_get_page_children(parent_id: date_parent_id)`** to see if today’s env child already exists (update vs create).
2. **`confluence_create_page`** or **`confluence_update_page`** with:
   - **`parent_id`:** `date_parent_id` (not the hub id)
   - **Body:** full May-11-style triage for **this env only** (§3)
3. Default **`/sentry-triage`** → create/update **STAGE** child under today’s date parent.

### Step 4c — Refresh date parent and hub (THIRD)

1. **`confluence_update_page`** on **`date_parent_id`**: add/update the row for this env (link to child, issue count, A/B/C summary).
2. **`confluence_update_page`** on hub **`4007182380`**: ensure the Triage Reports table has one row for **`YYYY-MM-DD`** linking **`date_parent_id`** (create row if missing; do not add three env rows on the hub).

### Step 4d — Clear local draft markdown (FOURTH)

After **all** Confluence updates for this run succeed (env child + date parent + hub):

1. **Delete** any triage draft files created for this run, e.g. under `.claude/skills/flava-sentry-triage/reports/`:
   - `YYYY-MM-DD-STAGE.md`, `YYYY-MM-DD-DEV.md`, `YYYY-MM-DD-PROD.md`
   - Or any `*-STAGE.md` / `*-DEV.md` / `*-PROD.md` matching today’s triage date
2. **Do not** delete `SKILL.md` or files under `evals/`.
3. If publish **failed**, **keep** drafts until a retry succeeds (then delete).

**Default:** Build report markdown **in memory** and pass directly to `confluence_update_page`. Only write a local `.md` if MCP payload handling truly requires it — then **always** delete it in Step 4d.

### Confluence publish order (checklist)

| Order | Action | If skipped |
|-------|--------|------------|
| 1 | Hub smoke test (§0c) | Stop |
| 2 | Find or **create** date parent under hub | Child would be orphaned or under wrong parent |
| 3 | Create/update **one** env child under date parent | — |
| 4 | Update date parent index + hub table | — |
| 5 | Delete local draft `.md` for this env/date (§4d) | Stale copies confuse the next run |

### Confluence size discipline

- Publish **one** env child per `confluence_update_page` call.
- If the body is very large, still include **all** issue rows (May-11 style); do not replace tables with “see Sentry” summaries on the env child page.

### MCP-only publishing (required)

Use **only** Confluence MCP tools (`confluence_get_page`, `confluence_get_page_children`, `confluence_create_page`, `confluence_update_page`) via `CallMcpTool` / the agent’s Confluence MCP integration.

| Do | Don’t |
|----|--------|
| Build markdown in the agent from `list_issues` results, then pass it to `confluence_update_page` with `content_format: "markdown"` | Run Python, Node, or shell wrappers (`publish_to_confluence.py`, `npx @linecorp/flava-mcp-connector`, etc.) |
| Classify and format tables in the agent (same logic as §3) | Leave draft `.md` in `reports/` after publish (delete per §4d) |
| One `confluence_update_page` per env child body | Batch three envs in one turn |

**Why:** Shell scripts add latency, duplicate the same MCP call, and have caused stale payloads (e.g. wrong issue counts). MCP alone is the supported path.

If `confluence_update_page` fails on size or timeout, **retry MCP once** with the same body; do not fall back to scripts. If it still fails, report the error and leave the wiki unchanged rather than publishing a shortened summary on the env child.

**Confluence markdown quirk:** In table **Title** cells, wrap bare `<unknown>` as `` `<unknown>` `` (backticks). Unescaped `| <unknown> |` breaks Confluence storage conversion. See **§8.4** if publish fails.

---

## 5. Deliverables to the user

1. **Environment triaged** (`stage` / `dev` / `prod`) and total unresolved count.
2. Query string and A/B/C/D (+ performance) counts.
3. Top 3–5 themes with example issue ids.
4. Confluence URL for **this env’s child page** (+ date parent + hub if published).
5. Reminder: post to **`#pj-flava-console-alert`**.
6. If other envs were not run: *“To triage dev or prod, run again with `/sentry-triage dev` or `/sentry-triage prod`.”*
7. If MCP cap hit (often prod): totals may be **≥100**.

If MCP pre-flight failed: only **§0d**—no fabricated data.

---

## 6. Out of scope

- No `.env`, tokens, or DSN secrets in reports.
- No code fixes unless explicitly requested after triage.
- No skipping §0 because MCP “worked last time”.
- **No** single run that lists STAGE + DEV + PROD issues in one wiki table.
- **No** three full Confluence publishes in one agent turn (use three invocations).
- **No** Python/shell publish helpers — triage is Sentry MCP + Confluence MCP only.

---

## 7. Operational experience (why DEV feels hard + how to fix)

This section captures **2026-05-21 DEV** lessons so future runs do not look “complex” for the wrong reasons. The workflow is the same as STAGE; DEV differs in **data shape** and **Confluence edge cases**.

### 7.1 Why DEV is harder than STAGE (not a different process)

| Factor | STAGE (typical) | DEV (typical) | What it changes |
|--------|-----------------|---------------|-----------------|
| Issue count | ~60 | **~80** | Report body ~**25–30 KB** → slower `confluence_update_page` |
| Dominant signatures | Route-specific FE `TypeError`s | Many **`<unknown>`** across products (**~22** on 2026-05-21) | Large **Category C**; easy to over-file JIRAs if misclassified |
| Performance noise | Few N+1 rows | **~30+ N+1** (VPC, Monitoring, K8s list routes) | Many similar table rows; must count N+1 in Summary |
| Environmental | Some BFF/port noise | **`window.ya`**, **SessionExpiredModal** on `flava-dev`, localhost | Strong **C** bias (§1d); fewer true “bugs” in A |
| Event volume | Spread across bugs | **SHELL-CLIENT-1**, **OVERVIEW-CLIENT-1** often 100k+ events | Rollup themes highlight **noise**, not one-line fixes |

**Takeaway:** DEV “complexity” = **more rows + more Category C + bigger paste to Confluence**. Classification rules and one-env-per-run stay the same.

### 7.2 Root causes of failed or slow DEV publishes (2026-05-21)

| # | Symptom | Root cause | Fix for next run |
|---|---------|------------|------------------|
| 1 | MCP **timeout** on `confluence_update_page` | ~27 KB markdown, 80 table rows | **Retry once** with same body; one env per call (§4) |
| 2 | Confluence error *"No space or no content type"* | Raw `\| <unknown> \|` in **Title** cells → invalid storage HTML | Use `` `<unknown>` `` in Title column only (§4, below) |
| 3 | Wiki shows **wrong counts** (e.g. 81 vs 80) | Stale local `publish-*.json` / old script payload | **MCP-only** publish; counts from fresh `list_issues` only (§4 MCP-only) |
| 4 | Wiki has summary only, no per-issue tables | Skipped May-11 template on env child | Env child must list **every** issue with link (§3) |
| 5 | Agent “stuck” for minutes | Extra Python/`npx` publish wrappers | Removed — build markdown → single `confluence_update_page` |

### 7.3 DEV classification quick rules (apply in order)

First match wins:

1. Title contains **`N+1 API Call`** → **A** (also increment Performance row).
2. Title contains **`window.ya`** → **C**.
3. Title or culprit contains **`SessionExpiredModal`**, **`flava-dev.workers-hub.com`**, or **`localhost`** → **C**.
4. Title is **`<unknown>`** → **C** on dev (document high events in Recommended Actions, not as separate A rows).
5. Culprit is BFF **`GET`/`POST`** or title is **Internal Server Error** / BFF `map` on API route → **B**.
6. **`Missing required param "projectName"`** → **A**.
7. Else → **A** (FE guard, silent error, iterable/null) unless clear BFF evidence.

**Never** bulk-resolve DEV Category **C** without explicit user order.

### 7.4 Confluence publish playbook

**Before `confluence_update_page` (env child):**

- [ ] Classify all rows; verify **A + B + C + D = total** from `list_issues`.
- [ ] Wrap every Title `<unknown>` as `` `<unknown>` `` (backticks).
- [ ] Performance row: N+1 count = number of rows whose title contains `N+1 API Call`.
- [ ] Intro notes query (`is:unresolved environment:dev`) and if `whoami` failed but `list_issues` worked.

**When publish fails:**

| Error / behavior | Action |
|------------------|--------|
| Timeout `-32001` | Retry **once**; do not switch to summary-only body |
| Storage / content-type HTML error | Search markdown for `\| <unknown> \|`; backtick Title cells only; retry |
| Still failing after retry | Stop; report error; **do not** update date parent/hub with new counts |

**After success:** update date parent + hub (§4c), then delete draft `.md` (§4d).

### 7.5 Allowed shortcuts (do not drop rows)

May-11 requires **every issue** with Sentry link. You **may** reuse short Analysis/Recommendation text:

| Pattern | Analysis (short) | Recommendation (short) |
|---------|------------------|------------------------|
| C + `<unknown>` | Dev `<unknown>` noise on route. | Monitor; JIRA only if stage reproduces. |
| A + N+1 | Duplicate sequential API on dev. | Batch/cache; JIRA if stage reproduces. |
| C + `window.ya` | Analytics `window.ya` unavailable. | SDK ignore or guard. |
| C + SessionExpiredModal / flava-dev chunk | Federation chunk load on dev. | Environmental; verify on stage first. |
| A + null/undefined TypeError | Missing null guard on culprit route. | Triage stack; JIRA if stage reproduces. |

**Forbidden:** “See Sentry dashboard” instead of tables; merging STAGE+DEV+PROD on one page; Python/shell publish helpers.

### 7.6 Plan a full daily triage (three invocations)

| Order | Command | Expected pain | Child `page_id` (2026-05-21 example) |
|-------|---------|---------------|--------------------------------------|
| 1 | `/flava-sentry-triage` (stage) | Medium | `4188442801` |
| 2 | `/flava-sentry-triage dev` | **High** — apply §7.3–7.4 | `4164182076` |
| 3 | `/flava-sentry-triage prod` | **Highest** — often **≥100** issues (MCP cap) | `4188442750` |

### 7.7 Product noise vs real bugs (DEV)

High-event **C** issues are often **expected on dev** (instrumentation, analytics, federation). Prioritize **A** and **B** for JIRA:

- **A:** `projectName` routes, `SHELL-2P` silent errors, `SHELL-4` null config, `VPC-6K`, `MCP-HUB-3` filter, `APP-RUNNER-7` iterable.
- **B:** `KUBERNETES-ENGINE-BFF-1` vpc_networks `map` on GET.
- **C (monitor only):** `SHELL-1`, `OVERVIEW-1`, product-wide `<unknown>`, `window.ya`, SessionExpiredModal.

---

## 8. References

- **Sentry MCP:** [FE3 · AI · Sentry Integration Guide](https://wiki.workers-hub.com/display/LVN/FE3+-+AI+-+Sentry+Integration+Guide)
- **Hub:** [Flava Console - Sentry Issues](https://wiki.workers-hub.com/pages/viewpage.action?pageId=4007182380)
- **Report template:** [2026-05-11](https://wiki.workers-hub.com/pages/viewpage.action?pageId=4136143567)
- **Example rollup + children:** [2026-05-21](https://wiki.workers-hub.com/pages/viewpage.action?pageId=4188442597)
- **Published DEV example (80 issues):** [2026-05-21 - DEV](https://wiki.workers-hub.com/pages/viewpage.action?pageId=4164182076)
