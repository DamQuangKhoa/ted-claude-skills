---
name: flava-jira-wiki-check
description: Analyze Jira tickets together with linked Confluence wiki pages, reconcile ticket vs documentation, identify root causes, and produce a detailed plan file (.claude/flava-jira-wiki-check/plans/{TICKET-ID}-PLAN.md) before any implementation. Use whenever the user provides a Jira key (LYCC-1234, CLOUDQA-12345, etc.) and wants investigation that must include wiki/Confluence context—phrases like "check ticket and wiki", "Jira plus Confluence", "does the ticket match the doc", "wiki says X but ticket says Y", "root cause using the design page", or when they paste a ticket that references a Confluence URL. Also use when flava-jira-check would apply but the user explicitly wants Confluence MCP used on pages linked or named in the ticket. Workflow order is mandatory—fetch Jira, fetch relevant Confluence, analyze (ticket + wiki + codebase), write plan file, wait for user confirmation of the plan, then create todo tasks; do not create editor todos before plan confirmation. Do not edit code until the user explicitly approves implementation or asks you to execute the plan (same approval gate as flava-jira-check).
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
| **4** | **Root cause + detailed plan** — Combine ticket, wiki, and codebase (see §3–5). **Write the plan to a file** including a **mandatory unit-test plan** (see §4.5 + §5). |
| **5** | **Confirm plan with user** — Point the user to the plan file; ask explicitly for confirmation or revisions. **Stop here** until the user confirms (or adjusts) the plan. Ambiguous replies ("ok", "thanks") are **not** confirmation—ask a clear yes/no whether the plan is approved as written. |
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

## 4.5. Unit-test plan (mandatory)

Every ticket investigation **must** include a unit-test plan as part of the fix plan — this is non-negotiable, even for tiny bug fixes or doc-vs-code reconciliations. The plan should answer:

- **Which test file(s)** will be added or extended (existing `*.spec.ts` / `*.test.ts` next to the changed code, or a new sibling spec file matching the repo's pattern)?
- **Which test framework** applies — Vitest for client/Vue, Jest for NestJS BFF — and which existing setup/utilities to reuse.
- **Cases to cover:**
  - At least one test that **reproduces the bug** or encodes the wiki-defined behavior (would fail before the fix, pass after).
  - Regression cases for edge inputs, error paths, and any branches touched by the fix.
  - For BFF: service-level tests with mocked `HttpService` / `AppService`; controller-level tests only when the controller logic changes.
  - For client: composable / util / store tests with mocked APIs; component tests only when component logic changes.
- **Mocks and fixtures** required (upstream API responses, wiki-derived expected payloads, etc.).
- **How to run** the tests locally (e.g. `pnpm --filter <pkg> run test:ci -- <pattern>`).

If the changed code is genuinely untestable in isolation (rare — e.g. pure type-only changes, configuration, or doc-only updates), state this **explicitly** in the plan with the reason and propose an alternative verification (integration test, manual repro for QA). Do not silently skip the unit-test plan.

This section **must appear** in the plan file written in §5.

---

## 5. Write plan file (before todos)

**Always write the investigation plan to a markdown file** under:

```
.claude/flava-jira-wiki-check/plans/{TICKET-ID}-PLAN.md
```

Create the `plans` directory if it does not exist.

Examples:

- `.claude/flava-jira-wiki-check/plans/LYCC-11471-PLAN.md`
- `.claude/flava-jira-wiki-check/plans/CLOUDQA-12345-PLAN.md`

For **multiple tickets**, use one file per ticket unless the user asks for a single merged plan — then use `.claude/flava-jira-wiki-check/plans/{PRIMARY-TICKET-ID}-PLAN.md` and list all keys in the title.

### File contents

Use this structure. Include a short **Wiki summary** subsection citing what you read (page title / id) and how it relates to the ticket. Record any **user-stated scope** (inclusions/exclusions) near the top.

```markdown
# Investigation: [TICKET-ID] + Confluence

**Product / area:** [if known]
**Scope (this plan):** [what this plan covers]
**Out of scope (this plan):** [explicit exclusions, if any]

## Wiki consulted
- **Pages:** [titles or IDs with links]
- **Relevant expectations from doc:** [bullets]

## Ticket summary
[Brief — table or bullets: key, summary, status, assignee]

## Root cause
[Analysis incorporating Jira + wiki + code]

## Detailed plan
1. **[file or area]** — [what to change and why]
2. ...

## Unit-test plan (mandatory)
- **Framework:** [Vitest / Jest]
- **Test file(s):** [paths to add or extend]
- **Cases:**
  - [ ] Reproduces the bug / encodes the wiki-defined behavior (fails on current code)
  - [ ] Regression / edge case 1
  - [ ] Regression / edge case 2
- **Mocks / fixtures:** [what to stub]
- **Run command:** `pnpm --filter <pkg> run test:ci -- <pattern>`

## Risks / verification
| Risk | Mitigation |
|------|------------|
| ... | ... |

- [ ] Verification checklist items

## Plan confirmation
Please confirm this plan (or say what to revise). **Todos will be created only after you confirm.** Code changes only when you explicitly ask to implement.
```

### After writing the file

1. Tell the user the file path (e.g. `.claude/flava-jira-wiki-check/plans/LYCC-11471-PLAN.md`) and give a **short summary** in chat — do not paste the full plan inline unless the user asks.
2. If the user revises scope or plan content, **update the same plan file** before asking for confirmation again.

**Do not** create editor todos yet. **Do not** apply code patches yet.

---

## 6. After user confirms — create todo tasks

When the user **clearly confirms** the plan (or confirms a revised version):

1. Use the editor todo tool to break the **approved** plan into small, verifiable items (ordered, actionable). **Always include explicit todo item(s) for writing and running the unit tests** from the plan's Unit-test plan section.
2. Share the todo list in the reply so the user sees what was registered.

If the user revises the plan, update `.claude/flava-jira-wiki-check/plans/{TICKET-ID}-PLAN.md` first, get confirmation again, then create todos.

---

## 7. Implementation (explicit approval only)

Same **approval gate** as flava-jira-check:

- **Todo creation ≠ permission to edit code.**
- Implement only when the user explicitly asks (e.g. "implement", "apply the plan", "go ahead and fix it").

Then execute todos with minimal, focused changes. **Write the planned unit tests in the same change set as the fix** — confirm at least one test reproduces the bug before the fix and passes after. Run lint/type checks **and** the unit tests for the touched package (`pnpm --filter <pkg> run test:ci`) on touched files; summarize results with ticket id, wiki alignment, changes, test results, and verification steps.

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
