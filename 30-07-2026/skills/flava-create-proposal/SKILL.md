---
name: flava-create-proposal
description: >-
  Turn a Jira ticket (LYCC-xxxx / CLOUDQA-xxxx) or a plain issue description into a
  structured **engineering proposal published as a live Confluence page** in the
  LYCC/flava-console conventions. Use whenever the user says "create a proposal",
  "write a proposal for this ticket", "propose a solution", "draft a design doc /
  RFC", "turn this ticket into a wiki proposal", "document the fix approach", or
  pastes a Jira key / issue and asks how to solve it as a shareable doc — even if
  they don't say the word "Confluence". Especially for DevOps / CI/CD / infra /
  cross-repo changes. The skill investigates root cause first (via flava-jira-check),
  then writes a bilingual 🇻🇳/🇬🇧 Deck-of-Cards page (Problem → Root cause → Solution
  with the exact code locus → Edge cases → Verify → Related), adds workflow diagrams
  when a diagram macro is available, publishes it under the "Flava DevOps - Proposals"
  parent, and adds it to that parent's index table. Do NOT use for creating the Jira
  ticket itself (that's flava-jira-create-*), for implementing a fix (flava-jira-implement),
  or for a PR review (flava-review-pr) — this produces a PROPOSAL DOC, not code or a ticket.
---

# Flava Create Proposal

Turn a ticket or issue into a **published Confluence proposal** that a reader can follow end to end: what's broken, why, the exact fix, and how to verify it. The value is a shareable, reviewable design artifact grounded in the real code — not a vague write-up.

**Core idea:** a good proposal is *investigation first, prose second*. Read the ticket, trace the real code, find the root cause and the smallest correct fix (with file:line), THEN write. A proposal that isn't grounded in the actual code is just a guess with nice formatting — reviewers can't trust it and implementers can't use it.

**Defaults (from established team convention — change only if the user asks):**
- **Repo:** `LYCC/flava-console`. **Confluence space:** `LVN`. **Parent page:** `Flava DevOps - Proposals`.
- **Languages:** bilingual — Vietnamese card + English card, in a Deck of Cards macro.
- **Tone:** concise. The fix is usually small; don't pad. If the change is ~5 lines, say so — an honest "this is a one-file change" is more useful than inflating it.

---

## Workflow (required order)

| Step | Action |
|------|--------|
| **1** | **Get the input** — Jira key → fetch via Jira MCP; or use the pasted issue text (§1) |
| **2** | **Investigate** — run flava-jira-check investigation to get root cause + AS-IS/TO-BE + file:line (§2) |
| **3** | **Draft the two language cards** — the section template, both VN + EN (§3) |
| **4** | **Diagrams** — probe which diagram macro renders; add Problem/Solution/Verify diagrams if one works (§4) |
| **5** | **Publish** — create the page (storage format) in space LVN (§5) |
| **6** | **Re-parent + index** — move under "Flava DevOps - Proposals", add a row to its index table (§6) |
| **7** | **Verify round-trip + report** — fetch back, confirm macros survived, give the user the URL (§7) |

Approval note: this skill **publishes a live wiki page** — an outward-facing artifact. If the user only asked to "draft" or "help me think about" a proposal, produce the content and show it first; publish to Confluence only when they want it live. When they said "create the proposal page", publishing is the expected outcome — proceed.

---

## 1. Get the input

- **Jira key** (`LYCC-1234`, `CLOUDQA-12345`): `jira_get_issue(issue_key=..., fields="*all", comment_limit=20)`. Read summary, description, DoD, components, and comments — the real requirement and any linked wiki often live in comments, not the description.
- **Plain issue text**: use it directly as the problem statement; note there's no ticket to link.

Pin one line: *"Problem to solve: ___ (source: ticket / user description)."* Everything downstream serves it.

## 2. Investigate (this is where the proposal earns its trust)

Run the **flava-jira-check** investigation half (root cause only — no branch, no code edits). Produce:

- **Root cause** — the single point where the behavior originates, with `file:line`. Grep callers/callees; the root cause is usually one shared function, not the many call sites.
- **AS-IS** — what the code does now (quote the offending line).
- **TO-BE** — the smallest correct change, with the actual code snippet and the exact file + line(s) to touch.
- **Scope boundary** — what is explicitly *out* of scope (so reviewers don't expand it).

If the change touches CI/deploy, read the real workflow files (`.github/workflows/*.yaml`, `scripts/*.sh`, `turbo.json`) — cite line numbers. Never describe CI behavior you haven't read.

**Ground every claim in a real line.** If you can't find it in the code, say "unverified — confirm against X" rather than asserting it. A confidently wrong file:line is worse than an honest gap.

## 3. Draft the two language cards

Each card (VN and EN) uses this section set — it maps directly to the user's goal (understand the problem, the solution, and how to verify):

```
Header table: Status | Ticket (markdown link to jira.workers-hub.com/browse/KEY) | Scope | Date
1. TL;DR            — 2-4 sentences: the gap + the proposed fix, one breath
2. Problem          — bullets, each with file:line
3. Root cause       — the single origin point, why the symptom happens
4. Solution         — "locus: <file>"; the actual code snippet (AS-IS → TO-BE)
5. Edge cases       — what must NOT change, idempotency, adjacent paths
6. How to verify    — a table: Goal | How to verify | Expected
7. Related          — ticket link, sibling proposals, files touched, example artifacts
```

- The VN card is the Vietnamese version; the EN card is a faithful translation. Keep technical terms in English (function names, `file.yaml:line`, flags, tool names) in both.
- Write in **storage format** (`content_format: "storage"`) because the Deck/Card and code macros are storage XML, not markdown. See `references/confluence-storage.md` for the exact deck/card/code macro skeleton and the round-trip gotcha.

## 4. Diagrams (default ON — add them; they're the point)

Diagrams are what make the proposal *understandable at a glance* — the whole reason a reader opens the page instead of reading the ticket. **Add them by default**, at minimum a **Problem** and a **Solution** diagram; the flow beats a wall of prose. A **Verify** diagram is optional — skip it when the §6 verify table already conveys the same thing (don't draw a diagram that just restates a table).

**But diagram macros are not uniformly installed** — adding an unsupported macro silently drops the diagram body on save. So **verify the macro round-trips before relying on it**, and probe on a throwaway/scratch page, never the live proposal. (On workers-hub this is already known — see the probe order — so you can skip straight to `plantuml` there.)

Probe order (use the first that survives a round-trip with a real `ac:macro-id`):
1. **PlantUML** — `ac:name="plantuml"`, body `<ac:plain-text-body><![CDATA[@startuml ... @enduml]]>`. **Confirmed working on workers-hub (2026-07)** — default to this and you can skip the probe there.
2. **Mermaid** — `ac:name="mermaid"` / `mermaid-cloud` / `easy-mermaid`, body `flowchart TD ...`. (NOT installed on workers-hub as of 2026-07 — probe before use elsewhere.)
3. **Fallback (always works):** no macro — a numbered step list or an arrow table (`A → B → C`) in plain storage. Not as pretty, but guaranteed to render and stays editable.

Add the diagrams into **both** cards under the matching section (Problem, Solution, and Verify-if-it-adds-value). Keep node labels short and language-neutral (English) so one diagram serves both cards — you write each diagram twice (once per card) but the content is identical. Fetch the full body and append; never send a partial body (§5). See `references/confluence-storage.md` for the round-trip verification recipe + the exact `plantuml` skeleton. If no macro survives, use the fallback (step list / arrow table) and note it — never leave a broken empty macro on the page.

## 5. Publish

Create the page with the **Confluence MCP** `confluence_create_page`: `space_key="LVN"`, a clear title (`Proposal: <short what> (<TICKET>)`), `content_format="storage"`, the full deck (both cards).

**Do not** send a partial body on any later update — always fetch the full current storage and edit the whole thing, then update. A minimal body replaces the entire page (a real failure mode we hit).

## 6. Re-parent + index

- **Re-parent:** `confluence_update_page` with `parent_id` = the "Flava DevOps - Proposals" page id (resolve via `confluence_get_page(space_key="LVN", title="Flava DevOps - Proposals")`). Pass the same full storage body (re-parent alone still requires title+content).
- **Index:** fetch the parent page, append one row to its "Proposals" table — `| N | [Title](pageUrl) | 📝 Draft | <topic> |` — and update it. This keeps the parent a live directory of proposals.

## 7. Verify round-trip + report

Fetch the created page back in **raw storage** (`convert_to_markdown: false`) and confirm:
- The deck + both cards survived with real `ac:macro-id`s (not normalized to empty `<ac:macro/>`).
- Any diagram macros survived (else you'd have silently lost them — fall back per §4).
- Content/tables/links intact.

> The MCP's markdown re-conversion of the *response* mangles code/mermaid macros into flat text — that is a display artifact of the response, NOT the stored page. Trust the raw-storage fetch, not the echoed markdown.

Then tell the user: the **page URL**, that it's parented under Flava DevOps - Proposals and added to the index, which diagram macro was used (or the fallback + why), and a one-line summary of the proposed fix. Note anything left unverified in §2.

---

## Edge cases

- **No ticket, just an issue description:** skip the Jira fetch and the ticket link (write `Issue: <one-line>` in the header); everything else is the same.
- **Fix is trivial (1-2 lines):** still worth a proposal if it documents cross-repo or non-obvious behavior — but keep it short and say plainly it's a small change. Don't inflate scope to justify a doc.
- **Change spans repos** (e.g. flava-console CI → lycc-deploy manifests): describe both sides; if the other repo isn't checked out locally, mark those paths "from ticket, unverified against repo".
- **Two proposals overlap the same files:** cross-link them in Related as "separate but adjacent — coordinate to avoid collisions"; do NOT merge unrelated scope into one proposal.
- **User wants a different parent / space / monolingual:** honor it — the defaults are convention, not law.
- **Diagram macro unavailable:** fallback to step list / arrow table (§4). Never leave an empty stub macro.

## Related skills

- **flava-jira-check** — the root-cause investigation this skill runs in §2.
- **flava-jira-implement** — implements a fix; use *after* a proposal is approved, not instead of.
- **flava-jira-create-dev-ticket / -sre-ticket** — create the Jira ticket; this skill consumes a ticket, doesn't create one.
- **flava-md-to-html** — HTML artifact patterns (if the user wants a local HTML preview instead of a live page).
