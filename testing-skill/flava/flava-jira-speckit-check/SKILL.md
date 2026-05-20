---
name: flava-jira-speckit-check
description: End-to-end workflow from a Jira ticket to Spec Kit artifacts and (after approval) implementation. Use whenever the user gives a Jira key (e.g. LYCC-1234), wants a feature spec/plan from a ticket, or says things like "turn this Jira into a spec", "speckit from ticket", "plan this story from Jira", or combines Jira + Confluence wiki context with /speckit. Also use when the user wants the same ticket intake as flava-jira-check but oriented toward specification and implementation planning rather than bug root-cause analysis. Requires a repo with `.specify/` (Spec Kit), Jira MCP, and optionally Confluence MCP. Triggers even if the user only pastes a ticket ID—assume they want the full pipeline unless they say otherwise.
compatibility: "Jira MCP (user-jira), Confluence MCP (user-confluence) optional but recommended, Spec Kit (.specify/), skills speckit-specify, speckit-clarify, speckit-plan, speckit-tasks, speckit-implement"
---

# Flava Jira → Spec Kit pipeline

Take a **Jira ticket**, pull **linked Confluence wiki** content when present, then drive **Spec Kit** (`specify` → `clarify` → `plan` → `tasks`) and stop for **human approval** before running **implement**.

This skill complements **`flava-jira-check`**: that skill focuses on **investigation, root cause, and bug fixes** in the flava-console codebase. **This skill** focuses on **product/feature intake**: Jira + wiki → `spec.md` / `plan.md` / `tasks.md` → optional code implementation.

---

## Prerequisites

- **Spec Kit** present at repo root (`.specify/`, templates, scripts). If missing, tell the user to bootstrap Spec Kit first; do not pretend the pipeline exists.
- **MCP**: Read tool schemas before calling (descriptor JSON under the enabled MCP server folders). Typical servers: `user-jira`, `user-confluence`.
- **Skills**: Load and follow these skills when you reach each phase (paths depend on installation; use the workspace `.cursor/skills/` or user skill directories):
  - `speckit-specify`
  - `speckit-clarify`
  - `speckit-plan`
  - `speckit-tasks`
  - `speckit-implement`

---

## Step 0 — Ticket input

Collect from the user:

- **Issue key** (required), e.g. `LYCC-1234`.
- **Repo / branch expectations** (if relevant): whether Spec Kit should use an existing feature dir or create a new one (default: let `speckit-specify` create the next feature directory per project rules).

If the user only pastes a key, treat that as sufficient to start.

---

## Step 1 — Jira MCP: load the ticket

Mirror the fetch pattern from **`flava-jira-check`** (read that skill for field guidance):

- Read the **`jira_get_issue`** schema, then call with enough fields to capture description, comments, links, and any custom fields your org uses. Prefer `fields="*all"` when you need wiki URLs or custom link fields, and a sensible `comment_limit` (e.g. 10–25) so discussion context is not dropped.

Extract a structured brief:

- Summary, description, type, status, priority, assignee, labels, components
- **Comments** (acceptance hints, QA notes)
- **Issue links** (blocks, relates, epic)
- **Any URLs** pointing at Confluence / wiki (`...atlassian.net/wiki/...`, `/pages/123456789/`, etc.)

---

## Step 2 — Confluence MCP: wiki linked from the ticket

If the ticket (description, comments, or fields) references **Confluence / wiki**:

1. Read **`confluence_get_page`** and **`confluence_search`** schemas.
2. **Prefer `confluence_get_page`** when you can extract a **numeric `page_id`** from the URL (the path segment after `/pages/`).
3. If you only have title + space, use `page_id` + `space_key` + `title` per schema.
4. Use **`confluence_search`** when the ticket mentions a page title or phrase but no stable URL.
5. Request **`convert_to_markdown: true`** unless you need raw HTML for a macro (mind token size).

If **no** wiki references exist, skip this step and note "no Confluence context found."

