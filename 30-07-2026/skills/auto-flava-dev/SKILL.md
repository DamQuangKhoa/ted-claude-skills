---
name: auto-flava-dev
description: Self-improving Flava product development using flava skills (commit, PR, Jira, product conventions). Build reliable development workflows through iterative experimentation — an inner agent executes the dev task using the full flava skill suite, the outer agent reads results and improves strategy.md. Repeat until the task passes consistently. Use whenever the user wants to develop, fix, or maintain any Flava product feature end-to-end, even if they only say "auto-flava-dev", "build this ticket", "implement this feature autonomously", "develop flava task", "run this Jira ticket", or "loop on this fix". Also triggers for phrases like "keep trying until it works", "iterate on this dev task", or "self-improving dev loop".
---

# Auto-Flava-Dev — Self-Improving Flava Development Skill

Develop and maintain Flava Console features through iterative experimentation using the **flava skill suite**. An inner agent executes the dev task end-to-end (investigate → code → commit → PR → Jira update). You — the outer agent — read what happened and improve `strategy.md`. Repeat until the task passes consistently.

## Entry Points

Both explicit flags and free-form natural language work:

```
/auto-dev --task LYCC-1234
/auto-dev --task add-lb-replica-field --iterations 5
/auto-dev --tasks LYCC-1234,LYCC-5678
/auto-dev --all

# Also fine — parse freely:
/auto-dev CLOUDQA-84652
/auto-dev fix the tooltip on the blueprint deployment page
/auto-dev retry the existing lb-replica-field task
/auto-dev LYCC-1234 just the investigation, no code
```

When the user drops a Jira key or free-form instruction instead of `--task <name>`:

- If an existing task in `./auto-dev/tasks/` clearly matches the ticket/intent, use it.
- Otherwise pick a short kebab-case name derived from the ticket key or intent (e.g. `LYCC-1234` → `lycc-1234`, "fix tooltip on blueprint" → `fix-blueprint-tooltip`), scaffold `./auto-dev/tasks/<name>/task.md`, fill in the goal, and proceed. Tell the user the chosen name in one line.

## How to Run

### Step 1 — Parse Arguments

- `--task <name>` → single task mode
- `--tasks a,b,c` or `--all` → multi-task mode (spawn sub-agents)
- `--iterations N` → execute/improve cycles (default: 5)
- Any Jira-key-like pattern (e.g. `LYCC-1234`, `CLOUDQA-9999`) → resolve to `--task <key-lowercase>`

Map free-form input to one of the above before continuing.

### Step 2 — Set Up Workspace

All artifacts live in `./auto-dev/` in the current working directory — NOT inside `~/.claude/skills/`.

```bash
mkdir -p ./auto-dev/tasks ./auto-dev/traces ./auto-dev/reports
```

If `./auto-dev/tasks/<task>/task.md` doesn't exist yet, scaffold it:

```bash
mkdir -p ./auto-dev/tasks/<task>
```

Then write `task.md` with this structure (or copy from `references/example-task.md`):

````markdown
# Task: <task-name>

## Jira Ticket

<ticket key or "N/A">

## Product Area

<product name and path, e.g. "product-lb — apps/product-lb/">

## Goal

<what to accomplish in 1–2 sentences>

## Steps

1. <high-level step, e.g. "Investigate ticket / understand root cause">
2. <e.g. "Implement fix in BFF + client">
3. <e.g. "Commit following flava conventions">
4. <e.g. "Create PR and update Jira">

## Expected Output

```json
{
  "status": "success",
  "pr_url": "https://git.linecorp.com/...",
  "jira_status": "In Review",
  "notes": "brief summary of what was done"
}
```
````

### Step 3 — Multi-task: Spawn Parallel Sub-agents

If running multiple tasks (`--tasks` or `--all`), use the Agent tool to spawn one sub-agent per task simultaneously. Each receives a self-contained prompt (see The Loop below). Wait for all to complete, then collect summaries.

For a single task, skip this step and run the loop directly.

---

## The Loop (run for each task)

### Iteration Start

Verify `./auto-dev/tasks/<task>/task.md` exists (scaffold if not — see Step 2). `strategy.md` starts empty and is auto-created by the inner agent on first run.

### Run the Inner Agent

Spawn a sub-agent with this exact prompt:

