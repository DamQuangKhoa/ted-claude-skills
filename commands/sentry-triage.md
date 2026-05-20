# /sentry-triage - Automated Sentry Issue Triage

Triage unresolved Sentry issues for all Flava Console projects, categorize them, document findings in Confluence, and clean up non-stage noise.

## Configuration

| Setting               | Value                                                                  |
| --------------------- | ---------------------------------------------------------------------- |
| Sentry Org            | `ly`                                                                   |
| Sentry Projects       | All `flava-console-*` projects                                         |
| Sentry Region         | `https://ly.my.sentry.io`                                              |
| Sentry Issues (stage) | `https://ly.my.sentry.io/organizations/ly/issues/?environment=stage`   |
| Confluence Space      | `LVN`                                                                  |
| Parent Page ID        | `4007182380` (Flava Console - Sentry Issues)                           |
| Parent Wiki           | `https://wiki.workers-hub.com/pages/viewpage.action?pageId=4007182380` |
| Slack Channel         | `#pj-flava-console-alert`                                              |

## Instructions

When `/sentry-triage` is invoked, execute the following workflow step by step.

---

### Step 1: Load Unresolved Sentry Issues (stage environment)

Use the Sentry MCP tools to fetch all unresolved issues from the stage environment across all `flava-console-*` projects. Query each project individually or use the org-wide query.

```
mcp__sentry__list_issues(
  organization_slug: "ly",
  query: "is:unresolved environment:stage project:flava-console-*",
  sort_by: "freq"
)
```

Also fetch a broader list without the environment filter to identify non-stage-only issues later:

```
mcp__sentry__list_issues(
  organization_slug: "ly",
  query: "is:unresolved project:flava-console-*",
  sort_by: "freq"
)
```

For each issue, note the following fields:

- `id` (numeric ID for URLs)
- `title`
- `culprit`
- `count` (event count)
- `userCount` (affected users)
- `firstSeen` / `lastSeen`
- `level`
- `metadata`
- `tags` (especially `environment`, `browser`, `os`)

### Step 2: Gather Detailed Context for Each Issue

For every issue from Step 1, fetch recent events to understand the root cause:

```
mcp__sentry__list_issue_events(
  organization_slug: "ly",
  issue_id: "<issue_id>"
)
```

Examine:

- Stack traces (look for files under `src/` to identify FE-owned code)
- Error messages and exception types
- Request URLs and API endpoints involved
- Browser/OS/device context from tags
- Whether the error originates from our codebase or third-party libraries
- The environment tag on each event (prod, beta, rc, dev, etc.)

### Step 3: Categorize Each Issue

Place every issue into exactly one of these four categories:

#### Category A: Actionable FE Bugs

Issues where:

- The stack trace points to code in our `src/` directory
- The error is reproducible based on event patterns
- It affects stage users (environment: stage)
- Examples: unhandled promise rejections in our components, null reference errors in our hooks, rendering crashes in flava-console pages

#### Category B: API / Backend Errors

Issues where:

- The root cause is a failed API response (4xx/5xx from backend)
- Network errors or timeout errors calling our APIs
- CORS issues originating from backend configuration
- RTK Query error handler caught an upstream failure
- Examples: `ChunkLoadError` from CDN, API returning unexpected schema, 502/503 from backend

#### Category C: External / Environmental

Issues where:

- The error originates from third-party scripts (analytics, ad SDKs, browser extensions)
- Device/browser-specific quirks (old WebView versions, specific OS bugs)
- Network connectivity issues on the user's side
- LIFF SDK or LINE app environment issues outside our control
- Examples: `ResizeObserver loop limit exceeded`, extension-injected script errors, `SecurityError` from cross-origin iframes

#### Category D: Already Fixed / Stale

Issues where:

- The `lastSeen` date is more than 30 days ago
- The error references code paths that no longer exist in the current codebase
- A recent deployment likely resolved the underlying cause
- Very low event count (< 5 total) with no recent activity

### Step 4: Determine Ignore Threshold Recommendations

For each issue, recommend an action:

| Category          | Recommendation                                                                                                                          |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| A (FE Bug)        | **Investigate** - Create a JIRA ticket if one does not exist. Include Sentry link and reproduction hints.                               |
| B (API/Backend)   | **Escalate** - Flag to backend team. Add a note in the issue. Consider setting an alert threshold.                                      |
| C (External)      | **Ignore with threshold** - Set ignore conditions: ignore if fewer than N events in M days. Suggested: ignore if < 50 events in 7 days. |
| D (Already Fixed) | **Resolve** - Mark as resolved in Sentry.                                                                                               |

