---
name: flava-jira-check
description: Analyze Jira tickets, identify root causes, and (after explicit approval) implement fixes in the LYCC flava-console codebase. Use whenever the user provides a Jira ticket ID (like LYCC-1234, CLOUDQA-12345) and wants to investigate, check, debug, analyze, or fix an issue — even if they just paste a ticket number without further instructions. Also triggers for phrases like "check this ticket", "investigate this bug", "what's this Jira about", "fix this issue", or "root cause analysis". Supports both single and multiple ticket IDs. After delivering a fix plan and todo list, do not edit code until the user approves or explicitly asks to implement.
---

# Flava Jira Check

Analyze Jira tickets to understand issues, identify root causes, and—**only after the user approves**—implement fixes in the flava-console codebase. This skill bridges Jira context with codebase investigation; code changes require an explicit go-ahead after the plan and todos are shared.

## End-to-end workflow (required order)

Deliver work in this sequence. **Final user-facing output** after investigation must include **plan** and **todo tasks** (see §5–6).

**Approval gate (mandatory):** After §5–6, **do not modify any code** — no `apply_patch`, no file edits, no commits — unless the user **explicitly approves** the plan or **explicitly asks you to implement** (e.g. “approved”, “go ahead”, “implement it”, “apply the plan”, “fix it now”). If the user is silent, only asked for analysis, or has not approved, **stop** and wait. Ambiguous replies (“ok”, “thanks”) are **not** approval to edit code; ask briefly if they want you to proceed with implementation.

| Step | Action |
|------|--------|
| **1** | **Check Jira ticket** — Fetch full issue details (see §1). |
| **2** | **Root cause analysis** — Codebase search + synthesis (see §3–4). |
| **3** | **Plan to fix** — Concrete file-level plan, risks, verification (see §5). |
| **4** | **Todo tasks** — Break the plan into a checklist of small, verifiable tasks (see §6). |
| **5** | **Stop for approval** — Present plan + todos; do **not** change code until the user approves or requests implementation (see above). |
| **6** | **Implement** — Only after approval: execute todos; minimal, focused changes (see §7). |
| **7** | **Results** — After implementation: summary with ticket id, root cause, changes, verification (see §8). |

If the user only wants analysis, stop after **§4** (and step **5** in the table: no code changes).

---

## 1. Fetch ticket details

For each provided Jira ticket ID, use the **Jira MCP** tool `jira_get_issue` (read the tool schema under the `user-jira` MCP descriptors before calling). Example:

```
jira_get_issue(issue_key="LYCC-1234", fields="*all", comment_limit=10)
```

Extract and note:

- **Summary & description**: What's the reported problem?
- **Status & priority**: How urgent is this?
- **Labels & components**: Which part of the system?
- **Comments**: Often contain reproduction steps, stack traces, or clues from other engineers
- **Linked issues**: Related tickets that provide additional context

### 2. Analyze the ticket

From the ticket information, identify:

- **Error messages or stack traces** — these are your best leads for codebase search
- **Reproduction steps** — helps understand the user flow
- **Screenshots or logs** — visual clues about what's wrong
- **Environment details** — stage vs real, specific regions affected
- **Related tickets** — patterns across multiple reports

### 3. Search the codebase

Based on what you found in the ticket, search the codebase methodically:

- **Error messages** → use `grep` to find where they originate
- **API endpoints mentioned** → trace the request flow through BFF controllers → services → upstream calls
- **Components/pages mentioned** → find the relevant Vue components, composables, and stores
- **Function or class names** → use `codebase_search` to understand the context

For this monorepo, remember the structure:

- `bff/src/modules/` — BFF modules by domain (instance, application, revision, vpc, etc.)
- `client/src/pages/` — Vue pages (application/, network/)
- `client/src/composables/` — feature composables with TanStack Query hooks
- `client/src/apis/` — API modules (e.g. `apis/index.ts` or domain-specific api files)
- `client/src/utils/` — utility functions including UI-to-API payload converters

### 4. Root cause analysis

Synthesize your findings into a clear analysis:

- **Direct cause**: What specifically triggers the issue?
- **Contributing factors**: Configuration, timing, environment, API changes
- **Impact scope**: Which users/environments/flows are affected?
- **Confidence level**: Are you certain, or is this a hypothesis that needs verification?

---

## 5. Present fix plan

After identifying the root cause, produce a **fix plan** for review:

```markdown
## Fix Plan for [TICKET-ID]

### Root cause summary
Brief recap of what's causing the issue

### Proposed changes
1. **file/path.ts** — Description of what will change and why
2. **another/file.ts** — Description of what will change and why

### Approach
- Explanation of the fix strategy
- Any trade-offs or alternatives considered

### Risk assessment
- Low/Medium/High — why
- Side effects to watch for
```

**Do not edit the codebase after posting this plan** unless the user has already given explicit approval to implement (see **End-to-end workflow**).

---

## 6. Create todo tasks from the plan

Translate **Proposed changes** and **Approach** into a **numbered or bulleted todo list** of small, completable items, for example:

- Update column definitions / enums for the feature
- Wire filter keys and API params in the composable
- Align Vue template slots and row mapping with new column keys
- Run lint on touched files; manual verification steps

Use the editor todo tool when available to track these items **after the user approves implementation**. The user should receive **both** the markdown plan (§5) **and** this todo list **before** any code changes.

**After §5–6:** If there is **no** explicit approval to implement, **stop**. Do not apply patches or modify files.

---

## 7. Implement the fix

**Only enter this section after the user approves the plan or explicitly asks you to implement** (see **Approval gate** in the workflow table). Then execute the todos:

- Make focused, minimal changes — fix the bug, don't refactor the neighborhood
- Follow existing code patterns and conventions (see copilot-instructions.md)
- For BFF changes: use `@CommonData()` decorator, `BaseData` typing, and `AppService` for endpoints
- For client changes: use TanStack Query patterns, `QUERY_KEY` constants, and `createHttpClient()`

After making changes:

- Check for lint/type errors on edited files
- Suggest verification steps the user can follow

---

## 8. Present results

For each ticket analyzed, present findings in this format:

```markdown
## [TICKET-ID] Summary

**Status**: Current Status | **Priority**: Priority Level

### Issue description
Brief summary of the problem

### Root cause
What's causing the issue and why

### Affected code
- file/path.ts — what's relevant here

### Plan & todos (reference)
- Link back to the fix plan and the todo items completed

### Changes made
1. What was changed and why
2. Additional changes...

### Verification steps
- How to verify the fix works
```

---

## Multiple tickets

When given multiple ticket IDs:

1. Analyze each individually first
2. Look for common root causes across tickets
3. Suggest a prioritization order if relevant
4. Identify opportunities for batch fixes
5. One combined plan/todo list per ticket or a merged list if a single fix addresses several tickets

## Tips

- Always read the ticket comments — engineers often leave critical debugging context there
- Check git history of affected files (`git log --oneline -10 -- path/to/file`) to see recent changes that may have introduced the bug
- If the ticket mentions a specific environment (stage/real), keep that in mind when looking at endpoint resolution and feature flags
- When the ticket references a UI issue, trace from the Vue component → composable → API function → BFF controller → BFF service to understand the full data flow
