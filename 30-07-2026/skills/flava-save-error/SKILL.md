---
name: flava-save-error
description: Append a structured bug/incident entry to the Flava Console error log at .claude/error.md using WHAT, WHY, WHEN, and HOW sections. Use when the user says "save this error", "log this bug", "add to error log", "document this incident", "flava-save-error", or after fixing a bug and they want it recorded for the team. Prefer extracting WHAT/WHY/WHEN/HOW from the conversation or the user's description before writing the file.
---

# flava-save-error

Record a resolved or in-progress incident so future work (and agents) can recognize the failure mode and the fix pattern.

## Log file

- **Path:** `.claude/error.md` (monorepo root, same directory as this skills folder’s parent).
- **Order:** Insert each new entry **below the header instructions and above the previous entry** (newest first).

## Required structure (per entry)

Use this template verbatim for section titles (markdown `###` / `####` as below).

```markdown
## YYYY-MM-DD — Short title (product/area)

### WHAT
- Observable symptoms, user impact, UI/API behavior (concrete, no stack traces unless critical).

### WHY
- Root cause: which components, APIs, or state interactions led to it.
- Mention frameworks/libraries when relevant (e.g. FlavaInput + native `required`).

### WHEN
- When it manifests (flow, env, feature flags).
- Affected apps/paths (e.g. `apps/product-lb/client`, routes, instance types).

### HOW (fix)
- Ordered steps or bullet list: what changed, where, and any caveats.
- If not fixed yet, write **HOW (mitigation)** or **HOW (next steps)** instead.

### References
- Files, tickets (e.g. LYCC-1234), PRs, or docs (optional but encouraged).
```

## Process

1. **Collect** — From chat or user input, fill WHAT/WHY/WHEN/HOW. Ask one targeted question only if a section is unknown.
2. **De-duplicate** — If `.claude/error.md` already documents the same incident (same title/date/symptoms), **update** that entry or add a short cross-link instead of duplicating.
3. **Write** — Edit `.claude/error.md`: insert the new block at the top of the entries list (after the intro `---` separator).
4. **Confirm** — Tell the user the entry title and path.

## Style

- Prefer **plain language**; avoid dumping full stack traces in WHAT (put in References or linked ticket).
- Keep each section **scannable**; sub-bullets OK.
- Use **ISO date** `YYYY-MM-DD` in the `##` title line.

## Out of scope

- Does **not** replace Jira/Confluence for formal RCA; this file is a **lightweight team log** inside the repo.
- Do **not** paste secrets, tokens, or full `.env` contents into the log.