> "You are the inner dev agent for task `<task>`. Workspace: `<absolute-path>/auto-dev`.
>
> 1. Read `./auto-dev/tasks/<task>/task.md` — understand the Jira ticket, product area, goal, and expected output.
> 2. Read `./auto-dev/tasks/<task>/strategy.md` if it exists — follow every instruction in it exactly.
> 3. Execute the development task end-to-end using the flava skill suite. The typical sequence (adjust based on task type and strategy.md):
>    - **Investigate:** Use `flava-jira-check` to read the ticket, checkout or create the ticket branch, and identify root cause / planned changes. Wait for the investigation report before proceeding.
>    - **Load conventions:** Load the relevant product skill (`flava-blueprint-skill`, `flava-lb-skill`, `flava-vector-pipeline-skill`, `flava-vector-search-skill`, or `flava-fractaldb-skill`) for the affected product area before touching code.
>    - **Implement:** Apply the planned changes in the codebase following the loaded conventions. Run existing tests to confirm no regressions.
>    - **Commit:** Use `flava-commit-skill` to stage codebase files only and commit with the correct format.
>    - **Create PR:** Use `flava-pr-skill` to open the PR (GitHub MCP only), assign it, add labels, and link to Jira.
>    - **Update Jira:** Transition the ticket to `In Review` and post the PR URL as a comment.
> 4. After the task completes (pass or fail), write a summary JSON to a temp file and copy it to the traces directory:
>    ```bash
>    mkdir -p ./auto-dev/traces/<task>
>    cat > ./auto-dev/traces/<task>/latest.json << 'ENDJSON'
>    {
>      "status": "pass",
>      "pr_url": "https://git.linecorp.com/...",
>      "jira_status": "In Review",
>      "branch": "LYCC-1234",
>      "skills_used": ["flava-jira-check", "flava-lb-skill", "flava-commit-skill", "flava-pr-skill"],
>      "steps_taken": ["synced main", "checked out LYCC-1234 branch", "loaded flava-lb-skill", "fixed BFF DTO", "committed", "created PR #456"],
>      "failure_point": null,
>      "failure_turn": null,
>      "notes": "Added missing field to revision DTO and updated client composable."
>    }
>    ENDJSON
>    ```
>    Use `"status": "fail"` and fill in `failure_point` / `failure_turn` if the task did not complete successfully.
> 5. Print the full JSON summary to stdout so the outer agent can read it."

### Read the Trace

```bash
cat ./auto-dev/traces/<task>/latest.json
```

If the agent failed, look deeper:

- Which `steps_taken` was last before the failure?
- What was `failure_point`?
- Look at the git state and any error messages the inner agent reported.

### Form One Hypothesis

Find the exact step that went wrong. What single strategy change would have prevented it?

**Examples:**

- "Load `flava-lb-skill` before reading any file in `apps/product-lb/` — conventions aren't obvious from grep alone"
- "Run `git pull --rebase origin main` before branching — previous ticket branch was stale and caused merge conflicts"
- "Use GitHub MCP `pull_request_read` to confirm the PR template is populated before submitting"
- "Transition Jira only after confirming the PR URL is valid — previous runs transitioned before PR creation succeeded"
- "When product area is unknown, run `flava-product-explainer` first to identify the right app and skill"
- "Check for existing open PRs on the branch before creating a new one to avoid duplicates"
- "Run `pnpm --filter <app>-client test` after code changes — catches TypeScript errors early before committing"

### Update strategy.md

Edit `./auto-dev/tasks/<task>/strategy.md`. Keep everything that worked. Fix the specific failure. Add the concrete heuristic.

Good strategies have:

- **Fast path**: which skills to load first and in what order for this ticket/product area
- **Step-by-step workflow**: exact skill invocation sequence with decision points
- **Product-specific gotchas**: known conventions, file paths, or patterns that trip up the agent
- **Failure recovery**: what to do when investigation reveals blocked dependencies, missing Jira fields, or test failures

### Judge the Result

- Pass or clear progress → keep strategy, next iteration
- No progress or regression → revert `strategy.md` to previous version and try a different hypothesis

### After All Iterations — Graduate if Ready

If the task passed on 2+ of the last 3 iterations (or hit max iterations with consistent behavior), save the learned strategy as a project-local pattern.

Write to `./.claude/skills/<task>/SKILL.md` (project-local):

```bash
mkdir -p ./.claude/skills/<task>
```

Use this structure for the graduated SKILL.md:

````markdown
---
name: <task>
description: <1-2 sentences with trigger keywords — product area, ticket, type of change>
---

# <Task Title> — Flava Dev Skill

## Purpose

<what this automates and why it exists>

## When to Use

<trigger scenarios>

## Product Area

<app path, BFF + client paths, key files>

## Workflow

### Step 1 — Investigation

<exact flava-jira-check / confluence steps and what to look for>

