---
name: flava-estimate-skill
description: Generate a structured development effort estimate (estimate.md) from a Confluence wiki page. Use whenever the user provides a Confluence/wiki URL and wants to estimate work, create a task breakdown, generate an effort table, plan man-days, or size a feature. Triggers on phrases like "estimate this wiki", "create estimate from confluence", "make an effort table", "estimate this feature", "how long will this take", "break down this wiki into tasks", or when the user pastes a Confluence link and asks for sizing or planning. Always use this skill when a wiki URL + estimation request appear together — even if the user just says "estimate" and pastes a link.
---

# Flava Estimate Skill

Convert a Confluence wiki page into a structured `estimate.md` file with a hierarchical task breakdown table (GLP-style columns) and effort estimates (MD + buffer).

## Workflow (required order)

| Step | Action |
|------|--------|
| **1** | **Fetch wiki content** — Use Confluence MCP to get the page |
| **2** | **Parse & understand** — Extract all features, tasks, and sub-tasks |
| **3** | **Estimate** — Assign MD values and compute buffer (MD × 1.1) |
| **4** | **Write estimate.md** — Output the structured file (exact column headers below + totals at end) |

---

## 1. Fetch Confluence page

Read tool schemas under `user-confluence` before calling.

```
confluence_get_page(page_id="<id>", ...)
```

**Extract page_id from the URL:**
- `atlassian.net/wiki/spaces/TEAM/pages/123456789/Title` → `page_id=123456789`
- `atlassian.net/wiki/...?pageId=123456789` → `page_id=123456789`
- Short link or unclear → use `confluence_search` with title keywords

Get the full page body (storage or view format). If the page has child pages or linked specs, fetch those too when they contain relevant task details.

---

## 2. Parse content into tasks

Convert the wiki content into a hierarchical task list mapped to **six levels** (`1 Level` … `6 Level`), matching spreadsheet-style breakdowns:

- **1 Level**: Page / major module (e.g., "Ad Videos Page", "Ad Metadata List Page")
- **2 Level**: Section or composite (e.g., "Ad Videos Table", "Form", "Integrate API")
- **3 Level**: Component or workflow step (e.g., "Video Detail Modal", "Service Select")
- **4 Level**: Sub-component (e.g., "Expandable row functionality", "Slate info after select")
- **5 Level** / **6 Level**: Extra depth when the wiki nests further (bullet sub-points, checklist steps). Leave blank if unused.

**Other columns:**
- **remark**: Implementation notes, field lists, reuse hints ("reuse file management component"), edge cases copied or summarized from the wiki.
- **Question**: Only if something is ambiguous, TBD, or needs PM/design/server confirmation; otherwise leave empty.
- **API**: Short note when known (e.g., new endpoint vs existing BFF, resource name). Empty if not specified in the wiki.
- **Design**: Empty unless the wiki names a designer or design deliverable.

Rules for parsing:
- Headings → distribute across 1–3 Level depending on depth
- Bullet points under a heading → deeper levels (3–6) or **remark**
- Tables in the wiki → rows become tasks; extra table columns can fill **remark** / **API** / **Question**
- Policy/non-task sections → capture separately as **Policy Updates** (do not force into the level columns)

---

## 3. Estimate effort

For each leaf-level task, assign a **MD (Man-Day)** estimate using these guidelines:

| Complexity | MD range | Examples |
|------------|----------|----------|
| Trivial (read-only display, copy) | 0.25–0.5 | Static info display, label changes |
| Simple (form field, modal with basic info) | 0.5–1 | Basic info modal, empty state, single API call |
| Medium (table with actions, multi-step form) | 1–2 | Table with edit/delete, paginated list, integrated API |
| Complex (new page, multi-API, complex logic) | 2–4 | Full CRUD page, complex state machine, cross-module integration |
| Integration/glue work | 0.5–1 | API wiring for existing UI, XLT updates |

**Buffer** = MD × 1.1 (round to 2 decimal places per row)

Leave **Design** and **PIC** empty unless the wiki explicitly names designers or assignees.

If a task has children, do **not** put MD on the parent row — only **leaf** rows get **MD** / **Buffer (1.1)**.

---

## 4. Write estimate.md

Save the file as `estimate.md` in the current working directory (or project root).

### Main table — use **exactly** these column headers (order and spelling)

The table must match the **GLP Schedule** layout: six level columns, then **remark**, **Question**, **API**, **Design**, **MD**, **Buffer (1.1)**, **PIC**.

```markdown
# <Wiki Page Title> - Estimate

## 1. Project Task Estimation Table

| 1 Level | 2 Level | 3 Level | 4 Level | 5 Level | 6 Level | remark | Question | API | Design | MD | Buffer (1.1) | PIC |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **<Example Page>** | | | | | | | | | | | | |
| <1 Level> | <2 Level> | <3 Level> | <4 Level> | <5 Level> | <6 Level> | <remark> | | | | <MD> | <Buffer> | |
...

---

## 2. Policy Updates

* **<Policy item>**: <description>

---

## 3. Estimation Guide
* **1 Level–6 Level**: Hierarchy from page/module down to finest task slice; leave trailing level cells empty when not needed.
* **remark**: Notes on reuse, fields, UX copy, dependencies.
* **Question** / **API**: Optional; use when the wiki implies follow-ups or API scope.
* **MD (Man-Day)** / **Buffer (1.1)**: Leaf tasks only; buffer = MD × 1.1 per row.

---

## 4. Total estimate

| | MD | Buffer (1.1) |
| :--- | :--- | :--- |
| **Total** | **<sum of all MD cells>** | **<sum of all Buffer (1.1) cells>** |
```

**Table formatting rules:**
- Use the header row **verbatim**: `1 Level`, `2 Level`, … `6 Level`, then `remark`, `Question`, `API`, `Design`, `MD`, `Buffer (1.1)`, `PIC` (**remark** and **Question** casing as shown).
- Bold the **1 Level** group name on its first row under a new page/module when helpful (e.g., `**Ad Videos Page**`).
- When a level spans multiple rows, leave repeated level cells **empty** (`| |`) on continuation rows, same as merged cells in Sheets.
- Cells with no value → empty (`| |`).
- MD values: decimals like `0.5`, `1`, `1.5`, `2`; Buffer always MD × 1.1 (e.g., `0.55`, `1.1`).
- **Total estimate**: Sum **only** numeric **MD** and **Buffer (1.1)** from data rows (ignore header and parent rows without MD). Round totals to **2 decimal places**.
- Rows with partial scope and **no MD** in the spreadsheet (placeholders): omit MD or add **Question**; do not invent buffer.

**Policy Updates section:** Include only if the wiki has explicit policy/timeline/rule changes outside the task table. If none, omit **## 2. Policy Updates** entirely.

**Section order:**
1. `## 1. Project Task Estimation Table` (always)
2. `## 2. Policy Updates` (optional — omit heading and bullets if none)
3. `## 3. Estimation Guide` (always)
4. `## 4. Total estimate` (always last)

---

## Output confirmation

After writing `estimate.md`, tell the user:
- File path written
- Total MD (must match **## 4. Total estimate**)
- Total Buffer (must match **## 4. Total estimate**)
- Count of leaf tasks estimated (rows with MD)