### Step 5: Create Confluence Report

Fetch the parent page and its existing child pages to understand triage history:

```
mcp__confluence__confluence_get_page(page_id: "4007182380")
```

```
mcp__confluence__confluence_get_page_children(parent_id: "4007182380")
```

Review the existing child pages to:

- Identify previously triaged issues (avoid re-categorizing issues that were already handled)
- Reference prior reports in the "Previous Reports" section of the new report
- Note trends (e.g., recurring issues across multiple triage runs)

Then create a child page:

```
mcp__confluence__confluence_create_page(
  space_key: "LVN",
  title: "Flava Console - Sentry Triage - {YYYY-MM-DD}",
  parent_page_id: "4007182380",
  body: "<generated HTML content>"
)
```

The page title MUST use today's actual date in `YYYY-MM-DD` format (e.g., `2026-04-16`).

#### Report Structure

Generate the page body in Confluence storage format (XHTML) with the following sections:

```html
<h2>Sentry Triage Report - {YYYY-MM-DD}</h2>
<p>
  Automated triage of unresolved Sentry issues for
  <strong>Flava Console</strong> projects (<code>flava-console-*</code>, org:
  ly). Filtered to <code>environment:stage</code>.
</p>

<ac:structured-macro ac:name="toc">
  <ac:parameter ac:name="printable">true</ac:parameter>
  <ac:parameter ac:name="style">disc</ac:parameter>
  <ac:parameter ac:name="maxLevel">3</ac:parameter>
  <ac:parameter ac:name="minLevel">2</ac:parameter>
  <ac:parameter ac:name="type">list</ac:parameter>
  <ac:parameter ac:name="outline">false</ac:parameter>
  <ac:parameter ac:name="include">.*</ac:parameter>
</ac:structured-macro>

<h3>Summary</h3>
<table>
  <tr>
    <th>Category</th>
    <th>Count</th>
    <th>Action</th>
  </tr>
  <tr>
    <td>A - Actionable FE Bugs</td>
    <td>{count}</td>
    <td>Investigate / Create JIRA tickets</td>
  </tr>
  <tr>
    <td>B - API / Backend Errors</td>
    <td>{count}</td>
    <td>Escalate to backend team</td>
  </tr>
  <tr>
    <td>C - External / Environmental</td>
    <td>{count}</td>
    <td>Ignore with threshold</td>
  </tr>
  <tr>
    <td>D - Already Fixed / Stale</td>
    <td>{count}</td>
    <td>Resolved in Sentry</td>
  </tr>
</table>

<h3>Category A: Actionable FE Bugs</h3>
<table>
  <tr>
    <th>Issue</th>
    <th>Events (Users)</th>
    <th>First / Last Seen</th>
    <th>Culprit</th>
    <th>Analysis</th>
    <th>Recommendation</th>
  </tr>
  <!-- One row per issue -->
  <tr>
    <td>
      <a
        href="https://ly.my.sentry.io/organizations/ly/issues/{issue.id}/?project=1360"
        >{issue.title}</a
      >
    </td>
    <td>{issue.count} ({issue.userCount})</td>
    <td>{issue.firstSeen} / {issue.lastSeen}</td>
    <td><code>{issue.culprit}</code></td>
    <td>{brief explanation of root cause and affected code path}</td>
    <td>{specific action to take}</td>
  </tr>
</table>

<!-- Repeat the same table pattern for Categories B, C, D -->

<h3>Category B: API / Backend Errors</h3>
<table>
  <tr>
    <th>Issue</th>
    <th>Events (Users)</th>
    <th>First / Last Seen</th>
    <th>Culprit</th>
    <th>Analysis</th>
    <th>Recommendation</th>
  </tr>
  <!-- One row per issue -->
</table>

<h3>Category C: External / Environmental</h3>
<table>
  <tr>
    <th>Issue</th>
    <th>Events (Users)</th>
    <th>First / Last Seen</th>
    <th>Culprit</th>
    <th>Analysis</th>
    <th>Recommendation</th>
  </tr>
  <!-- One row per issue, include ignore threshold recommendation in Recommendation column -->
</table>

<h3>Category D: Already Fixed / Stale</h3>
<table>
  <tr>
    <th>Issue</th>
    <th>Events (Users)</th>
    <th>First / Last Seen</th>
    <th>Culprit</th>
    <th>Analysis</th>
    <th>Action Taken</th>
  </tr>
  <!-- One row per issue, note that these were resolved in Sentry -->
</table>

<h3>Ignore Threshold Recommendations</h3>
<table>
  <tr>
    <th>Issue</th>
    <th>Category</th>
    <th>Recommended Threshold</th>
    <th>Rationale</th>
  </tr>
  <!-- One row per issue where an ignore threshold is recommended -->
  <tr>
    <td>
      <a
        href="https://ly.my.sentry.io/organizations/ly/issues/{id}/?project=1360"
        >{title}</a
      >
    </td>
    <td>{category}</td>
    <td>{e.g., "Ignore if < 50 events in 7 days"}</td>
    <td>{rationale}</td>
  </tr>
</table>

<h3>Previous Triage Reports</h3>
<ul>
  <!-- List links to all existing child pages under the parent, fetched in Step 5 -->
  <li><a href="{url}">{title}</a> - {date}</li>
</ul>

<hr />
<p>
  <em
    >Generated by Claude Code on {YYYY-MM-DD}. Review and adjust thresholds as
    needed.</em
  >
</p>
<p>
  <em
    >Post triage updates to <strong>#pj-flava-console-alert</strong> Slack
    channel.</em
  >
</p>
```

