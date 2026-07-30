---
name: flava-review-pr
description: >-
  Review pull requests for **any Flava Console product** (`apps/product-*`) in
  the LYCC flava-console monorepo using GitHub MCP, Jira MCP, Confluence MCP, and
  **flava-jira-check** root-cause analysis. Use whenever the user asks to "review
  this PR", "review pull request", "check PR #123", pastes a GitHub PR URL or
  number, or wants a code review before merge — for any product (LB, vector
  search, blueprint, DBS, object storage, etc.), even if they do not mention
  Jira. Workflow: fetch PR via GitHub MCP → detect changed product(s) from paths
  → resolve Jira ticket → run flava-jira-check investigation (root cause +
  expected fix) → compare PR diff against that analysis and the **generic Flava
  code standards** (TS strict / no `any`, no hardcode → enum/named constant, BFF
  DTO validators, API stack order, tests, query invalidation, a **feature flag
  for large features** — wired all four points not just `.env` — and a **real
  Jira ticket in the commit messages, not NO-JIRA**) → **run the scoped
  lint / type:check / build gates for real** and report pass/fail. Writes a
  **standalone HTML review report** (tabs: overview, Jira, alignment, Flava
  standards + gate results, findings, draft GitHub review) for the user to open
  in a browser. Also shows a short chat summary with the report path. **Never
  auto-post to GitHub** — after the review, **ask the user** whether they want a
  comment on the PR; only call `pull_request_review_write` when they explicitly
  say yes (e.g. "post review", "add comment to PR"). Re-reviews and "check again"
  do **not** imply posting. Opt-out: "review only", "don't comment", "no Jira",
  "skip wiki".
---

# Flava Review PR

Structured PR review for **any product (`apps/product-*`)** in the **LYCC/flava-console** monorepo.

**Core idea:** Treat the Jira ticket as the source of truth for *what should be fixed*, use **flava-jira-check** to derive the *root cause and expected fix*, then judge whether the PR *actually solves it*, follows the **generic Flava code standards**, and **passes the real lint / type:check / build gates**.

**Default repo:** `owner=LYCC`, `repo=flava-console`.

**Scope:** Deep review for every changed product under `apps/product-*`. Detect the product(s) from the changed paths and review each one. A PR may touch several products; review them all.

**GitHub posting (mandatory — opt-in only):**

- **Default:** Review ends with HTML report + chat summary + draft review text in the **Draft** tab. **Stop.** No GitHub write tools.
- **Never auto-post** — not after first review, not after re-review ("check again", "verify", "author replied"), not because the verdict is obvious.
- **Always ask** before posting, with a clear yes/no question, for example:

  > I've finished the review (HTML: `…/pr-NNNN-review.html`). **Do you want me to post this as a GitHub PR review?** Reply **yes** with `APPROVE`, `REQUEST_CHANGES`, or `COMMENT` (or **no** / **review only** to keep it local).

- **Post only if** the user explicitly opts in: "post review", "add comment to PR", "submit to GitHub", "post as REQUEST_CHANGES", etc.
- **Do not post if** the user says "review only", "don't comment", "no PR comment", or gives no answer / only discusses findings.
- Ambiguous replies ("ok", "thanks", "LGTM", "looks good") are **not** permission to post — ask again.
- Use `pull_request_review_write` for PR reviews; `add_issue_comment` only if the user asks for a general PR comment instead of a review.

**Required companion skills (read before reviewing the code):**

| Skill | When |
|-------|------|
| **flava-jira-check** | Root cause + expected fix from ticket (§5 — investigation only, no git branch, no code edits) |
| **flava-blueprint-skill** | Canonical example of Flava conventions — enum/constant placement, `*Model`-suffix types, `@/` client vs `src/` BFF imports, BFF DTO rules. Use as the reference for the generic checklist. |
| **flava-`<product>`-skill** | If a matching product skill exists for a changed product (e.g. `flava-lb-skill`, `flava-vector-search-skill`, `flava-fractaldb-skill`), load it as **optional extra context** for that product's specifics. Best-effort — do not fail if none exists. |