### Step 2 — Load Conventions

<which product skill to load and why>

### Step 3 — Implement

<key files to touch, patterns to follow>

### Step 4 — Commit & PR

<commit format, PR sections to fill, labels to add>

### Step 5 — Jira Update

<transition target, comment format>

## Product-Specific Gotchas

<bullet list of every hard-won heuristic from iterations — this is the core value>

## Failure Recovery

<what to do when investigation is blocked, tests fail, or PRs can't be created>
````

After writing, confirm:
```bash
ls ./.claude/skills/<task>/SKILL.md
```

---

## Final Report (multi-task mode)

After all sub-agents complete, print a summary table:

| Task            | Iterations | Final Status | Graduated | PR |
| --------------- | ---------- | ------------ | --------- | -- |
| lycc-1234       | 3          | ✅ pass      | yes       | #456 |
| fix-lb-tooltip  | 5          | ❌ fail      | no        | — |

Then write a persistent report to `./auto-dev/reports/YYYY-MM-DD-HH-MM-<tasks>.md`:

```markdown
# Auto-Dev Session Report

**Date:** <ISO date>
**Tasks:** <comma-separated>

## Results

| Task | Iterations | Pass Rate | Final Status | Graduated | PR |
| ---- | ---------- | --------- | ------------ | --------- | -- |
| ...  | ...        | X/5       | ✅/❌        | yes/no    | #N |

## Per-Task Learnings

### <task>

- **Key insight:** <heuristic learned>
- **Failure mode fixed:** <what broke and how it was resolved>
- **Skills used:** <comma-separated flava skills>

## Iteration Log

<brief per-iteration notes>
```

---

## Flava Skill Reference

> Full detail for each skill (gotchas, loading order, MCP requirements) is in `references/flava-skills-overview.md`. Read it when the task involves an unfamiliar product area or MCP setup.

These skills are available in the flava suite. The inner agent should load the right ones based on the task:

| Skill | When to use |
|-------|------------|
| `flava-jira-check` | Always — ticket investigation, root cause, branch setup, implement after approval |
| `flava-commit-skill` | Whenever committing — ensures commitlint format, excludes AI agent files |
| `flava-pr-skill` | Whenever creating a PR — GitHub MCP only, structured description, Jira link |
| `flava-review-pr` | When reviewing someone else's PR |
| `flava-blueprint-skill` | Code touching `apps/product-cloud-blueprint/` |
| `flava-lb-skill` | Code touching `apps/product-lb/` |
| `flava-vector-pipeline-skill` | Code touching vector search pipelines in `apps/product-dbs-for-vector-search/` |
| `flava-vector-search-skill` | Code touching vector search features more broadly |
| `flava-fractaldb-skill` | Code touching FractalDB-related apps |
| `flava-estimate-skill` | Estimating effort from a Confluence page |
| `flava-jira-create-dev-ticket` | Creating new LYCC dev/feature/bug tickets |
| `flava-jira-create-sre-ticket` | Creating new SRE/infra tickets |
| `flava-sentry-check` | Investigating a Sentry error linked in a ticket |
| `flava-sentry-triage` | Running a full Sentry triage session for an environment |
| `flava-product-explainer` | When the product area is unknown and needs orientation |
| `flava-md-to-html` | Converting markdown investigation reports to HTML |
| `flava-jira-wiki-check` | Checking Confluence wiki pages linked from a ticket |
| `flava-save-error` | Saving persistent error notes for future reference |

**Default skill loading order for most bug-fix/feature tasks:**
1. `flava-jira-check` (ticket + branch)
2. Relevant product skill (blueprint / lb / vector etc.)
3. `flava-commit-skill` (after implementation)
4. `flava-pr-skill` (after commit)

---

## Tips for the Outer Agent

- **Read transcripts, not just status.** If the inner agent kept retrying the same Jira call, that's a signal the Jira MCP was throttled — add a retry note to strategy.md, not just "use Jira MCP".
- **Stable patterns → bundled scripts.** If multiple iterations all independently ran `pnpm --filter product-lb-client test` and then parsed the same output, consider adding a helper note in strategy.md with the exact command and what a passing output looks like.
- **Don't over-constrain.** If the inner agent is generally succeeding but failing on one edge case (e.g., a missing `@IsOptional()` on a DTO field), target that specifically rather than rewriting the whole strategy.
- **Flava conventions are load-sensitive.** The product skills (lb, blueprint, vector) contain dense convention tables. If the inner agent is producing code that violates conventions, the most common fix is: load the product skill *before* reading any source files, not after.