**Important URL format:** All Sentry issue links MUST use this exact format:

```
https://ly.my.sentry.io/organizations/ly/issues/{numericId}/
```

where `{numericId}` is the numeric `id` field from the Sentry API response (NOT the `shortId`). Do NOT hardcode a project ID — flava-console has many projects.

### Step 5b: Update Parent Page Triage Table

After creating the child page, update the parent page's triage table to include the new report:

```
mcp__confluence__confluence_get_page(page_id: "4007182380", convert_to_markdown: false)
```

Add a new row to the "Triage Reports" table with the date, link to the newly created page, and type "Automated triage by Claude Code".

```
mcp__confluence__confluence_update_page(
  page_id: "4007182380",
  title: "Flava Console - Sentry Issues",
  content: "<updated HTML with new row in triage table>",
  content_format: "storage",
  version_comment: "Added triage report for {YYYY-MM-DD}"
)
```

### Step 6: Resolve Non-prod and Stale Issues in Sentry

For issues categorized as **Category D (Already Fixed / Stale)**, mark them as resolved:

```
mcp__sentry__update_issue(
  organization_slug: "ly",
  issue_id: "<issue_id>",
  status: "resolved"
)
```

For issues that exist ONLY in non-stage environments (found in the broad query but NOT in the stage-filtered query), also resolve them:

```
mcp__sentry__update_issue(
  organization_slug: "ly",
  issue_id: "<issue_id>",
  status: "resolved"
)
```

Log every resolution action (issue ID, title, reason) so it can be reported to the user.

### Step 7: Report Results

After completing all steps, present a summary to the user:

1. **Issues triaged:** total count and breakdown by category
2. **Issues resolved in Sentry:** list with IDs and titles
3. **Confluence page:** link to the newly created page
4. **Action items requiring human attention:**
   - Category A issues that need JIRA tickets
   - Category B issues that need backend team escalation
5. **Reminder:** Post a summary to `#pj-flava-console-alert` with the Confluence page link

---

## Error Handling

- If the Sentry MCP tools return errors, report the error and continue with available data.
- If Confluence page creation fails, output the full report as text so the user can manually create the page.
- If an issue cannot be categorized with confidence, default to **Category A (Actionable FE Bug)** to avoid accidentally ignoring real problems.
- Never resolve issues in Category A or B -- only Category D and non-prod-only issues get resolved.

## Notes

- This command covers all `flava-console-*` projects (Vue 3 + TypeScript, Nuxt, LINE internal cloud platform).
- The Sentry instance is self-hosted at `ly.my.sentry.io`.
- Stack traces referencing paths under `src/` or `app/` indicate our frontend code. Anything else is likely third-party or backend.
- Project slugs follow the pattern `flava-console-{product}-{bff|client}` (e.g., `flava-console-lb-client`).
- When in doubt about categorization, err on the side of caution (keep as unresolved, categorize as A).
- The `stage` environment corresponds to the staging deployment of each flava-console product.
