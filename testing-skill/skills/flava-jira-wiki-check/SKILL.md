---
name: flava-jira-wiki-check
description: Analyze Jira tickets together with linked Confluence wiki pages, reconcile ticket vs documentation, identify root causes, and produce a detailed plan before any implementation. Use whenever the user provides a Jira key (LYCC-1234, CLOUDQA-12345, etc.) and wants investigation that must include wiki/Confluence context—phrases like "check ticket and wiki", "Jira plus Confluence", "does the ticket match the doc", "wiki says X but ticket says Y", "root cause using the design page", or when they paste a ticket that references a Confluence URL. Also use when flava-jira-check would apply but the user explicitly wants Confluence MCP used on pages linked or named in the ticket. Workflow order is mandatory—fetch Jira, fetch relevant Confluence, analyze (ticket + wiki + codebase), present plan, wait for user confirmation of the plan, then create todo tasks; do not create editor todos before plan confirmation. Do not edit code until the user explicitly approves implementation or asks you to execute the plan (same approval gate as flava-jira-check).
---

# Flava Jira + Wiki Check

Investigate Jira issues using **both** the issue record and **Confluence documentation** referenced (or implied) by the ticket, then synthesize root cause and a fix plan. This extends **flava-jira-check** with a required **Confluence MCP** pass so analysis can compare reported behavior, acceptance criteria, and design/wiki content.

## End-to-end workflow (required order)

Work strictly in this sequence. **Do not skip the Confluence step** when the ticket contains or strongly implies a wiki link; if there is no link, document that and use targeted `confluence_search` only when it would materially reduce ambiguity.

| Step | Action |
|------|--------|
| **1** | **User input** — Capture the Jira key(s) and any optional hints (environment, expected doc title). |
| **2** | **Jira MCP** — Fetch full issue details (`jira_get_issue` on `user-jira`; read the tool schema before calling). |
| **3** | **Confluence MCP** — Resolve and read wiki pages tied to the ticket (see §2). |
| **4** | **Root cause + detailed plan** — Combine ticket, wiki, and codebase (see §3–5). |
| **5** | **Confirm plan with user** — Present the plan; ask explicitly for confirmation or revisions. **Stop here** until the user confirms (or adjusts) the plan. Ambiguous replies ("ok", "thanks") are **not** confirmation—ask a clear yes/no whether the plan is approved as written. |
| **6** | **Create todo tasks** — **Only after step 5 confirmation:** use the editor todo tool to create the checklist derived from the approved plan. |
| **7** | **Implement (optional)** — **Only after explicit approval to implement** (same rule as flava-jira-check): execute todos with minimal code changes. If the user only confirmed the plan for tracking purposes and did not ask to implement, do **not** modify code. |

---

## 1. Fetch Jira ticket details

For each issue key:

```
jira_get_issue(issue_key="LYCC-1234", fields="*all", comment_limit=10)
```

(Adjust `fields` / `expand` per schema; use `renderedFields` in `expand` if you need rendered HTML and the tool supports it.)

Extract and note:

- Summary, description, acceptance criteria (including custom fields)
- Status, priority, labels, components
- Comments (repro steps, links, stack traces)
- **Any Confluence URLs** in description, comments, or fields (see §2)
- Linked issues (blocks, relates to, epic)

---

## 2. Confluence MCP — wiki from the ticket

**Always read tool schemas** under `user-confluence` before calling (`confluence_get_page`, `confluence_search`, etc.).

### 2.1 Find wiki references

From the Jira payload, collect:

- Explicit links: `atlassian.net/wiki/...`, `/pages/`, `pageId=`, short links, or "Confluence" mentions with page titles
- Epic or parent issues that might hold the canonical spec link (follow if needed via another `jira_get_issue`)

Parse **page ID** from URLs when present, e.g.  
`.../wiki/spaces/TEAM/pages/123456789/Title` → `page_id=123456789`.

### 2.2 Fetch page content

Prefer **`confluence_get_page`**:

