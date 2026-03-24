---
name: flava-jira-check
description: Analyze Jira tickets, identify root causes, and implement fixes in the LYCC flava-console codebase. Use whenever the user provides a Jira ticket ID (like LYCC-1234, CLOUDQA-12345) and wants to investigate, check, debug, analyze, or fix an issue — even if they just paste a ticket number without further instructions. Also triggers for phrases like "check this ticket", "investigate this bug", "what's this Jira about", "fix this issue", or "root cause analysis". Supports both single and multiple ticket IDs.
---

# Flava Jira Check

Analyze Jira tickets to understand issues, identify root causes, and implement fixes in the flava-console codebase. This skill bridges Jira context with codebase investigation so you can go from ticket to fix in one flow.

## Workflow

### 1. Fetch Ticket Details

For each provided Jira ticket ID, use `mcp_jira_jira_get_issue` to retrieve the full ticket:

```
mcp_jira_jira_get_issue(issue_key="LYCC-1234", fields="*all", comment_limit=10)
```

Extract and note:
- **Summary & description**: What's the reported problem?
- **Status & priority**: How urgent is this?
- **Labels & components**: Which part of the system?
- **Comments**: Often contain reproduction steps, stack traces, or clues from other engineers
- **Linked issues**: Related tickets that provide additional context

### 2. Analyze the Ticket

From the ticket information, identify:
- **Error messages or stack traces** — these are your best leads for codebase search
- **Reproduction steps** — helps understand the user flow
- **Screenshots or logs** — visual clues about what's wrong
- **Environment details** — stage vs real, specific regions affected
- **Related tickets** — patterns across multiple reports

### 3. Search the Codebase

Based on what you found in the ticket, search the codebase methodically:

- **Error messages** → use `grep_search` to find where they originate
- **API endpoints mentioned** → trace the request flow through BFF controllers → services → upstream calls
- **Components/pages mentioned** → find the relevant Vue components, composables, and stores
- **Function or class names** → use `semantic_search` to understand the context

For this monorepo, remember the structure:
- `bff/src/modules/` — BFF modules by domain (instance, application, revision, vpc, etc.)
- `client/src/pages/` — Vue pages (application/, network/)
- `client/src/composables/` — feature composables with TanStack Query hooks
- `client/src/apis/index.ts` — all API functions in a single file
- `client/src/utils/` — utility functions including UI-to-API payload converters

### 4. Root Cause Analysis

Synthesize your findings into a clear analysis:
- **Direct cause**: What specifically triggers the issue?
- **Contributing factors**: Configuration, timing, environment, API changes
- **Impact scope**: Which users/environments/flows are affected?
- **Confidence level**: Are you certain, or is this a hypothesis that needs verification?

### 5. Present Fix Plan and Get Approval

After identifying the root cause, **do not implement changes immediately**. Instead, present a fix plan for the user to review:

```markdown
## Fix Plan for [TICKET-ID]

### Root Cause Summary
Brief recap of what's causing the issue

### Proposed Changes
1. **file/path.ts** — Description of what will change and why
2. **another/file.ts** — Description of what will change and why

### Approach
- Explanation of the fix strategy
- Any trade-offs or alternatives considered

### Risk Assessment
- Low/Medium/High — why
- Side effects to watch for
```

Wait for the user to approve, request modifications, or ask questions before proceeding. The user might want to adjust the scope, suggest a different approach, or add extra requirements.

### 6. Implement the Fix (after approval)

Once the user approves the plan, implement the fix:

- Make focused, minimal changes — fix the bug, don't refactor the neighborhood
- Follow existing code patterns and conventions (see copilot-instructions.md)
- For BFF changes: use `@CommonData()` decorator, `BaseData` typing, and `AppService` for endpoints
- For client changes: use TanStack Query patterns, `QUERY_KEY` constants, and `createHttpClient()`

After making changes:
- Check for lint/type errors
- Suggest verification steps the user can follow

### 7. Present Results

For each ticket analyzed, present your findings in this format:

```markdown
## [TICKET-ID] Summary

**Status**: Current Status | **Priority**: Priority Level

### Issue Description
Brief summary of the problem

### Root Cause
What's causing the issue and why

### Affected Code
- file/path.ts — what's relevant here

### Changes Made
1. What was changed and why
2. Additional changes...

### Verification Steps
- How to verify the fix works
```

## Multiple Tickets

When given multiple ticket IDs:
1. Analyze each individually first
2. Look for common root causes across tickets
3. Suggest a prioritization order if relevant
4. Identify opportunities for batch fixes

## Tips

- Always read the ticket comments — engineers often leave critical debugging context there
- Check git history of affected files (`git log --oneline -10 -- path/to/file`) to see recent changes that may have introduced the bug
- If the ticket mentions a specific environment (stage/real), keep that in mind when looking at endpoint resolution and feature flags
- When the ticket references a UI issue, trace from the Vue component → composable → API function → BFF controller → BFF service to understand the full data flow
