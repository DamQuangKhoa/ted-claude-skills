---
name: weekly-report
description: Generate professional weekly activity reports from Jira data. Use when users request weekly reports, activity summaries, or work reports covering a specific time period (e.g., "Create report for last week", "Generate my weekly report", "Show what I worked on this week"). Automatically fetches Jira issues updated within the specified period, groups by component/project, and formats into a structured summary with ticket IDs and descriptions.
---

# Weekly Report Generator

Generate formatted weekly reports from Jira activity data with automatic grouping and professional formatting.

## Workflow

When a user requests a report:

1. **Determine the time period** - Parse the user's request for date range (e.g., "last week", "past 7 days", "from Monday to Friday")
2. **Query Jira** - Use `mcp_jira_jira_search` with JQL to fetch updated issues
3. **Extract and group data** - Organize tickets by component, project, or team
4. **Format the report** - Generate professional output with numbering and clear structure

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
1. First try grouping by **components** field
2. If no components, group by **project key** prefix
3. If user specifies, group by **issue type** or **status**

## Step 4: Format the Report

Generate output following this structure:

```
[Component/Project Name] - X tickets

1. [Brief summary]: [TICKET-ID]

[Main description - what was done]
[Key details or changes]
[Impact or outcome]

2. [Next ticket summary]: [TICKET-ID]
...
```

**Formatting guidelines:**
- Use clear section headers with ticket counts
- Number items sequentially across all sections
- Keep summaries concise (under 10 words)
- Include 2-4 bullet points for details
- Focus on what was accomplished, not technical implementation
- Use past tense for completed work
- End report with a **Summary** section using bullet points highlighting key themes and accomplishments

**Example output format:**

```
Application Load Balancer (ALB) - 6 tickets

1. Fixed routing rules bug in UI: LYCC-6166

Fixed bug in routing rules configuration on UI
Corrected rule handling and validation logic
Ensures proper routing rule behavior and configuration

2. Changed upper limit for upstream/downstream timeout: LYCC-6109

Updated maximum timeout limits for upstream and downstream connections
Adjusted timeout constraints to meet new requirements
Provides more flexibility for long-running connections
```

**Summary section format:**

End each report with a Summary section using bullet points to highlight:
- Main focus areas and product categories worked on
- Key achievements and major features completed
- Types of work (new features, bug fixes, refactoring, infrastructure)
- Notable improvements or significant impact items

Example:
```
**Summary:**
- Focused primarily on Load Balancer improvements and Vector Search enhancements
- Completed major features: IPv6 support, "Managed by" functionality, API migration
- Addressed multiple bug fixes for UI consistency and error handling
- Advanced CI/CD automation with GitHub Actions migration
- Enhanced user experience through improved terminology and guidance modals
```

## Customization Options

Users may request variations:

**Different grouping:**
- "Group by status" → Group tickets by current status
- "Group by type" → Group by issue type (Bug, Feature, Task)
- "Don't group" → Simple numbered list

**Different filtering:**
- "Only completed tickets" → Add `status IN ('Done', 'Resolved', 'Closed')` to JQL
- "Include all team" → Remove `assignee = currentUser()` from JQL
- "Project X only" → Add `project = X` to JQL

**Different format:**
- "Brief format" → Show only summary and ticket ID
- "Detailed format" → Include more description details
- "Bullet list" → Skip numbering, use bullets

## Tips for Best Results

1. **Default to current user**: Unless specified, fetch the current user's activity
2. **Reasonable limits**: Default to 50 tickets max; ask if more are needed
3. **Handle missing data**: If tickets lack components, fall back to project grouping
4. **Parse descriptions intelligently**: Extract key accomplishments from description field
5. **Professional tone**: Use clear, professional language in summaries

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