- With `page_id` when known
- Otherwise `title` + `space_key` when the ticket names them exactly

Use `convert_to_markdown: true` by default for readability; switch to HTML only if macros or tables are missing in markdown and you need them (note token cost in the skill: keep excerpts focused).

If the link is broken or unclear, use **`confluence_search`** with CQL or keywords (and optional `spaces_filter`) to find the right page; prefer the smallest set of results and summarize disambiguation for the user if multiple pages match.

### 2.3 What to extract from the wiki

- Intended behavior, APIs, data models, rollout notes
- Known limitations, edge cases, or "out of scope" statements
- Diagrams or tables—summarize; don't paste huge blobs
- **Gaps vs ticket**: Does the ticket contradict the doc, omit required steps, or describe a flow the doc marks deprecated?

If **no** wiki exists or none can be found, state that plainly and proceed with Jira + codebase analysis; do not block the workflow unless the user requires a doc.

---

## 3. Search the codebase

Same methodology as **flava-jira-check**: grep for errors/endpoints, `codebase_search` for flows, trace BFF → client.

Use **wiki + ticket** together to prioritize where to look (e.g. module names, feature flags, API paths mentioned only on the wiki page).

Monorepo pointers (align with flava-jira-check):

- `bff/src/modules/`
- `client/src/pages/`, `client/src/composables/`, `client/src/apis/`, `client/src/utils/`

---

## 4. Root cause analysis

Synthesize **three** sources: Jira, Confluence, code.

- **Direct cause** — What fails and where?
- **Doc vs reality** — Does implementation match wiki? Is the ticket valid per spec?
- **Contributing factors** — Config, env, race, API drift, doc stale
- **Impact scope** — Users, regions, features
- **Confidence** — Confirmed vs hypothesis (and what would verify it)

---

## 5. Present detailed plan (before todos)

Output a structured plan for user review. Include a short **Wiki summary** subsection citing what you read (page title / id) and how it relates to the ticket.

```markdown
## Investigation: [TICKET-ID] + Confluence

### Wiki consulted
- **Pages:** [titles or IDs]
- **Relevant expectations from doc:** [bullets]

### Ticket summary
[Brief]

### Root cause
[Analysis incorporating Jira + wiki + code]

### Detailed plan
1. **[file or area]** — [what to change and why]
2. ...

### Risks / verification
- Risks: ...
- How to verify: ...

### Plan confirmation
Please confirm this plan (or tell me what to revise). **Todos will be created only after you confirm.**
```

**Do not** create editor todos yet. **Do not** apply code patches yet.

---

## 6. After user confirms — create todo tasks

When the user **clearly confirms** the plan (or confirms a revised version):

1. Use the editor todo tool to break the **approved** plan into small, verifiable items (ordered, actionable).
2. Share the todo list in the reply so the user sees what was registered.

If the user revises the plan, update the plan text first, get confirmation again, then create todos.

---

## 7. Implementation (explicit approval only)

Same **approval gate** as flava-jira-check:

- **Todo creation ≠ permission to edit code.**
- Implement only when the user explicitly asks (e.g. "implement", "apply the plan", "go ahead and fix it").

Then execute todos with minimal, focused changes; run lint/type checks on touched files; summarize results with ticket id, wiki alignment, changes, and verification steps.

---

## Multiple tickets

For multiple keys:

1. Jira fetch each; Confluence pass per ticket (shared pages deduplicated)
2. Note common root causes or shared wiki sources
3. One combined plan per ticket or one merged plan if a single change fixes several—still **one confirmation step** per deliverable the user expects (clarify if needed)

---

## Tips

- Read Jira comments—engineers often paste the canonical wiki link there, not in the description.
- If wiki and ticket disagree, call it out in the plan and recommend either code fix or doc update (or both).
- Prefer quoting **short** excerpts from Confluence; link identifiers (page id / title) so humans can open the source.
- When Confluence search returns many hits, narrow by space from the URL or ticket component before deep-reading.
