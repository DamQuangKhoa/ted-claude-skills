---
name: flava-jira-check
description: Analyze Jira tickets, identify root causes, and produce a structured plan file (`<TICKET>.plan.md`). Does NOT implement — stops after plan approval. Use when the user provides a Jira ticket ID (like LYCC-1234, CLOUDQA-12345) and wants to investigate, check, debug, analyze, or understand an issue. Triggers on "check this ticket", "investigate this bug", "what's this Jira about", "root cause analysis", or just a pasted ticket number. After producing the plan, asks user (1) approve/change the plan, and (2) whether to generate an HTML report. To implement, use **flava-jira-implement**.
---

# Flava Jira Check

Analyze Jira tickets to understand issues, identify root causes, and produce a **plan file**. This skill does **NOT** implement fixes — it stops after the plan is approved. Use **flava-jira-implement** for implementation.

## Workflow

| Step | Action |
|------|--------|
| **0** | **Git prep** — checkout `main`, pull latest, create the ticket branch (§0). |
| **1** | **Fetch Jira ticket** — get full issue details (§1). |
| **2** | **Analyze requirements / bug** — understand the problem (§2). |
| **3** | **Search codebase** — find relevant code, trace flows (§3). |
| **4** | **Root cause analysis** — synthesize findings (§4). |
| **5** | **Draft plan** — solution + unit tests → write `<TICKET>.plan.md` (§5). |
| **5.5** | **Ask about feature flag** — if the ticket adds/changes user-facing behavior, ask whether to gate it behind a flag; if yes, add a Feature Flag section to the plan (§5.5). |
| **5.7** | **Codex plan review** — run `codex exec` (CLI, headless, read-only) to critique the plan before the user sees it (§5.7). |
| **6** | **Stop for approval** — present plan summary + Codex critique in chat, ask user to approve or request changes (§6). |
| **7** | **Optional HTML report** — only if user says yes (§7). |

**No code changes, no commits.** This skill prepares the ticket branch (§0) but stays read-only on product code — investigation and planning only.

---

## 0. Git prep

Before investigating, get a clean branch off the latest `main` so the follow-up implement step starts from the right base:

```bash
git checkout main
git pull --rebase origin main
git checkout -b <TICKET-ID>          # e.g. LYCC-11637
```

Notes:
- Derive `<TICKET-ID>` from the ticket the user gave (the Jira key).
- If `git pull --rebase origin main` prints a stale-ref / packed-refs warning but `main` is already up to date, that's harmless — proceed. Only stop if `main` genuinely failed to update.
- If the branch already exists, switch to it (`git checkout <TICKET-ID>`) instead of recreating.
- Still **no product-code edits and no commits** in this skill — the branch is just staged for `flava-jira-implement`.

## 1. Fetch ticket details

Use **Jira MCP** `jira_get_issue`:

```
jira_get_issue(issue_key="LYCC-1234", fields="*all", comment_limit=10)
```

Extract:

- **Summary & description**: What's the reported problem or requirement?
- **Status & priority**: How urgent?
- **Labels & components**: Which part of the system?
- **Comments**: Reproduction steps, stack traces, clues from engineers
- **Linked issues**: Related context

## 2. Analyze the ticket

From ticket information, identify:

- **Error messages or stack traces** — best leads for codebase search
- **Reproduction steps** — understand the user flow
- **Screenshots or logs** — visual clues
- **Environment details** — stage vs real, specific regions
- **Related tickets** — patterns across reports
- **For feature/improvement tickets**: acceptance criteria, UI/API requirements

## 3. Search the codebase

Search methodically based on ticket findings:

- **Error messages** → grep to find origin
- **API endpoints** → trace BFF controllers → services → upstream calls
- **Components/pages** → find Vue components, composables, stores
- **Function/class names** → understand context

Monorepo structure reminder:

- `bff/src/modules/` — BFF modules by domain
- `client/src/pages/` — Vue pages
- `client/src/composables/` — feature composables with TanStack Query hooks
- `client/src/apis/` — API modules
- `client/src/utils/` — utility functions

**Tip:** Check git history of affected files (`git log --oneline -10 -- path/to/file`) to see recent changes that may have introduced the bug.

## 4. Root cause analysis

Synthesize findings:

- **Direct cause**: What specifically triggers the issue?
- **Contributing factors**: Configuration, timing, environment, API changes
- **Impact scope**: Which users/environments/flows affected?
- **Confidence level**: Certain or hypothesis needing verification?

## 5. Write plan file

Output path:

```
.claude/flava-jira-check/plans/<TICKET-ID>.plan.md
```

Create the `plans` directory if missing.

### Plan file structure (mandatory sections)

```markdown
# <TICKET-ID>: <Summary>

## Ticket Info

- **Key**: <TICKET-ID>
- **Type**: Bug / Task / Story / Improvement
- **Component**: <component>
- **Priority**: <priority>
- **Jira**: https://jira.workers-hub.com/browse/<TICKET-ID>

## Problem

<1-3 sentences: what's wrong or what's requested>

## Root Cause

<Direct cause, contributing factors, confidence level>

## Solution

### Changes

<Numbered list of file-level changes with approach>

1. `path/to/file.ts` — what to change and why
2. `path/to/other.vue` — what to change and why

### Approach

<Strategy, alternatives considered, why this approach>

### Risk

<Low/Medium/High + potential side effects>

## Feature Flag

<Include this section ONLY if the user opted in during §5.5; otherwise omit it entirely.>

- **Flag key**: `ENABLE_<AREA>_<FEATURE>` (default on/off)
- **Gate points**: which components/tabs/routes wrap the ticket's *new* delta
- **Wiring**: `.env`, `vite.config.ts` inject.data, `index.html` window.flava, `envUtils` const — see **flava-flag-feature**

## Unit Test Plan

### Test files

<Which spec files to create or extend>

### Framework

<Vitest for client, Jest for BFF>

### Test cases

1. <Test that reproduces the bug / validates the feature — would fail before fix>
2. <Edge case>
3. <Regression case>

### Mocks needed

<What to mock: APIs, composables, stores>

### Run command

```bash
pnpm --filter <pkg> run test:ci -- <pattern>
```

## Manual Verification

<Steps to manually verify the fix works>

## Open Questions

<Anything unclear that needs user/QA/PM input before implementation — or "None">
```

