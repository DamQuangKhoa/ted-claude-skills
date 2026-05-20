---
name: flava-md-to-html
description: >
  Turn Markdown (or plain notes) into rich, standalone HTML pages for Flava Console work — specs,
  implementation plans, PR writeups, code explainers, incident reports, and interactive review
  artifacts. Uses pure HTML/CSS/JS (no framework): tabs, tables, SVG diagrams, syntax-highlighted
  snippets, severity badges, and optional copy/export buttons. Use this skill whenever the user
  asks to convert markdown to HTML, make an HTML artifact/file, turn a plan or spec into a readable
  page, create an HTML explainer (technical, not product marketing), review a PR as HTML, or says
  they want something easier to read/share than a .md file — even if they only paste markdown or
  say "make this digestible". Default page language is Vietnamese (tiếng Việt) unless the user
  asks for English or another language. Do NOT use for Vietnamese business product intro pages
  (use flava-product-explainer) or for Canvas/React dashboard deliverables (use canvas skill).
---

# Flava Markdown → HTML

Produce **single-file, standalone HTML** that is faster to read and share than Markdown. The goal
is information density and visual structure — not a pretty landing page for its own sake.

Inspired by Thariq Shihipar's article on HTML effectiveness with Claude Code ([gallery](https://github.com/anthropics/html-effectiveness)) and adapted for **flava-console** workflows.

## When to use HTML instead of leaving Markdown

| Prefer HTML when… | Markdown is fine when… |
|-------------------|-------------------------|
| Doc is > ~100 lines or has many sections | Short README, commit message, AGENTS snippet |
| Reader needs tabs, diagrams, diffs, tables | Linear notes only |
| You will share with reviewers who won't open the repo | File stays in repo for agents only |
| You want sliders, copy-to-prompt, or triage UI | No interaction needed |

## Distinction from other Flava skills

| Skill | Use for |
|-------|---------|
| **flava-md-to-html** (this) | Technical specs, plans, PR reviews, RCA, architecture — **Vietnamese by default**, dev/team audience |
| **flava-product-explainer** | Flava **product** marketing for stakeholders — Vietnamese, fixed 9-tab **business** template (non-technical) |
| **canvas** | Interactive React artifact in Cursor Canvas, data-heavy live exploration |

## Process

### 1. Clarify intent (one short pass)

Infer from the user message; only ask if unclear:

