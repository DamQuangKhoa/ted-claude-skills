---
name: flava-jira-create-dev-ticket
description: Create and validate LYCC Jira tickets for developer/product work using the Jira MCP (create issue, link to epic, assign, components, priority, labels). Default assignee to the reporter (creator) unless the user names someone else. Default epic link to **Flava operational task** (resolve key via Jira search—currently LYCC-2141—then set customfield_10108). Components include Load Balancer, Vector search, DBS for Redis, DBS for Cassandra, and other product components. Use whenever the user wants to open a new dev ticket, file feature/improvement/bug work in Jira, set component to Load Balancer or any product component, or duplicate dev-style tickets like LYCC-9844. Also use for phrases like "create a Jira for dev", "file a feature ticket", "open a product backlog item", "create an improvement ticket", "create a bug ticket for Load Balancer", or when the user pastes a reference dev ticket URL. Prefer this skill over generic Jira advice so fields match team conventions.
---

# Flava Jira — Create Dev Ticket

Help the user create **LYCC** issues that match **developer/product** conventions: correct **component**, **Epic link**, **issue type**, **assignee**, **priority**, and **description structure**. Use the **user-jira** MCP tools (read each tool's schema before calling).

## Why this exists

Mis-set fields (wrong component, missing epic, wrong issue type) create noise for the team. This workflow mirrors real tickets such as [LYCC-9844](https://jira.workers-hub.com/browse/LYCC-9844): **Improvement** in **LYCC**, **Load balancer** component, linked to the epic **Flava operational task**, with an **assignee** and structured description.

## Before you create — collect inputs

Ask for anything missing. Minimum useful set:

| Input | Notes |
|-------|-------|
| **Summary** | Short title describing the feature, improvement, or bug. |
| **Description** | Use the [structured template](#description-template) below. Gather: summary of the work, background/context, UI plan (optional), API plan (optional), contact points. |
| **Issue type** | `Task`, `Story`, `Bug`, or `Improvement`. Default: `Task` unless context clearly indicates otherwise (e.g. user says "bug" → `Bug`, "new feature" → `Story`, "improvement" → `Improvement`). |
| **Component** | Choose from common dev components (see list below). Ask if unclear. **No default** — always confirm with the user. |
| **Assignee** | **Default:** same as **reporter** (whoever creates the issue). If the user names someone else, use that person only. |
| **Epic** | **Default:** `Flava operational task` (as of team convention this is **`LYCC-2141`** — confirm with a quick search if unsure). If the user names a different epic, use that key or resolve it by summary. |
| **Priority** | Low / Medium / High (default: `Medium`). |
| **Labels** | Optional. Common labels: `cloud_web_dev`, `ui_improvement`, `api`. |

**Project** is **`LYCC`** unless the user explicitly asks for another project.

## Component list

Common components for dev/product tickets (choose one or more):

- `Load balancer`
- `Vector search`
- `DBS for Redis`
- `DBS for Cassandra`
- `Flava Function`
- `SSK`
- `Common`

If the user mentions a component not in this list, use their exact wording and let Jira validate it.

## Description template

Structure the description using Jira wiki markup (h3 headings). Only include sections that are relevant — omit empty ones:

```
h3. Summary

[Brief description of what this ticket is about and what it delivers.]

h3. Background

[Context, motivation, why this work is needed.]

h3. Plan (UI)

[UI/frontend plan, design links (Figma, wiki), or N/A if backend-only.]

h3. Plan (API)

[Backend/API plan, relevant wiki pages or design docs, or N/A if frontend-only.]

h3. Contact Point

[Names or usernames of the key people involved / point of contact.]
```

**Example** (from LYCC-9844):
```
h3. Summary

Offers ALB log functionality. Provides a way for users to view logs before completing the response.

h3. Background

Provide the Opensearch tab, and click the tab to go to the Opensearch dashboard.
View the information (log) of the user's ALB on the dashboard.

h3. Plan (UI)

[Operational_tasks_17|https://wiki.workers-hub.com/pages/viewpage.action?pageId=3902335462]
ref. design figma: [Load balancer – Figma|https://www.figma.com/...]

h3. Plan (API)

[Operational_tasks_17|https://wiki.workers-hub.com/pages/viewpage.action?pageId=3902335462]

h3. Contact Point

lee.min.hee
Shimizu Rei
```

## Optional: confirm or discover context

1. **Reference ticket** — If the user gives a URL or key (e.g. `LYCC-9844`), call `jira_get_issue` with `fields="*all"`. Use it as a **template** for defaults (epic, component, naming style), not as something to copy verbatim.

2. **Duplicate search** — If the user cares about duplicates, run `jira_search` with a tight JQL by component and keywords in summary, `project = LYCC`, limited results.

3. **Default dev epic** — Resolve the canonical epic by name with **`jira_search`**, e.g.:
   `project = LYCC AND issuetype = Epic AND summary ~ "Flava operational task"`
   Use the returned **`key`** when setting **`customfield_10108`** via **`jira_update_issue`** (see Epic Link section). That key is the source of truth for the visible Epic Link on the LYCC board.

4. **Epic list (browse)** — Broader JQL: `project = LYCC AND issuetype = Epic AND status != Done` when the user wants to pick from alternatives.

5. **Assignee** — If the user named a specific assignee, resolve with `jira_get_user_profile` or a targeted search. Avoid guessing email addresses. If they did **not** name someone else, plan to set assignee to **reporter** after create.

## Create the issue

Call **`jira_create_issue`** with:

- `project_key`: `LYCC` (unless user chose otherwise).
- `summary`, `issue_type`, `description` as agreed (using the template above).
- `components`: the confirmed component(s), comma-separated.
- `assignee`: set **only** if the user explicitly asked to assign to someone other than themselves. Otherwise pass **`null`** / omit and fix in the next step — this avoids the project picking a **default assignee** who is not the reporter.
- `is_description_markdown`: `false` (use Jira wiki markup / plain text unless the user specifically asks for Markdown).

Put **priority** and **labels** in **`additional_fields`** when not top-level parameters, e.g.:

- `priority`: `{ "name": "Medium" }`
- `labels`: `["cloud_web_dev", "..."]`

## Assignee = reporter (default)

When the user did **not** specify a different assignee, **assign the issue to the reporter** (creator) so `reporter` and `assignee` match.

1. After **`jira_create_issue`**, call **`jira_get_issue`** on the new key with `reporter` and `assignee` in `fields`.
2. If **assignee already equals reporter** (same account/email), skip.
3. Otherwise call **`jira_update_issue`** with `fields` containing **`assignee`** set to the reporter's identifier — prefer **`reporter.email`** from the response; fallback to display name or account id if email is missing.

Skip this block only when the user explicitly chose a different assignee on create.

## Link to Epic (Epic Link field in UI)

After the issue is created (and after **Assignee = reporter** if applicable), read the new issue **key** from the response.

**Default epic:** **`Flava operational task`** (Epic issue key is typically **`LYCC-2141`**).

1. Resolve the epic **key** with **`jira_search`**, e.g.:
   `project = LYCC AND issuetype = Epic AND summary ~ "Flava operational task"`
   Use the single **`key`** returned. If zero or multiple matches, ask the user which epic to use. If they already gave a different epic key or name, resolve that epic instead.

2. **Set the Epic Link that the Jira UI shows** (orange pill / "Epic Link" on the issue):
   On **LYCC (Flava Console)**, this field is **`customfield_10108`**, stored as the **Epic's issue key** (e.g. `LYCC-2141`). The UI renders it as the epic's title.

   Call **`jira_update_issue`** with:

   ```text
   fields: { "customfield_10108": "<epic_key>" }
   ```

   Example: `{ "customfield_10108": "LYCC-2141" }`.

   **Why not only `jira_link_to_epic`?** In LYCC, `jira_link_to_epic` may return success while **`customfield_10108` stays empty**, so the Epic Link panel looks blank. Always set **`customfield_10108`** via **`jira_update_issue`** for LYCC — it is the source of truth for the visible Epic Link.

3. **Optional:** `jira_link_to_epic` may still be called for Agile API parity, but do not rely on it alone.

**Other projects:** If `project_key` is not `LYCC`, discover the Epic Link field id from **`jira_get_issue`** on any issue that already has an epic (`fields="*all"`) — do not assume `10108`.

## Verify

Call **`jira_get_issue`** on the new key with fields: summary, status, assignee, components, priority, `customfield_10108` (must equal the epic key, e.g. `LYCC-2141`), and optionally `customfield_10104` (epic name string).

## Present to the user

Return:

- **Browse URL**: `https://jira.workers-hub.com/browse/<KEY>`
- **Key**, **issue type**, **assignee**, **component(s)**, **epic** (name and key), **priority**, **status**.

## Guardrails

- **Component required** — Never create a dev ticket without a component. If the user hasn't specified one, ask before creating.
- **Read-only / errors** — If the MCP reports read-only or unavailable client, stop and tell the user; do not fake ticket keys.
- **Epic** — Unless the user asked for a **different** epic, link to **`Flava operational task`** (resolve key via search; usually `LYCC-2141`). Only ask which epic to use when the default epic cannot be found or the user's request clearly belongs under another epic.
- **Assignee** — Do not leave self-filed tickets on a project default assignee who is not the reporter; apply **Assignee = reporter** unless the user chose someone else.
- **Secrets** — Do not put credentials, tokens, or internal-only URLs into descriptions unless the user explicitly wants them.

## Relationship to other skills

- **flava-jira-check**: investigate existing tickets and fix code.
- **flava-jira-create-sre-ticket**: create SRE/infra-ops tickets with the SRE component and SRE Temporary Epic.
- **flava-jira-create-dev-ticket**: create developer/product tickets (Load Balancer, Vector search, DBS, etc.) linked to Flava operational task.

Use `flava-jira-create-dev-ticket` for all feature, improvement, and bug work in product components. Use `flava-jira-create-sre-ticket` for infra/ops work.
