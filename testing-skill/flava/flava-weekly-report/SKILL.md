---
name: weekly-report
description: Generate weekly activity from Jira in one of two outputs—(1) **Flava product buckets** (default): group headers as Markdown **h3 + bold**, e.g. `### **SRE:**`, `### **Load Balancer:**` (larger type + bold), then task lines `[Category] Short description [KEY](https://jira.workers-hub.com/browse/KEY)`, no leading list markers; (2) **LVN FE3 "This Week"** column—member line `（ Full Name ）`, `*` bullets, same Jira URL base, optional PRs. Use Confluence MCP `confluence_get_page` (LVN / FE 3 - Weekly template) when FE3 rules must be refreshed. No Jira workflow status in task text.
---

# Weekly Report Generator

Build a paste-ready weekly list from **Jira** (`user-jira` / `jira_search`) unless the user supplies tickets manually.

## Choose output format

| Format | When to use |
|--------|-------------|
| **Flava product buckets** | Group headers use `### **SRE:**` style (Markdown **h3** + **bold** label for larger type); each line ends with `[KEY](https://jira.workers-hub.com/browse/KEY)`. **Default** unless they say "FE3" or "wiki template". |
| **LVN FE3 "This Week"** | User asks for DEV3 wiki column, `（ Full Name ）`, bullets with Jira URLs, PR links—see [FE 3 - Weekly template](https://wiki.workers-hub.com/pages/viewpage.action?pageId=3999174967); refresh via `confluence_get_page` (`space_key`: `LVN`, `title`: `FE 3 - Weekly template`). |

---

## Format 1 — Flava product buckets (expected default)

### Rules

1. **Sections** — One **group header** per section, on its own line: `### **AreaName:**` — Markdown **level-3 heading** (larger font in most viewers) with the **label in bold**, trailing colon inside the bold span. Examples: `### **SRE:**`, `### **Load Balancer:**`, `### **DBS for Cassandra:**`, `### **Vector Search:**`, `### **QA:**`, `### **Flava Console:**`.  
   - If the user’s paste target does not support Markdown (plain text only), fall back to `**AreaName:**` or plain `AreaName:` and say rendering may be limited.  
   - For **Confluence** rich editor, pasting Markdown depends on editor mode; equivalent HTML is `<h3><strong>SRE:</strong></h3>` if they need storage format.
2. **Blank line** — After each group header line, one blank line, then task lines. **No** required blank line between the last task of a section and the next group header (compact paste is OK); optional extra blank between sections if the user prefers.
3. **Task line** — Single line per issue, **no** leading `*` or `-`. Pattern: `[Category] Human-readable short description [ISSUE-KEY](https://jira.workers-hub.com/browse/ISSUE-KEY)`  
   - **Jira link is required** for every task. Use base URL `https://jira.workers-hub.com/browse/`; link text **must** match the key (e.g. `[LYCC-9351](https://jira.workers-hub.com/browse/LYCC-9351)`).  
   - If the user explicitly asks for **bare keys only** (no markdown), omit links for that run only.
4. **Description** — Short, title-like; trim Jira bracket prefixes such as `[ALB]` when it helps readability (optional). **Do not** append workflow status (*Backlog*, *Closed*, etc.).
5. **Section order** — Default order (repeat only sections that have ≥1 issue):  
   `SRE` → `Load Balancer` → `DBS for Cassandra` → `Vector Search` → `QA` → `Flava Console`  
   Omit empty sections. User may override order or labels.
6. **Between sections** — Either place the next `### **Area:**` header immediately after the previous section’s last task **or** insert one blank line between sections—match the user’s latest example if they provide one.

### Bucket mapping (Jira → section)

Use **components** and **project** first; normalize case/spelling.

| Group header (output) | Map when |
|-------------------------|----------|
| `### **SRE:**` | `components` contains `SRE`. |
| `### **Load Balancer:**` | `components` contains `Load balancer` (or team convention "Load Balancer"). |
| `### **DBS for Cassandra:**` | `components` contains Cassandra / `DBS for Cassandra` / equivalent product name. |
| `### **Vector Search:**` | `components` contains `Vector search` (or `Vector Search`). |
| `### **QA:**` | `project` is `CLOUDQA`, or issue is clearly QA-filed work in Cloud QA project. Use `[QA]` category for these lines unless the user says otherwise. |
| `### **Flava Console:**` | LYCC (or Flava Console) issues that are **not** placed above—e.g. cross-product console features, deployment overview/run history, integrate-API console work **without** a more specific component bucket. If unsure, prefer asking once or using the component the user names. |

If an issue matches multiple rules, use the **most specific** product (e.g. Vector Search before Flava Console).

### Category tags

Same semantics as FE3; **one** tag per line:

| Tag | Use when |
|-----|----------|
| `[Feature]` | New capability / user-facing feature |
| `[Bugfix]` | Defect fix |
| `[Improvement]` | Refactor, UX polish, performance, API swap |
| `[Hotfix]` | Urgent prod fix |
| `[Infra]` | CI/CD, alerts, channels, env, routing |
| `[Docs]` | Docs / wiki / spec |
| `[Design]` | Design implementation |
| `[QA]` | QA-driven items (common for CLOUDQA) |
| `[Release]` | Release / deploy checklist |
| `[Discussion]` | Alignment / handover (Slack thread only if user or Jira provides URL) |

Infer from `issuetype`, `labels`, `components`, `project`, and summary.

### Example (target shape)

```
### **SRE:**

[Infra] Alert noise reduction for window.ya [LYCC-9351](https://jira.workers-hub.com/browse/LYCC-9351)
[Infra] Separate IMON and Sentry alert channels [LYCC-9841](https://jira.workers-hub.com/browse/LYCC-9841)

### **Load Balancer:**

[Feature] Add OpenSearch tab in overview [LYCC-9844](https://jira.workers-hub.com/browse/LYCC-9844)
[Improvement] Change to BE API for ALB list [LYCC-8687](https://jira.workers-hub.com/browse/LYCC-8687)

### **QA:**

[QA] Status shows Unknown during upgrade [CLOUDQA-83888](https://jira.workers-hub.com/browse/CLOUDQA-83888)
```

**Do not** use numbered lists in the body. **Do not** add a trailing "Summary" section.

### Golden example (team shape — grouping + Jira links)

Use this as the structural reference when the user asks for the "Flava bucket" weekly list (wording may change per sprint; **shape** must match). **Every** line ends with `[KEY](https://jira.workers-hub.com/browse/KEY)`.

```
### **SRE:**

[Infra] Alert noise reduction for window.ya [LYCC-9351](https://jira.workers-hub.com/browse/LYCC-9351)
[Infra] Separate IMON and Sentry alert channels [LYCC-9841](https://jira.workers-hub.com/browse/LYCC-9841)
[Infra] Separate Prod and Dev alert channels [LYCC-9796](https://jira.workers-hub.com/browse/LYCC-9796)
[Infra] Deliver IMON and Sentry channel routing [LYCC-9840](https://jira.workers-hub.com/browse/LYCC-9840)
### **Load Balancer:**

[Feature] Monitoring metric attributes [LYCC-9885](https://jira.workers-hub.com/browse/LYCC-9885)
[Feature] Add OpenSearch tab in overview [LYCC-9844](https://jira.workers-hub.com/browse/LYCC-9844)
[Improvement] Change to BE API for ALB list [LYCC-8687](https://jira.workers-hub.com/browse/LYCC-8687)
[Improvement] Remove General view from ALB edit [LYCC-8466](https://jira.workers-hub.com/browse/LYCC-8466)
[Feature] Add VPC selection for NLB/ALB [LYCC-9774](https://jira.workers-hub.com/browse/LYCC-9774)
[Feature] Add "Managed by" column to ALB list [LYCC-7983](https://jira.workers-hub.com/browse/LYCC-7983)
[Feature] Multiple products in "Managed by" on LB list [LYCC-9650](https://jira.workers-hub.com/browse/LYCC-9650)
[Improvement] Change to BE API for NLB list [LYCC-8686](https://jira.workers-hub.com/browse/LYCC-8686)
### **DBS for Cassandra:**

[Feature] Monitoring metric attributes [LYCC-9884](https://jira.workers-hub.com/browse/LYCC-9884)
### **Vector Search:**

[Feature] Add sparse encoding features [LYCC-9200](https://jira.workers-hub.com/browse/LYCC-9200)
### **QA:**

[QA] ALB list pagination incorrect [CLOUDQA-83822](https://jira.workers-hub.com/browse/CLOUDQA-83822)
[QA] NLB list pagination incorrect [CLOUDQA-83824](https://jira.workers-hub.com/browse/CLOUDQA-83824)
[QA] Field type for index template in pipeline [CLOUDQA-77248](https://jira.workers-hub.com/browse/CLOUDQA-77248)
[QA] Hide Approval from Vector Search in Prod [CLOUDQA-83167](https://jira.workers-hub.com/browse/CLOUDQA-83167)
[QA] Default not shown for Fixed char length [CLOUDQA-84098](https://jira.workers-hub.com/browse/CLOUDQA-84098)
[QA] Status not Deleting on lifetime end service [CLOUDQA-84099](https://jira.workers-hub.com/browse/CLOUDQA-84099)
[QA] Algorithm change fails after engine upgrade [CLOUDQA-84074](https://jira.workers-hub.com/browse/CLOUDQA-84074)
[QA] Missing Text embedding notice on pipeline [CLOUDQA-83862](https://jira.workers-hub.com/browse/CLOUDQA-83862)
[QA] ML model list empty when no models deployed [CLOUDQA-84073](https://jira.workers-hub.com/browse/CLOUDQA-84073)
[QA] Status shows Unknown during upgrade [CLOUDQA-83888](https://jira.workers-hub.com/browse/CLOUDQA-83888)
[QA] ML model label for system model ID [CLOUDQA-83869](https://jira.workers-hub.com/browse/CLOUDQA-83869)
[QA] Tooltip for system model ID [CLOUDQA-83868](https://jira.workers-hub.com/browse/CLOUDQA-83868)
[QA] Register model engine version format [CLOUDQA-83860](https://jira.workers-hub.com/browse/CLOUDQA-83860)
[QA] ML model catalog engine version filter [CLOUDQA-83859](https://jira.workers-hub.com/browse/CLOUDQA-83859)
### **Flava Console:**

[Feature] Deployment Run History detail view [LYCC-9765](https://jira.workers-hub.com/browse/LYCC-9765)
[Feature] Deployment Overview page [LYCC-9237](https://jira.workers-hub.com/browse/LYCC-9237)
```

Note: In real runs, only include tickets returned by JQL for the chosen period and assignee; omit sections with zero rows. The golden sample uses **no** blank line between the last task line and the following group header.

---

## Format 2 — LVN FE3 "This Week" column

When the user asks for the wiki column format:

- Re-read rules from Confluence: `confluence_get_page` (`user-confluence`), `space_key`: `LVN`, `title`: `FE 3 - Weekly template`.
- **Member line:** `（ Full Name ）` — full-width parentheses, single space inside.
- **Tasks:** `* [Category] Text [KEY](https://jira.workers-hub.com/browse/KEY)`; optional `, [PR-N](url)`; `+` sub-lines for Discussion Slack threads.
- **No activity:** `* No activity this week` under the member line.

---

## Workflow (both formats)

1. **Time period** — "Last week" → default `updated >= -7d`; or explicit dates; or `startOfWeek()` for "this week".
2. **Query** — `jira_search`: default `assignee = currentUser() AND updated >= -7d ORDER BY updated DESC`, `fields` include `summary,description,issuetype,status,components,updated,project,labels,assignee`, `limit` 50 (paginate if needed).
3. **Group** — Format 1: assign each issue to a **bucket** (table above). Format 2: optional component grouping or flat list per FE3.
4. **Emit** — Follow the chosen format exactly (Format 1: `### **Group:**` headers + Jira links on every task line unless bare keys requested; Format 2: member line + bullets).

## JQL reference

- Current user: `assignee = currentUser()`
- Done only: `status IN ('Done', 'Resolved', 'Closed')`
- Team: broaden assignee or drop filter
- Project: `project in (LYCC, CLOUDQA)`

## Tips

- **Format 1 default:** group titles as `### **Name:**` (bigger + bold); always append `[KEY](https://jira.workers-hub.com/browse/KEY)` so viewers render clickable tickets. Use bare keys only when the user says so.
- **LYCC-9840**-style rows appear when the user tracks related delivery; include only if it appears in the Jira result set for the window and assignee filter.
- Never invent PR URLs or Slack threads.

### scripts/

Optional helpers in `scripts/` if you add automation.

### references/

- [FE 3 - Weekly template](https://wiki.workers-hub.com/pages/viewpage.action?pageId=3999174967) (LVN).

### assets/

None required.

---

**Any unneeded directories can be deleted.** Not every skill requires all three types of resources.
