---
name: weekly-report
description: Generate professional weekly activity reports from Jira data. Use when users request weekly reports, activity summaries, or work reports covering a specific time period (e.g., "Create report for last week", "Generate my weekly report", "Show what I worked on this week"). Automatically fetches Jira issues updated within the specified period, groups by component/project with **bold** section labels (e.g. **Load balancer**, **SRE**), opens with `# Weekly Activity Report` plus Period and Total Issues lines, then formats each ticket as `**Summary** ([KEY](https://jira.workers-hub.com/browse/KEY))` — human-readable ticket title **bold**, link not bold — followed by accomplishment bullets only (no Backlog/In Progress/Closed status lines). No numbered lists in the report body; no closing Summary section.
---

# Weekly Report Generator

Generate formatted weekly reports from Jira activity data with automatic grouping and professional formatting.

## Workflow

When a user requests a report:

- **Determine the time period** — Parse the user's request for date range (e.g., "last week", "past 7 days", "from Monday to Friday")
- **Query Jira** — Use `mcp_jira_jira_search` with JQL to fetch updated issues
- **Extract and group data** — Organize tickets by component, project, or team
- **Format the report** — Lead with the **report header** (title, period, issue count), then grouped sections whose names are **bold** (`**SRE**`, `**Load balancer**`, …); one title line per ticket `**Summary** ([KEY](url))` with the issue **title bold** and the parenthesized link in normal weight, then `-` bullets for accomplishments only (no status words); omit a closing Summary section

## Step 1: Determine Time Period

Convert natural language to JQL date format:

- **"Last week"** → `updated >= -7d`
- **"This week"** → `updated >= startOfWeek()`
- **"Past X days"** → `updated >= -Xd`
- **Specific dates** → `updated >= "YYYY-MM-DD" AND updated <= "YYYY-MM-DD"`

If no period specified, default to last 7 days.

## Step 2: Query Jira Issues

Use `mcp_jira_jira_search` with appropriate JQL:

```
jql: "assignee = currentUser() AND updated >= -7d ORDER BY updated DESC"
fields: "summary,description,issuetype,status,components,updated"
limit: 50
```

**JQL patterns:**
- Current user's work: `assignee = currentUser()`
- Specific project: `project = PROJ`
- Specific status: `status IN ('Done', 'Resolved', 'Closed')`
- Exclude subtasks: `issuetype != Sub-task`

Adjust the JQL based on user requirements (e.g., specific project, all team activity, completed items only).

## Step 3: Extract and Group Data

From the Jira response, extract:
- Issue key (e.g., `LYCC-6166`)
- Summary (title/description)
- Components (for grouping)
- Issue type
- Description field (for details)

**Grouping logic:**
- First try grouping by **components** field
- If no components, group by **project key** prefix
- If user specifies, group by **issue type** or **status**

## Step 4: Format the Report

**Report header (required)** — Put this at the **very top** of the output, before any component sections:

```
# Weekly Activity Report

Period: March 10–17, 2026   Total Issues: 20
```

- **Title** — Always use the level-1 heading: `# Weekly Activity Report` (exact wording).
- **Period** — Human-readable date range that matches the query window you used (same calendar span as the JQL time filter).
  - For rolling windows (e.g. `updated >= -7d`), use **today’s date** as the report end: period = **inclusive** range covering the last N calendar days (e.g. Mar 24–30, 2026 for a 7-day window ending Mar 30, 2026). If the user’s “last week” means ISO calendar week, use Monday–Sunday or the org’s convention and state it.
  - For explicit ranges, use `Month D–D, YYYY` (or `Month D, YYYY – Month D, YYYY` across month boundaries). Use an **en dash** (`–`) between day numbers when both fall in the same month.
- **Total Issues** — Integer count of **issues actually listed** in the report body (after filtering). Must match the number of ticket blocks.

Optional: on the Period line you may separate fields with spaces (as above) or use a middle dot: `Period: … · Total Issues: N`.

Then a **blank line**, then the first grouping section.

**Jira ticket links (required):** Whenever you name an issue key, use a markdown link. Base URL is `https://jira.workers-hub.com/browse/`. The path segment must use the **same** key as link text (no mismatched keys).

Examples:

- `[LYCC-1234](https://jira.workers-hub.com/browse/LYCC-1234)`
- `[CLOUDQA-83167](https://jira.workers-hub.com/browse/CLOUDQA-83167)`

Put the key inside **parentheses** on the **title line** as a markdown link (same key in URL). Do not use a bare key in parentheses without a link on that line.

**Per-ticket shape (required):**