---

## End-to-end workflow (required order)

| Step | Action |
|------|--------|
| **1** | **Parse PR input** — owner, repo, PR number (§1) |
| **2** | **GitHub MCP — fetch PR** — metadata, files, diff, CI (§2) |
| **3** | **Detect product(s)** — from changed `apps/product-*` paths (§2.1) |
| **4** | **Jira MCP — ticket** — keys from PR; `jira_get_issue` (§4) |
| **5** | **flava-jira-check — root cause** — investigation methodology only (§5) |
| **6** | **Confluence MCP (optional)** — wiki linked from ticket (§6) |
| **7** | **Compare PR vs root cause** — alignment, gaps, over/under-fix, side effects (§7) |
| **8** | **Flava code standards review** — generic checklist + **run gates** on the diff (§8) |
| **9** | **Generate HTML report** — standalone `.html` file (§9) |
| **10** | **Present chat summary** + report path + draft GitHub body (§10). **Stop.** |
| **11** | **Ask user** — "Post this review on GitHub?" (yes/no + event). **Do not post by default.** |
| **12** | **Post review (optional)** — GitHub MCP **only if user said yes** (§11). |

---

## 1. Parse PR input

Accept:

- URL: `https://git.linecorp.com/LYCC/flava-console/pull/6933`
- Shorthand: `#6933`, `PR 6933`
- Branch: use **`search_pull_requests`** with query `head:<branch>`

Defaults: `owner=LYCC`, `repo=flava-console`.

**Read GitHub MCP tool schemas** under `user-github` before calling.

---

## 2. GitHub MCP — fetch PR context

Use **`pull_request_read`**:

| method | Purpose |
|--------|---------|
| `get` | Title, body, author, branches, state |
| `get_files` | Changed paths — group by `apps/product-*` |
| `get_diff` | Full diff |
| `get_check_runs` | CI on head commit |
| `get_reviews` | Avoid duplicate reviews |

From PR body, extract flava template sections: **Summary**, **JIRA Ticket**, **Root Cause**, **Changes**, **Test Plan**.

### 2.1 Detect product(s)

- Group changed files by their `apps/product-*` root (e.g. `apps/product-lb`, `apps/product-vector-search`, `apps/product-cloud-blueprint`).
- **Deep-review every changed product.** For each product, apply the generic Flava standards (§8) and run its scoped gates (§8.6).
- For each changed product, load the matching `flava-<product>-skill` if one exists (see companion table) as optional extra context; otherwise proceed with the generic checklist alone.
- Changes **outside** `apps/product-*` (e.g. `shared/`, `packages/`, `scripts/`) still get a code-standards pass; note them and run their gates if the changed package exposes lint/type:check/build.

If the PR changes no product code at all (docs/config only), tell the user and offer a lighter generic review.

---

## 4. Jira MCP — ticket context

### 4.1 Collect ticket keys

Parse `(LYCC|CLOUDQA)-[0-9]+` from PR title, body (`## JIRA Ticket`), commits, branch name. Ignore `NO-JIRA`.

### 4.2 Fetch ticket

```
jira_get_issue(issue_key="LYCC-1234", fields="*all", comment_limit=10)
```

Note: summary, description, acceptance criteria, status, components (which product?), comments, Confluence links, linked issues.

**Opt out:** `"no Jira"` / `"PR diff only"`.

---

## 5. flava-jira-check — root cause (investigation only)

**Load and follow flava-jira-check §1–4.** Do **not** run flava-jira-check §0 (git branch checkout) or §7+ (implementation, commits, todos for fixing).

### 5.1 What to produce

From the ticket, build an **expected fix profile**:

```markdown
### Root cause analysis (from ticket + codebase)

**Reported problem:** ...
**Direct cause:** ... (file/module if identified)
**Contributing factors:** ...
**Impact scope:** which product(s)/flow; env/region
**Confidence:** Confirmed / Hypothesis — [what would verify]

**Expected fix (what a correct PR should do):**
1. [Concrete change — e.g. convert pageNum/pageSize → limit/offset in BFF]
2. [Files/areas likely touched — e.g. `bff/.../instance.service.ts`]
3. [Flows to preserve — e.g. error logging unchanged, pagination edge cases]

**Out of scope for this ticket:** ...
```

