# auto-flava-dev

Self-improving Flava product development skill. You describe a dev task (Jira ticket, feature, bug fix) — the skill executes it end-to-end using the flava skill suite, learns from what failed, and refines its strategy until the task passes reliably. Graduated tasks become reusable project-local skills.

## How It Works

```
Outer agent (you)
│
├─ reads task.md          ← what to build / fix
├─ spawns inner agent     ← executes using flava skill suite
├─ reads trace            ← what happened (PR URL, failure point, skills used)
├─ updates strategy.md    ← one hypothesis per iteration
└─ repeats until passing  → graduates to .claude/skills/<task>/SKILL.md
```

Each iteration the outer agent forms **one hypothesis**, updates `strategy.md`, and re-runs. It builds on what worked and never reverts a win.

## Usage

Invoke via Claude Code with natural language or structured flags:

```
/auto-flava-dev --task LYCC-1234
/auto-flava-dev --task fix-lb-tooltip --iterations 5
/auto-flava-dev --tasks LYCC-1234,CLOUDQA-9999
/auto-flava-dev --all

# Or just drop a ticket key / description:
/auto-flava-dev CLOUDQA-84652
/auto-flava-dev fix the tooltip on the blueprint deployment page
/auto-flava-dev retry the existing lycc-1234 task
/auto-flava-dev LYCC-5678 investigation only, no code
```

## Prerequisites

The following flava skills must be accessible in `~/.claude/skills/flava-skills/` (or project-local):

- `flava-jira-check` — ticket investigation, branch setup, implementation
- `flava-commit-skill` — commitlint-compliant commits
- `flava-pr-skill` — PR creation via GitHub MCP
- Product skills: `flava-lb-skill`, `flava-blueprint-skill`, `flava-vector-pipeline-skill`, `flava-vector-search-skill`, `flava-fractaldb-skill`

MCPs required: **Jira MCP** (`user-jira`), **GitHub MCP** (`user-github`), **Confluence MCP** (`user-confluence`, optional).

## Workspace Layout

All training artifacts are written to `./auto-flava-dev/` in your working directory:

```
auto-flava-dev/
├── tasks/
│   └── <task>/
│       ├── task.md        ← task definition (edit once, never touch again)
│       └── strategy.md    ← evolving skill-loading + dev approach (updated each iteration)
├── traces/
│   └── <task>/
│       └── latest.json    ← summary of last run (status, PR URL, failure point, skills used)
└── reports/
    └── YYYY-MM-DD-<tasks>.md   ← session report after multi-task runs
```

Graduated tasks are written to `./.claude/skills/<task>/SKILL.md`.

## Defining a Task

Create `./auto-flava-dev/tasks/<task>/task.md` (the skill scaffolds this automatically, or copy from `references/example-task.md`):

```markdown
# Task: lycc-1234

## Jira Ticket

LYCC-1234

## Product Area

product-lb — apps/product-lb/

## Goal

Add the `drainTimeoutSeconds` field to the Application LB revision DTO and expose it in the edit modal.

## Steps

1. Investigate ticket and understand root cause
2. Load flava-lb-skill conventions
3. Implement DTO change in BFF + form field in client
4. Commit and create PR
5. Update Jira to In Review

## Expected Output

{
  "status": "success",
  "pr_url": "https://git.linecorp.com/LYCC/flava-console/pull/...",
  "jira_status": "In Review"
}
```

## Flava Skill Quick Reference

| Skill | Product area / use case |
|-------|------------------------|
| `flava-jira-check` | Any ticket — investigation, RCA, branch setup, implementation after approval |
| `flava-commit-skill` | Committing staged changes with correct commitlint format |
| `flava-pr-skill` | Creating PRs on `git.linecorp.com` via GitHub MCP |
| `flava-review-pr` | Reviewing someone else's PR |
| `flava-blueprint-skill` | `apps/product-cloud-blueprint/` |
| `flava-lb-skill` | `apps/product-lb/` |
| `flava-vector-pipeline-skill` | `apps/product-dbs-for-vector-search/` — pipelines, processors |
| `flava-vector-search-skill` | `apps/product-dbs-for-vector-search/` — general vector search |
| `flava-fractaldb-skill` | FractalDB-related apps |
| `flava-estimate-skill` | Effort estimate from a Confluence page |
| `flava-jira-create-dev-ticket` | Creating new LYCC dev/feature/bug tickets |
| `flava-jira-create-sre-ticket` | Creating new LYCC SRE/infra tickets |
| `flava-sentry-check` | Investigating a Sentry error linked in a ticket |
| `flava-sentry-triage` | Full Sentry triage session for an environment |
| `flava-product-explainer` | Orienting around an unfamiliar product area |
| `flava-md-to-html` | Converting markdown investigation reports to HTML |
| `flava-jira-wiki-check` | Checking Confluence wiki pages linked from a ticket |
| `flava-save-error` | Saving persistent error notes for future reference |

## Graduated Skills

When a task passes on 2+ of the last 3 iterations, the learned strategy is installed to `./.claude/skills/<task>/SKILL.md`:

```
.claude/skills/
└── lycc-1234/
    └── SKILL.md    ← invoke with /lycc-1234
```

## Example: Fixing a Load Balancer field (LYCC-9844-style)

```
/auto-flava-dev LYCC-9844
```

Typical iteration 1 learning: load `flava-lb-skill` **before** reading BFF source files — DTO conventions aren't obvious from grep. Graduated in 2 iterations.
