---
name: flava-jira-create-sre-ticket
description: Create and validate LYCC Jira tickets for SRE work using the Jira MCP (create issue, link to epic, assign, components, priority, labels). Default assignee to the reporter (creator) unless the user names someone else. Default epic link to the Epic whose summary is **SRE | Temporary Epic** (resolve key via Jira search—currently LYCC-9350—then `jira_link_to_epic`). Use whenever the user wants to open a new SRE ticket, file infra/ops work in Jira, set component to SRE, attach the SRE temporary epic, assign someone, or duplicate tickets like LYCC-9796. Also use for phrases like "create a Jira for SRE", "file LYCC ticket", "open backlog item with SRE component", or when the user pastes a reference ticket URL. Prefer this skill over generic Jira advice so fields match team conventions.
---

# Flava Jira — Create SRE Ticket

Help the user create **LYCC** issues that match **SRE** conventions: correct **component**, **Epic link**, **assignee**, **priority**, and **description**. Use the **user-jira** MCP tools (read each tool’s schema before calling).

## Why this exists

Mis-set fields (wrong component, missing epic, typo in assignee) create noise for the team. This workflow mirrors real tickets such as [LYCC-9796](https://jira.workers-hub.com/browse/LYCC-9796): **Task** in **LYCC**, **SRE** component, linked to the epic **SRE | Temporary Epic**, with an **assignee**.

## Before you create — collect inputs

Ask for anything missing. Minimum useful set:

| Input | Notes |
|--------|--------|
| **Summary** | Short title; many SRE tasks use prefix `SRE \| …` (optional but consistent with reference tickets). |
| **Description** | What to do, impact, links, timelines. |
| **Issue type** | Usually `Task`; use `Bug` or `Story` if the user says so. |
| **Assignee** | **Default:** same as **reporter** (whoever creates the issue—e.g. Ted files → Ted is assignee). If the user names someone else, use that person only. |
| **Epic** | **Default:** link to the Epic whose **summary/title** is **`SRE | Temporary Epic`** (as of team convention this is **`LYCC-9350`**—confirm with a quick search if unsure). If the user names a different epic, use that key or resolve it by summary. |
| **Priority** | e.g. Low / Medium / High — map into `additional_fields` (see Create step). |
| **Labels** | Optional list. |

**Project** is **`LYCC`** unless the user explicitly asks for another project.

**Component** defaults to **`SRE`** (comma-separated if multiple: e.g. `SRE` only unless they request more).

## Optional: confirm or discover context

1. **Reference ticket** — If the user gives a URL or key (e.g. `LYCC-9796`), call `jira_get_issue` with `fields="*all"` (or at least summary, description, components, assignee, priority, issuetype, and epic-related custom fields). Use it as a **template** for defaults (epic, component, naming style), not as something to copy verbatim without confirmation.

2. **Duplicate search** — If the user cares about duplicates, run `jira_search` with a tight JQL, e.g. same component and keywords in summary, `project = LYCC`, limited results.

3. **Default SRE epic** — Resolve the canonical epic by name with **`jira_search`** (e.g. `project = LYCC AND issuetype = Epic AND summary ~ "SRE | Temporary Epic"`). Use the returned **`key`** when setting **`customfield_10108`** via **`jira_update_issue`** (see **Link to Epic**). That is what makes the **Epic Link** UI match [LYCC-9796](https://jira.workers-hub.com/browse/LYCC-9796).

4. **Epic list (browse)** — Broader JQL: `project = LYCC AND issuetype = Epic AND status != Done` (adjust status as needed) when the user wants alternatives.

5. **Assignee** — If the user named a specific assignee, resolve with `jira_get_user_profile` or a targeted search workflow your MCP supports; avoid guessing email addresses. If they did **not** name someone else, plan to set assignee to **reporter** after create (see below).

## Create the issue

Call **`jira_create_issue`** with:

- `project_key`: `LYCC` (unless user chose otherwise).
- `summary`, `issue_type`, `description` as agreed.
- `components`: `SRE` unless the user specified additional components (comma-separated).
- `assignee`: set **only** if the user explicitly asked to assign to someone other than themselves (reporter). Otherwise pass **`null`** / omit and fix in the next step—this avoids the project picking a **default assignee** who is not the reporter.
- `is_description_markdown`: `true` **only** if the user asked for Markdown rendering in Jira; otherwise default false (raw Jira markup / plain text per MCP behavior).

Put **priority** and **labels** in **`additional_fields`** when not top-level parameters, e.g.:

- `priority`: `{ "name": "High" }`
- `labels`: `["sre", "..."]`

Do **not** rely on hard-coded custom field ids in the skill text for epic on create unless `jira_create_issue` docs or a live `jira_get_issue` on the same project shows they are required; prefer linking in the next step.

## Assignee = reporter (default)

When the user did **not** specify a different assignee, **assign the issue to the reporter** (creator) so `reporter` and `assignee` match—e.g. Ted creates → Ted is assignee.

1. After **`jira_create_issue`**, call **`jira_get_issue`** on the new key with `reporter` and `assignee` in `fields` (or `fields="*all"`).
2. If **assignee already equals reporter** (same account/email), skip.
3. Otherwise call **`jira_update_issue`** with `fields` containing **`assignee`** set to the reporter’s identifier the MCP accepts—prefer **`reporter.email`** from the response; fallback to display name or account id if email is missing.

Skip this block only when the user explicitly chose a different assignee on create (then leave that assignee as set).

## Link to Epic (Epic Link field in UI)

After the issue is created (and after **Assignee = reporter** if applicable), read the new issue **key** from the response.

**Default epic (SRE backlog):** **`SRE | Temporary Epic`** (Epic issue key is typically **`LYCC-9350`**).

1. Resolve the epic **key** with **`jira_search`**, e.g.  
   `project = LYCC AND issuetype = Epic AND summary ~ "SRE | Temporary Epic"`  
   Use the single **`key`** returned. If zero or multiple matches, ask the user which epic to use. If they already gave a different epic key or name, resolve that epic instead.

2. **Set the Epic Link that the Jira UI shows** (orange pill / “Epic Link” on the issue, like [LYCC-9796](https://jira.workers-hub.com/browse/LYCC-9796)):  
   On **LYCC (Flava Console)**, that field is the **`Epic Link`** custom field **`customfield_10108`**, stored as the **Epic’s issue key** (e.g. `LYCC-9350`). The UI renders it as the epic’s **`SRE | Temporary Epic`** title.

   Call **`jira_update_issue`** with:

   ```text
   fields: { "customfield_10108": "<epic_key>" }
   ```

   Example: `{ "customfield_10108": "LYCC-9350" }`.

   **Why not only `jira_link_to_epic`?** In this Jira, `jira_link_to_epic` may return success while **`customfield_10108` stays empty**, so the **Epic Link** panel looks blank. Always set **`customfield_10108`** via **`jira_update_issue`** for LYCC so the behavior matches tickets created in the UI.

3. **Optional:** `jira_link_to_epic` may still be called if you want parity with Agile APIs, but **do not rely on it alone** for LYCC—**`customfield_10108` is the source of truth** for the visible Epic Link.

When presenting results, name the epic **`SRE | Temporary Epic`**, give the epic browse URL (`…/browse/<epic_key>`), and confirm the issue shows the same Epic Link as in the reference screenshot.

**Other projects:** If `project_key` is not `LYCC`, discover the Epic Link field id from **`jira_get_issue`** on any issue that already has an epic (e.g. `fields="*all"` or search field metadata)—do not assume `10108`.

## Verify

Call **`jira_get_issue`** on the new key with fields needed to confirm: summary, status, assignee, components, priority, and for LYCC **`customfield_10108`** (must equal the epic key, e.g. `LYCC-9350`) and optionally **`customfield_10104`** (epic name string, e.g. `SRE | Temporary Epic`) when present.

## Present to the user

Return:

- **Browse URL**: `https://jira.workers-hub.com/browse/<KEY>` (adjust base URL if your MCP returns a different `self` / browse pattern).
- **Key**, **assignee**, **component(s)**, **epic** (name **SRE | Temporary Epic** and key), **priority**, **status**.

## Guardrails

- **Read-only / errors** — If the MCP reports read-only or unavailable client, stop and tell the user; do not fake ticket keys.
- **Epic** — Unless the user asked for a **different** epic, link to **`SRE | Temporary Epic`** (resolve key via search; usually `LYCC-9350`). Only ask which epic to use when the default epic cannot be found or the user’s request clearly belongs under another epic.
- **Assignee** — Do not leave self-filed tickets on a **project default assignee** who is not the reporter; apply **Assignee = reporter** unless the user chose someone else.
- **Secrets** — Do not put credentials, tokens, or internal-only URLs into descriptions unless the user explicitly wants them; prefer references to secure stores.

## Relationship to `flava-jira-check`

- **flava-jira-check**: investigate existing tickets and fix code.
- **flava-jira-create-sre-ticket**: **create** new SRE-style LYCC issues with correct fields.

Use both when the flow is “create ticket, then implement” — create first with this skill, then use the other skill with the new key if needed.