Use ticket comments, stack traces, and **local codebase search across the whole repo** (grep, read callers/callees) — scope to the changed product(s) first, but follow the flow wherever it goes (client → BFF → shared). Trace BFF controller → service → upstream when APIs are involved.

### 5.2 Confluence (within jira-check)

If the ticket links wiki pages, fetch via Confluence MCP (see §6) and fold relevant expectations into **Expected fix**.

---

## 6. Confluence MCP — wiki context

Same as **flava-jira-wiki-check §2**: `confluence_get_page` / `confluence_search`, markdown preferred.

Extract intended behavior and acceptance criteria; flag **ticket vs wiki** contradictions.

**Opt out:** `"skip wiki"`.

---

## 7. Compare PR vs root cause

This is the **central judgment** of the review.

For each item in **Expected fix**:

| Check | Question |
|-------|----------|
| **Addresses root cause?** | Does the diff fix the direct cause, or only symptoms? |
| **Complete?** | Missing files, edge cases, or related call sites? |
| **Over-scoped?** | Unrelated refactors, drive-by changes? |
| **PR Root Cause section** | Does the author's stated root cause match your analysis? |
| **Acceptance criteria** | Met / partial / not met |

Also assess **side effects** (generic Flava):

- **Query cache invalidation:** Do mutations invalidate the right query keys (the product's `QUERY_KEY.*` / TanStack Query keys) so list/detail views refresh? Stale-cache-after-mutation is a common bug.
- **Mutation sequencing:** Dependent mutations should chain in `onSuccess`, not fire in parallel where order matters.
- **Modal / form submit:** Validation before mutate; dirty check; loading state on submit; success handler invalidates/refetches.
- **Cross-flow regression:** List / detail / create / edit / delete flows; pagination; any nearby flow the diff could disturb.
- **API shape changes:** If request/response shape changed, all consumers (client types, apis, composables, UI) must be updated in step (see §8.2).

Record as:

```markdown
### PR vs root cause

| Expected fix item | PR status | Notes |
|-------------------|-----------|-------|
| ... | ✅ Done / ⚠️ Partial / ❌ Missing / ➕ Extra | ... |

**Overall alignment:** Strong / Acceptable with gaps / Does not fix root cause
```

---

## 8. Flava code standards review

Apply this **generic checklist** (one shared list for all products) to **every changed file**, then **run the scoped gates for real** (§8.6). Flag violations by severity. For product-specific nuances, lean on the matching `flava-<product>-skill` if loaded; **flava-blueprint-skill** is the canonical reference for the conventions below.

### 8.1 TypeScript strict / no `any`

- No `any`; no non-null `!` abuse. Types live in `types/` (client) — not ad-hoc inline in composables/components.
- Follow the `*Model`-suffix convention for domain model types (see flava-blueprint-skill).
- Client imports use `@/`; BFF imports use `src/` — no cross-boundary imports.

### 8.2 No hardcode

- Magic strings/numbers must be an **enum** (in `enums/`) or a **named constant** — not inline literals (raw status strings, query keys, numeric limits, etc.).
- UI copy → `const content = { title: '...' }` at the top of the component.
- New API fields must flow through the full stack **in order**: **BFF DTO → client types → apis → composable → UI**. A partial stack (e.g. DTO added but composable/UI missed) is a gap.

### 8.3 BFF DTOs and types

- class-validator decorators on **every** DTO field.
- Nested DTO classes declared **before** the parent class in the same file.
- BFF errors via the shared `handleError` — no duplicate ad-hoc catch blocks.

### 8.4 Unit tests

Pure logic that encodes business rules **should** have Vitest coverage when changed:

- **New or changed pure logic** (utils / helpers / validators / BFF services) → expect new/updated `*.test.ts` with meaningful cases (not trivial asserts).
- **Bug fix** → a test should reproduce or guard the fixed behavior.
- **UI-only / wiring** → Test Plan may be manual; still ask if composable logic deserves extraction + test.

Note if the PR adds no tests where logic changed. (The `test:ci` gate in §8.6 also runs the existing suite where present.)

### 8.5 UI / validation

- Lazy validation pattern (`useLazyValidation` + `useField`, or the modal `validationVisible` pattern) — errors not shown before the field is touched.
- Flava UI components only; Tailwind for layout.

### 8.5b Feature flag for large / risky features

A **large or multi-file feature** (roughly: a new user-facing capability, a new form option/flow, or a change spanning many files) **should ship behind a runtime feature flag** so it can be rolled out per environment and turned off without a revert. If the PR adds a sizable feature and there's **no flag**, raise it as a **Major** finding ("large feature with no rollout flag — how do we disable it if stage/prod breaks?"). A pure bug fix or refactor does not need a flag.

When a flag **is** present, verify it's wired correctly — a Flava flag is **not** a plain `.env` read. It only works if registered in **all** of these, and consumed via `getProperty`:

| Point | What to check |
|-------|---------------|
| `<product>/client/.env` | `ENABLE_<X>_FEATURE_FLAG=...` present |
| `client/vite.config.ts` `inject.data` | the flag added with the `isBuildToStaticFile ? '$FLAG' : process.env.FLAG` pattern |
| `client/index.html` `window.flava` | `<%= FLAG %>` line before `Object.freeze(window.flava)` |
| type decl (`global.d.ts` `@flava-federation/shell/index`) | flag in the `'true' | 'false'` union |
| **consumer** | read via `getProperty('ENABLE_<X>_FEATURE_FLAG') === 'true'` — **not** `process.env` or a raw import |

If any of the four registration points is missing, the flag **silently does nothing** (`getProperty` returns undefined) — flag it as **Blocker/Major**: "flag set in .env only → no-op". Also confirm the flag **fails closed** (unknown/missing value → feature OFF, old behavior preserved) and that OFF reproduces exactly the pre-PR behavior. See the `flava-flag-feature` skill for the canonical mechanism.

### 8.5c Commit messages carry a real Jira ticket

Fetch the branch commits (`git log main..<head> --oneline` or GitHub `list_commits`) and check each subject follows commitlint `type(scope): TICKET: msg` with a **real** `(LYCC|CLOUDQA)-NNNN` — not `NO-JIRA`. A substantive feature/fix landing as **NO-JIRA** is a **Minor/Major** finding (traceability gap): ask for the ticket. (`NO-JIRA` is only acceptable for trivial chores.) If the PR **title** has a ticket but a commit doesn't (or vice-versa), note the mismatch — the Jira automation keys off commit subjects.

### 8.6 Run gates (real — do not simulate)

For **each changed package** (client and/or BFF of each changed product, plus any changed `shared/` / `packages/` package), run the scoped gates and report pass/fail. **Do not just reason about them — actually run them.**

**Order — auto-install first** (deps may be missing in a fresh checkout/worktree):

```
pnpm --filter <workspace-pkg> install --frozen-lockfile
pnpm --filter <workspace-pkg> run lint
pnpm --filter <workspace-pkg> run type:check
pnpm --filter <workspace-pkg> run build
```

Rules:

- Resolve `<workspace-pkg>` from the package's `package.json` `name` (e.g. `product-lb-client`, `product-lb-bff`, `product-vector-search-client`). Discover names with `pnpm -r list --depth -1`.
- **Grep `package.json` `scripts` first** and skip any script that doesn't exist — some packages lack some gates (e.g. a BFF may have no `type:check` or `test:ci`). Note "no `<script>` script — skipped", don't report it as a failure.
- If a package has a `test:ci` script and logic changed, also run `pnpm --filter <workspace-pkg> run test:ci`.
- **Shared-package prerequisite:** if a changed client depends on a shared package (e.g. `flava-shell-client`), build that shared package first before `type:check` (`pnpm --filter flava-shell-client run build`), per AGENTS.md.
- **Known pre-existing failures:** the **vector-search client** has pre-existing `type:check`/lint failures (e.g. `IndexFieldFormModel.vue`, `SelectFieldRenderer.vue`). If a failing gate reproduces on `main` independent of the PR, mark it **pre-existing** and do **not** count it against the PR — but do flag any *new* failures the PR introduces.

Record the gate results as:

```markdown
### Gate results

| Package | install | lint | type:check | build | test:ci | Notes |
|---------|---------|------|------------|-------|---------|-------|
| product-lb-client | ✅ | ✅ | ✅ | ✅ | ✅ | |
| product-lb-bff | ✅ | ✅ | — (no script) | ✅ | — (no script) | |
| product-vector-search-client | ✅ | ⚠️ pre-existing | ⚠️ pre-existing | ✅ | n/a | fails on main too — not caused by PR |
```

Legend: ✅ pass · ❌ fail (caused by PR) · ⚠️ pre-existing (fails on main) · — script absent.

### 8.7 Summarize standards

```markdown
### Flava standards

| Area | Status | Findings |
|------|--------|----------|
| TS strict / no any | ✅ / ⚠️ / ❌ | ... |
| No hardcode (enum/const) | ✅ / ⚠️ / ❌ | ... |
| Feature flag (large feature) | ✅ / ⚠️ / ❌ / n/a | present + wired all 4 points + fails closed; or "not needed (bug fix)" |
| Jira ticket in commits | ✅ / ⚠️ / ❌ | real LYCC/CLOUDQA key, not NO-JIRA |
| Side effects / invalidation | ✅ / ⚠️ / ❌ | ... |
| API stack order / DRY | ✅ / ⚠️ / ❌ | ... |
| Unit tests | ✅ / ⚠️ / ❌ | ... |
| BFF DTO / types | ✅ / ⚠️ / ❌ | ... |
| Gates (lint / type:check / build) | ✅ / ⚠️ / ❌ | see gate-results table |
```

---

## 9. Generate HTML review report (required)

After completing §5–8, **always** write a standalone HTML file the user can open in a browser.

### 9.1 Template and layout

- Read **`references/review-report-template.html`** for structure (tabs, CSS, JS).
- Follow **flava-md-to-html** rules: one file, embedded CSS/JS, no framework, `lang="vi"` for UI copy.
- **Tabs (Vietnamese labels):** Tổng quan · Jira · So sánh fix · Chuẩn Flava · Findings · Draft review
- Use severity badges (`.badge-ok`, `.badge-warn`, `.badge-bad`) for alignment, standards, and gate-result tables.
- Escape `<`, `>`, `&` in code snippets inside `<pre>`.

### 9.2 Output path

Default filename pattern:

```
.claude/flava-review-pr/reviews/pr-<NUMBER>-review.html
```

Example: `.claude/flava-review-pr/reviews/pr-6998-review.html`

Override only if the user specifies another path. Create parent directories if needed.

### 9.3 Tab content

| Tab | Include |
|-----|---------|
| **Tổng quan** | PR title, author, branch, CI, changed product(s), file count, verdict badge, 2–3 sentence summary |
| **Jira** | Ticket link(s), summary, status, component, root cause analysis (§5), wiki if any |
| **So sánh fix** | Expected-fix vs PR table (§7), overall alignment |
| **Chuẩn Flava** | Flava standards table (§8.7) **and** the gate-results table (§8.6) — fill both `{{STANDARDS_CONTENT}}` and `{{GATE_RESULTS}}` |
| **Findings** | Blockers / Major / Minor / Questions lists; test plan assessment |
| **Draft review** | GitHub-ready markdown in `<textarea>` + **Sao chép** button calling `copyDraft()` |

Header must show verdict with class `verdict-approve` | `verdict-changes` | `verdict-comment`.

### 9.4 Tell the user

After saving, share in chat:

- Full path to the HTML file
- `open <path>` (macOS) to view locally
- One-line verdict; link to open the report for full detail

---

## 10. Present chat summary (do not post to GitHub yet)

```markdown
## PR Review: [LYCC/flava-console#NNNN](PR URL)

### PR overview
- **Title:** ...
- **Author:** ...
- **Branch:** `head` → `base`
- **CI:** ...
- **Product(s) changed:** ... (e.g. product-lb, product-vector-search)
- **Files changed:** N (+ list key paths per product)

### Jira context
- **Ticket(s):** [LYCC-1234](https://jira.workers-hub.com/browse/LYCC-1234)
- **Summary / status:** ...
- **Component:** ...

### Root cause analysis (flava-jira-check)
[Paste §5.1 output — condensed]

### Wiki consulted
- **Pages:** ... — or none
- **Relevant expectations:** ...

### PR vs root cause
[Table from §7]

### Flava standards
[Table from §8.7]

### Gate results
[Table from §8.6 — lint / type:check / build per package]

### Findings

#### Blockers
- [ ] ...

#### Major
- [ ] ...

#### Minor / suggestions
- [ ] ...

#### Questions
- [ ] ...

### Test plan assessment
[PR Test Plan vs required unit tests / manual steps]

### Verdict
**[Approve | Request changes | Comment only]** — one-line rationale

---

### Draft GitHub review (for PR — only if you ask to post)

[Concise markdown for GitHub: ticket link, root-cause alignment, top blockers/majors, standards gaps, failing gates, test gaps. No internal investigation dumps.]

---

**Next step:** Open the HTML report for full detail. The agent will ask whether to post on GitHub — nothing is posted automatically.
```

**Do not** call GitHub write tools in §10. End the turn by **asking** the posting question (see **GitHub posting** above).

---

## 11. Post review on GitHub (only when user opts in)

Enter this section **only** after the user explicitly asks to post on the PR.

1. Confirm **which event**: `APPROVE` | `REQUEST_CHANGES` | `COMMENT` — use their words or ask once if unclear.
2. Use the **user-approved** text (merge any edits they gave when saying yes).
3. **`pull_request_review_write`**: `method: "create"`, `body`, `event`, `commitID` = PR head SHA.
4. **Inline review comments** only if the user explicitly asks (pending review + `add_comment_to_pending_review`).
5. Confirm PR URL + event posted.
6. **Do not** transition Jira or add Jira comments unless the user asks separately.

If the user declines posting, acknowledge and keep the HTML report as the deliverable.

---

## Edge cases

- **Re-review / "check again" / author replied:** Run full review again and update HTML; **still ask** before posting — never auto-post a follow-up review.
- **User said "help me review" only:** Deliver HTML + summary; ask about posting; do not post.
- **PR Root Cause wrong but code right:** Call it out — suggest updating PR description
- **PR Root Cause right but code wrong:** Blocker — request changes
- **NO-JIRA:** Skip ticket alignment; review Flava standards + gates + technical correctness only
- **Large / multi-product PR:** Prioritize files tied to root cause; list what was skimmed; still run gates for every changed package
- **BFF-only / client-only:** Still check the full stack if API shape changed (§8.2 stack order)
- **Gate failure is pre-existing:** Reproduce on `main`; if it fails there too, mark pre-existing and don't hold the PR responsible

---

## Related skills

- **flava-jira-check** — Root cause methodology (this skill uses investigation half only)
- **flava-blueprint-skill** — Canonical Flava conventions (enums/constants, `*Model` types, `@/` vs `src/`, BFF DTOs) — the reference for §8
- **flava-`<product>`-skill** — Load the matching one for each changed product when it exists (e.g. flava-lb-skill, flava-vector-search-skill, flava-fractaldb-skill) for product-specific detail
- **flava-jira-wiki-check** — Heavier wiki + plan workflow before implementation
- **flava-pr-skill** — Creating PRs
- **flava-md-to-html** — HTML layout patterns (this skill uses PR-review tab set)

---

## Example triggers

- "Review PR #6933"
- "Does this PR fix CLOUDQA-83781 pagination?"
- "Review my vector-search PR — don't post yet"
- "Check PR 7012 and run the gates"