- **Title line** — no leading `-`. Pattern: `**Short Jira summary as title** ([KEY](https://jira.workers-hub.com/browse/KEY))`  
  - Wrap the **entire human-readable ticket name** (from the issue **summary**) in `**...**`. Leave a space before the opening parenthesis; keep `([KEY](url))` in **normal** weight (not inside the bold span).  
  - Derive the title from the issue **summary** (edit slightly for readability if needed; keep meaning).
  - Do **not** use `Title: [link]`, colons before the key, or a separate line for the link; merge into this single title line.

- **Detail lines** — only `-` bullets **under** that title, describing work and outcomes (features fixed, APIs changed, fields added, behavior improved).
  - Use **2–4 bullets** when possible; fewer is OK if the issue is thin.
  - **Do not** mention Jira workflow state: no *Backlog*, *In Progress*, *In Review*, *Closed*, *Resolved*, or lines like “Ticket still in …”.
  - For items not yet delivered, write what is **planned**, **scoped**, or **being worked on** in neutral language (still no status keywords).

Use a **blank line** between one ticket block (title + its bullets) and the next.

**Section header:** `**Group label** - X tickets` then a blank line, then ticket blocks.  
- **Bold** the whole group label (component, project bucket, or synthetic section name) using markdown `**...**` — e.g. **Load balancer** - 8 tickets, **SRE** - 4 tickets, **Cloud QA** - 3 tickets.  
- Keep the trailing ` - N tickets` part in regular weight unless the user asks otherwise.

**Do not** use ordered lists (`1.`, `2.`, …) anywhere in the report body.

**Do not** add a closing **Summary** section. Grouped sections are the full deliverable.

**Example (target style):**

```
# Weekly Activity Report

Period: March 10–17, 2026   Total Issues: 3

**Load balancer** - 2 tickets

**Request Quota API Enhancement** ([LYCC-9594](https://jira.workers-hub.com/browse/LYCC-9594))
- Added current quota fields to request quota API response
- New fields: cpu_old, memory_old, block_storage_old

**Fixed routing rules validation on UI** ([LYCC-6166](https://jira.workers-hub.com/browse/LYCC-6166))
- Corrected rule handling in the routing-rules UI flow
- Validation now matches expected routing rule behavior

**Application Load Balancer (ALB)** - 6 tickets

**Changed upper limit for upstream/downstream timeout** ([LYCC-6109](https://jira.workers-hub.com/browse/LYCC-6109))
- Raised maximum timeout limits for upstream and downstream connections
- Aligned configuration with new latency requirements
```

## Customization Options

Users may request variations:

**Different grouping:**
- "Group by status" → Group tickets by current status
- "Group by type" → Group by issue type (Bug, Feature, Task)
- "Don't group" → Simple bullet list with Jira links per ticket

**Different filtering:**
- "Only completed tickets" → Add `status IN ('Done', 'Resolved', 'Closed')` to JQL
- "Include all team" → Remove `assignee = currentUser()` from JQL
- "Project X only" → Add `project = X` to JQL

**Different format:**
- "Brief format" → Show only summary and ticket ID
- "Detailed format" → Include more description details
- "Bullet list" → Default format; still include Jira links for each ticket

## Tips for Best Results

- **Default to current user**: Unless specified, fetch the current user's activity
- **Reasonable limits**: Default to 50 tickets max; ask if more are needed
- **Handle missing data**: If tickets lack components, fall back to project grouping
- **Parse descriptions intelligently**: Extract key accomplishments from description field
- **Professional tone**: Outcome-focused bullets; ticket title on the title line is `**bold**` then `([KEY](url))` in normal weight; never echo Jira status columns; header always includes period + total issue count; group lines use **bold** for the component/project name; no trailing Summary block

### scripts/
Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.

**Examples from other skills:**
- PDF skill: `fill_fillable_fields.py`, `extract_form_field_info.py` - utilities for PDF manipulation
- DOCX skill: `document.py`, `utilities.py` - Python modules for document processing

**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Claude for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Claude's process and thinking.

**Examples from other skills:**
- Product management: `communication.md`, `context_building.md` - detailed workflow guides
- BigQuery: API reference documentation and query examples
- Finance: Schema documentation, company policies

**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Claude should reference while working.

### assets/
Files not intended to be loaded into context, but rather used within the output Claude produces.

**Examples from other skills:**
- Brand styling: PowerPoint template files (.pptx), logo files
- Frontend builder: HTML/React boilerplate project directories
- Typography: Font files (.ttf, .woff2)

**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

---

**Any unneeded directories can be deleted.** Not every skill requires all three types of resources.