**Rules:**
- Pull facts from Jira + codebase investigation; do not invent APIs or paths.
- Code paths, error strings, snippets in **English**.
- If the ticket is a feature/improvement (not a bug), skip "Root Cause" — use "Requirements Analysis" instead.

## 5.5 Ask about feature flag

If the ticket adds or changes **user-facing behavior** (a new feature, tab, field, page, or flow — not a pure bug fix or internal refactor), ask the user:

> "Do you want to gate this behind a feature flag so it can be toggled per environment?"

- **If yes**: add the **Feature Flag** section to the plan file (see template above) and consult **flava-flag-feature** for the exact key + the four-file wiring (`.env`, `vite.config.ts`, `index.html`, `envUtils`) and the gating scope. Crucially, scope the flag to the ticket's **delta** — the new pieces only — not the whole surrounding feature area (flag-off should match the pre-ticket state). The flag becomes part of the implementation the plan describes.
- **If no** (or it's a plain bug fix): omit the Feature Flag section entirely.

Keep this a quick yes/no — don't wire anything now (this skill is read-only on product code); it only records the flag in the plan for **flava-jira-implement** to build.

## 5.7 Codex plan review

Before presenting the plan for approval, get a second opinion on the **plan itself** — not code.

This skill produces only a plan `.md` and no code, so `codex exec review` (a diff reviewer) has nothing to review. Instead, run the Codex CLI headless as a one-shot critique of the plan **text** — pass the critique instruction as the prompt and let Codex read the plan file itself. A single `codex exec` call is fast (~2 min) and read-only.

**How:** run the Codex CLI in read-only sandbox (no edits, no approval prompts):

```bash
codex exec -s read-only -C "$(git rev-parse --show-toplevel)" \
  "Critique the implementation plan at .claude/flava-jira-check/plans/<TICKET-ID>.plan.md. \
Do NOT rewrite it and do NOT edit any files. Return a short findings list (issue → why it matters). \
Check: is the root cause correct? Any wrong assumptions, missing edge cases, overlooked callers/consumers, \
or a simpler approach? Are the test cases sufficient to catch a regression? Is the risk assessment honest? \
Read the referenced source files to verify claims before flagging."
```

- Preflight: if `command -v codex` fails, skip this step, note "Codex CLI not installed" in §6, and continue — don't block the plan.
- `-s read-only` guarantees Codex can read the repo + plan but cannot modify anything and won't hang on approval prompts.
- Run it **foreground** for a normal plan (it's one call). Capture stdout as the critique.

**Rules:**
- **Advisory only.** Do not silently rewrite the plan from the critique. **Verify each finding against the actual code** before acting — Codex can be wrong. Fold in confirmed findings, surface the rest (or refute them) in §6 and let the user decide.
- Skip if the plan is trivial (1-file, obvious fix) — say so in one line rather than running it.
- If the CLI errors or times out, note it and continue; don't block the plan on it.

## 6. Present plan and ask for approval

Reply in chat with:

- Ticket key + one-line verdict/summary
- **Plan file path**: `.claude/flava-jira-check/plans/<TICKET-ID>.plan.md`
- Key findings (2-3 bullets max)
- **Codex critique** (from §5.7): 1-2 bullets — what it flagged and whether you folded it in, or "no concerns"
- **Ask explicitly**: "Approve this plan, or want changes?"
- If a feature flag was added (§5.5), note it in one line so the user can confirm the flag choice.
- **Ask**: "Want an HTML report?"
- If open questions exist, call out the top 1–2

**After §6:** STOP. Do not edit product code. Do not commit. (The ticket branch from §0 already exists — leave it staged for `flava-jira-implement`.)

## 7. Optional HTML report

Only if user says yes to HTML report:

1. Read `.claude/skills/flava-md-to-html/SKILL.md` for styling rules.
2. Use `references/starter-template.html` as shell.
3. See `references/jira-check-report.md` in this skill for tab structure.

Output: `.claude/flava-md-to-html/docs/<TICKET-ID>-jira-check.html`

**Required tabs (Vietnamese unless user asks English):**

| Tab | Content |
|-----|---------|
| **Tổng quan** | Ticket summary, status, priority, component, Jira link, issue recap |
| **Nguyên nhân** | Direct cause, contributing factors, impact, confidence |
| **Kế hoạch thay đổi** | File-level changes, approach, risk, test plan, todo checklist |
| **Cần làm rõ** | Open questions or "Không có câu hỏi mở" |

## Multiple tickets

1. Analyze each individually
2. Look for common root causes
3. One plan file per ticket: `<TICKET-ID>.plan.md`
4. Suggest prioritization if relevant

## Relationship to other skills

- **flava-jira-check** (this): investigate → plan → approval. **No implementation.**
- **flava-jira-implement**: takes approved plan → branch → tests first → implement → run tests.
- **flava-jira-create-dev-ticket**: create new dev/product Jira tickets.
- **flava-jira-create-sre-ticket**: create SRE/infra tickets.

To go from check to implement: after plan approval, user invokes `/flava-jira-implement <TICKET-ID>`.
