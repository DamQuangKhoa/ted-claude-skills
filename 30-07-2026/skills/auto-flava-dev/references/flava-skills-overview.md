# Flava Skills Overview

Quick reference for all flava skills — when to load them, what they cover, and known gotchas for the inner agent.

## Skill Loading Order (default for most bug-fix / feature tasks)

1. **`flava-jira-check`** — always first: reads the ticket, syncs main, creates the ticket branch, runs root cause analysis, and provides the implementation plan. Do not write any code before this step completes.
2. **Product skill** (lb / blueprint / vector / fractaldb) — load immediately after investigation, before reading any source files. Conventions are dense and not inferrable from grep alone.
3. **`flava-commit-skill`** — after implementation: stages only codebase paths, formats message correctly.
4. **`flava-pr-skill`** — after commit: creates PR via GitHub MCP, fills the template, assigns, labels, links Jira.

---

## Core Workflow Skills

### `flava-jira-check`
- **Use:** Any ticket investigation, root cause analysis, codebase fix implementation
- **Key step:** Syncs `main` and creates a branch named exactly like the ticket key (e.g. `CLOUDQA-84652`) **before** fetching the ticket
- **Approval gate:** Will not write product code until the user explicitly approves the plan — check the HTML report it generates
- **Output:** Vietnamese HTML report with RCA, planned changes, and todo checklist

### `flava-commit-skill`
- **Use:** Committing any staged changes
- **Format:** `type(scope): TICKET-ID: Sentence case description`
- **Critical:** Stage by path (`git add apps/product-lb/...`), not `git add -A` — never commits `.claude/`, `.cursor/`, or other AI tooling files unless explicitly asked
- **Valid scopes:** Defined in the monorepo `commitlint.config.js`

### `flava-pr-skill`
- **Use:** Opening PRs on `git.linecorp.com`
- **Tooling:** GitHub MCP only — never `gh` CLI
- **Template sections:** Summary, JIRA Ticket, Root Cause, Changes, Test Plan
- **After PR creation:** Posts PR URL as a Jira comment, then transitions ticket to **In Review**

### `flava-review-pr`
- **Use:** Reviewing another developer's PR
- **Not for:** Reviewing your own just-created PR

---

## Product Convention Skills

These must be loaded **before reading source files** in the relevant product. They contain DTO patterns, enum placement rules, composable structures, and type conventions that aren't obvious from the code alone.

### `flava-lb-skill`
- **Product:** `apps/product-lb/`
- **Covers:** Dual instance model (Network LB vs Application LB), BFF module structure, revision system, modal patterns, rate-limiting utils
- **Load when:** Any change to ports, clusters, revisions, replicas, drain, deploy, create/edit flows

### `flava-blueprint-skill`
- **Product:** `apps/product-cloud-blueprint/`
- **Covers:** Enum/type placement, Model suffix naming, `@/` vs `src/` imports, API class patterns, TanStack Query composables, BFF module layout
- **Load when:** Any change to deployment/run flows, GitHub SCM OAuth, drift detection, configuration versions

### `flava-vector-pipeline-skill`
- **Product:** `apps/product-dbs-for-vector-search/` — pipeline builder
- **Covers:** Ingest/search pipeline forms, processor definitions, visual vs code editor, simulation, `processorSerialization.test.ts`
- **Load when:** Work on pipelines, processors, pipeline wizard, simulate ingest/search
- **Important:** Always extend `processorSerialization.test.ts` and run vitest before committing

### `flava-vector-search-skill`
- **Product:** `apps/product-dbs-for-vector-search/` — general features
- **Load when:** Work on vector search features outside the pipeline builder

### `flava-fractaldb-skill`
- **Product:** FractalDB-related apps
- **Load when:** Any FractalDB feature or bug fix

---

## Jira & Ticket Skills

### `flava-jira-create-dev-ticket`
- **Use:** Creating new LYCC dev/feature/improvement/bug tickets
- **Default epic:** Flava operational task (LYCC-2141)
- **Fields:** Summary, description, issue type, component, assignee, priority, labels

### `flava-jira-create-sre-ticket`
- **Use:** Creating new LYCC SRE/infra tickets

### `flava-jira-wiki-check`
- **Use:** Checking Confluence wiki pages linked from a ticket or spec

---

## Observability Skills

### `flava-sentry-check`
- **Use:** Investigating a specific Sentry error linked in a Jira ticket
- **Pre-flight:** Requires Sentry MCP (`user-sentry`) to be configured

### `flava-sentry-triage`
- **Use:** Full Sentry triage session for one environment (default: stage)
- **Output:** Publishes a Confluence child page with A–D classified issues
- **Pre-flight:** Requires both Sentry MCP and Confluence MCP

---

## Utility Skills

### `flava-estimate-skill`
- **Use:** Converting a Confluence wiki page into a structured effort estimate (`estimate.md`)
- **Input:** Confluence page URL or page ID
- **Output:** Hierarchical task table with MD estimates and buffer

### `flava-product-explainer`
- **Use:** Orienting around an unfamiliar product area when the product skill name is unknown
- **Load when:** Task involves a product area you haven't encountered before

### `flava-md-to-html`
- **Use:** Converting markdown investigation/analysis reports to a rendered HTML file
- **Typically called by:** `flava-jira-check` after generating the report

### `flava-save-error`
- **Use:** Saving a persistent error note for future reference (e.g., a known MCP failure mode)

---

## Gotchas Learned Across Tasks

- **Always load the product skill before reading source files.** Convention violations are the #1 cause of failed PRs.
- **`flava-pr-skill` requires GitHub MCP, not `gh` CLI.** The remote is `git.linecorp.com`, not `github.com`.
- **`flava-commit-skill` excludes `.claude/` by default.** If the task produced strategy files, they won't be committed — this is correct behavior.
- **`flava-jira-check` has an approval gate.** The inner agent must wait for user approval before writing product code; factor this into iteration design.
- **Branch name = ticket key exactly** (e.g. `CLOUDQA-84652`, not `feature/cloudqa-84652`). The PR skill and Jira comment derivation depend on this.