---

## Step 3 — Build the feature description for Spec Kit

Assemble **one** natural-language feature description for `speckit-specify` that includes:

- Ticket key and summary as the anchor
- User-visible behavior and constraints from Jira
- Extra detail from Confluence (APIs, data model, edge cases)
- Explicit mention of **out-of-scope** only if Jira/wiki say so
- Open questions as bullet points (they will feed `speckit-clarify`)

Do **not** silently invent scope; prefer marking unknowns for clarification.

---

## Step 4 — Run `speckit-specify`

1. Read the **`speckit-specify`** skill and execute it **verbatim** for the repo.
2. Pass the composed feature description as the user would for `/speckit.specify` (arguments / command pattern per that skill).
3. Confirm `spec.md` exists under the resolved feature directory and `.specify/feature.json` (or equivalent) points at it.

---

## Step 5 — Run `speckit-clarify` when needed (before plan)

The **`speckit-clarify`** skill is designed to run **before** `speckit-plan` so planning does not bake in wrong assumptions.

- If the spec is thin, ambiguous, or has `[NEEDS CLARIFICATION]` markers, run **`speckit-clarify`** now (up to the question limit and workflow in that skill).
- If the user **refuses** clarification time, document the risk and proceed, per `speckit-clarify` guidance.

**Note:** If you already ran `speckit-plan` earlier in the session and then clarify the spec, treat the plan as **stale**—re-run **`speckit-plan`** after clarifications land in `spec.md`.

---

## Step 6 — Run `speckit-plan`

1. Read **`speckit-plan`** and execute it for the same feature directory.
2. Produce/refresh `plan.md` and related artifacts (research, data model, contracts, etc.) per that skill.

---

## Step 7 — Run `speckit-tasks` (required before implement)

**`speckit-implement` expects `tasks.md`.** After `plan.md` is in good shape:

1. Read **`speckit-tasks`** and generate **`tasks.md`** for the feature.
2. Summarize task count and critical path for the user.

Skip only if `tasks.md` already exists and the user explicitly keeps it—but verify with `check-prerequisites` behavior from the implement skill before implementing.

---

## Step 8 — Approval gate (mandatory)

Present a short **approval packet**:

- Jira key + link (if available)
- Paths: `spec.md`, `plan.md`, `tasks.md`
- **What will change in the codebase** (high level)
- **Risks / open questions** still unresolved

**Stop.** Do **not** run `speckit-implement`, edit files for the feature, or commit until the user clearly approves (e.g. "approved", "go ahead and implement", "run implement"). Ambiguous ack ("ok", "thanks") is **not** enough—ask once.

Same spirit as **`flava-jira-check`**: no implementation without explicit consent.

---

## Step 9 — Run `speckit-implement` (only after approval)

1. Read **`speckit-implement`** and execute it.
2. Respect checklist gates and hooks defined there; if implement stops for checklist confirmation, surface that to the user.

---

## Deliverables checklist

At the end of a successful run (before code), the user should have:

- [ ] Jira context summarized
- [ ] Confluence wiki merged in (or explicit skip)
- [ ] `spec.md` from specify (+ clarify updates)
- [ ] `plan.md` (+ artifacts from plan phases)
- [ ] `tasks.md`
- [ ] Explicit user approval recorded in the thread

---

## Optional: shallow ticket-only pass

If the user says they **only** want Jira/wiki synthesis **without** Spec Kit, stop after Step 2–3 with a structured brief and suggest running this skill again when they are in a Spec Kit repo.

---

## Tips

- Always read MCP **tool schemas immediately before** the first call; parameter names and defaults differ by server version.
- Prefer **ticket comments** for acceptance criteria; description often lags.
- Large Confluence pages: summarize sections for the feature description and keep a note of what was omitted to save tokens.
- If Jira and Spec Kit disagree (e.g. ticket is bugfix but spec template assumes feature), call it out and align wording with the user before `specify`.