- **Artifact type**: spec / implementation plan / PR review / explainer / report / prototype / custom editor
- **Audience**: self, teammate, reviewer, stakeholder
- **Source**: path to `.md`, pasted content, ticket URL, git diff, or "read the codebase"
- **Output path**: where to write the file (see [Output locations](#output-locations))
- **Language**: default **Vietnamese**; use English only if the user says so (e.g. "in English", "tiếng Anh")

### 2. Gather content

Load sources in this order:

1. User-pasted Markdown or attached files
2. Paths the user named (`docs/`, `project-docs/`, ticket writeup, `estimate.md`, etc.)
3. **Codebase context** (Claude Code advantage): relevant `apps/product-*`, BFF modules, composables, recent `git log` / `git diff` when the artifact is about code or a PR
4. Jira/Confluence via MCP **only if** the user linked a ticket or asked to include it

Do not invent file paths or APIs. If content is thin, say what is missing in the HTML (a "Open questions" section) rather than fabricating detail.

### 3. Pick a layout pattern

Choose **one primary pattern** (combine lightly if needed):

| Pattern | HTML features | Typical trigger |
|---------|---------------|-----------------|
| **Structured doc** | Sticky nav or tabs, `<details>`, callout boxes | Long spec or plan |
| **Comparison grid** | CSS grid, labeled cards, tradeoff tags | "6 approaches side by side" |
| **PR / code review** | Diff blocks, severity chips, flowchart SVG | Review PR, explain streaming logic |
| **Explainer** | Diagram + annotated snippets + gotchas | "How does X work?" |
| **Report** | Executive summary, metrics table, timeline | Incident, weekly status, research |
| **Micro-editor** | Form controls + **Copy as JSON/Markdown/prompt** | Triage tickets, tune flags, reorder list |

Read `references/layout-patterns.md` for section outlines and copy-button patterns.

### 4. Build the HTML file

**Technical constraints:**

- **One `.html` file** — embedded `<style>` and `<script>`; no build step, no npm imports
- **No framework** (no React/Vue) unless the user explicitly asks for a prototype of a Vue component
- **Self-contained** — works via `file://` or static host; relative assets only if user provides images
- **Accessible basics** — semantic headings, sufficient contrast, `lang` on `<html>`, keyboard-focusable controls
- **Mobile-friendly** — `viewport` meta, fluid width, tabs that wrap on small screens

**Language (default: Vietnamese):**

- Set `<html lang="vi">` unless the user requested another language.
- Write **all UI copy** in Vietnamese: titles, tab labels, callouts, table headers, checklist items, footer.
- Keep **identifiers unchanged**: file paths, ticket keys, API names, error strings, code snippets, commit messages, PR titles.
- Tone: informal but professional — clear Vietnamese, avoid stiff translationese; explain jargon once in parentheses if needed.
- Bilingual source (English Jira/PR): **summarize and structure in Vietnamese**; do not leave long English prose in the body.

**Content rules:**

- Preserve facts from source Markdown; improve **structure**, not substance
- Replace ASCII diagrams with **SVG** (flow, sequence, boxes-and-arrows)
- Replace unicode "color squares" with real **CSS colors** or swatches
- Use `<table>` for tabular data; use `<pre><code>` for snippets (escape `<`, `>`, `&`)
- For code from the repo, cite **path** near each snippet (e.g. `bff/src/.../service.ts`)
- Add a generated **footer** with date and "Generated from …" (source path or ticket id)

**Starter shell:** copy structure from `references/starter-template.html` (tabs, theme variables, copy helper). Adapt; do not ship the placeholder content verbatim.

### 5. Enrich when the article's use cases apply

Apply these **only when they serve the stated goal** (explain why in a HTML comment if non-obvious):

- **Tabs** — separate sections (e.g. Tổng quan / Kế hoạch / Rủi ro / Kiểm thử, or Nguyên nhân / Thay đổi / Kiểm thử)
- **Severity colors** — PR findings: blocker / major / minor / nit
- **Interactive knobs** — design/prototype requests; always end with export/copy
- **Mermaid-like flows** — prefer inline SVG for single-file portability (no CDN dependency)

Avoid gimmicks: no autoplay video, no heavy animation, no external font CDNs unless user requires brand fonts.

### 6. Validate before saving

- [ ] File opens in browser without console errors
- [ ] Every tab `data-tab` / `id` pairing is consistent
- [ ] All user-provided links work; code is escaped in `<pre>`
- [ ] File size reasonable (< ~500KB); split into multiple HTML files only if user asked for a "web" of docs
- [ ] Output path exists or parent dir is created

### 7. Tell the user how to use it

After writing, give:

- Full path to the `.html` file
- One line: `open <path>` (macOS) or open in browser
- What to do next (e.g. attach to PR, share link after upload, feed back into Claude Code)

## Output locations

Default by artifact type (override if user specifies):

| Type | Default path |
|------|----------------|
| Product-scoped doc | `apps/product-<name>/docs/<slug>.html` or next to related `.md` |
| Ticket / investigation | `.claude/flava-md-to-html/docs/<TICKET-ID>-jira-check.html` (flava-jira-check) or `project-docs/<TICKET-ID>-<slug>.html` |
| Repo-wide / cross-cutting | `docs/html/<slug>.html` |
| Ephemeral scratch | `/tmp/flava-<slug>.html` — say it's not committed unless user asks |

Use kebab-case filenames: `implementation-plan-network-lb.html`, `pr-6920-review.html`.

## Markdown conversion rules

When source is Markdown:

| MD | HTML |
|----|------|
| `#` headings | `<h1>`–`<h4>` with anchor `id` for nav |
| Lists | `<ul>` / `<ol>` |
| Tables | `<table>` with `<thead>` |
| Fenced code | `<pre><code class="language-ts">` + language class for styling |
| Blockquote | `<blockquote class="callout">` |
| Links | `<a target="_blank" rel="noopener">` for external |
| Task lists `- [ ]` | Checkboxes (disabled) or status badges |

Do not leave raw Markdown syntax in the output.

## Example invocations

- "Chuyển `docs/plan.md` sang HTML có tab, kèm sơ đồ luồng dữ liệu"
- "Làm HTML review PR này — tập trung backpressure, chú thích diff"
- "Đổi ghi chú RCA CLOUDQA-90665 thành trang HTML, phần gotchas ở cuối"
- "6 ý onboarding trong md — lưới HTML so sánh cạnh nhau"
- "English version of this spec as HTML" → then use `lang="en"` and English copy

## Anti-patterns

- Dumping the entire Markdown into one `<pre>` — defeats the purpose
- Generic "AI slop" purple gradients and Inter font stacks unless user wants brand styling
- Splitting into 15 files when one navigable page would do
- Using **flava-product-explainer**'s Vietnamese 9-tab product template for a technical PR review
- Committing secrets, `.env` values, or tokens into HTML

## References (read as needed)

- `references/layout-patterns.md` — section templates per artifact type
- `references/starter-template.html` — minimal tabbed shell + copy utility
