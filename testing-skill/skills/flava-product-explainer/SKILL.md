---
name: flava-product-explainer
description: >
  Create a standalone interactive HTML explainer page (pure HTML/CSS/JS, no framework) for any
  Flava Cloud product — in Vietnamese, business-focused, NOT technical. The page follows a fixed
  9-tab structure: Tổng quan, Đối tượng, Vấn đề & Giải pháp, Hành trình, Tính năng, Giá trị,
  So sánh, Thực tế (end-to-end real-world walkthrough), Kiểm tra (quiz). Use this skill whenever
  the user says "tạo trang giới thiệu", "giải thích product", "interactive HTML cho product",
  "explainer page", "trang học về", "overview page", "tổng quan sản phẩm", "tạo HTML giải thích"
  — even if they only name a product without saying "HTML". Also use it to update or add tabs to
  an existing explainer file when the user says "thêm tab", "cập nhật explainer", or "chỉnh page".
---

# Flava Product Explainer Skill

Create a rich interactive HTML page that helps anyone understand a Flava Cloud product from a
**business perspective** — what problem it solves, who uses it, and how to get value from it.

## Reference template

Read this file before writing any code — it contains the full working CSS/JS framework and all
9 tab implementations for Vector Search. Adapt it rather than starting from scratch:

```
apps/product-dbs-for-vector-search/vector-search-overview.html
```

## Process

### 1. Gather product knowledge

Before writing HTML, collect information about the target product. Use these sources in order:

1. **Skill files first** — check `.claude/skills/` for a skill about the product (e.g.,
   `flava-lb-skill`, `flava-vector-search-skill`). If found, read it for domain knowledge.
2. **Codebase scan** — look at `apps/product-<name>/` for:
   - `AGENTS.md` — product overview
   - `client/src/` — feature list, form fields (what users configure)
   - `bff/src/modules/` — API endpoints and data structures
3. **Ask the user** if there are any key scenarios, real-world examples, or competitors they want
   highlighted. Do this in ONE question block, not multiple back-and-forth rounds.

### 2. Plan each tab's content

Map the gathered knowledge to the 9 tabs. Jot a quick outline before writing HTML. Key decisions:

| Tab | What to fill in |
|-----|----------------|
| **Tổng quan** | 1-line definition, 2-3 use-case cards, "concept explained simply" box |
| **Đối tượng** | 3-4 persona cards with avatar emoji, role, needs, benefits |
| **Vấn đề & Giải pháp** | 2-3 problem/solution pairs relevant to this product |
| **Hành trình** | 4-8 ordered steps from "zero" to "value delivered"; each step gets WHAT/WHEN/WHY/HOW cards |
| **Tính năng** | Feature accordion — 4-6 main features grouped logically |
| **Giá trị** | 4 metric cards + 4 benefit cards (cost, speed, UX, security) |
| **So sánh** | Table vs 3-4 alternatives (self-hosted, competitors, adjacent Flava products) |
| **Thực tế** | ONE end-to-end scenario for a Vietnamese company. Include config values, code blocks (dark theme), before/after results, outcome metrics |
| **Kiểm tra** | 5 quiz questions — mix of concept, use-case, and "gotcha" questions |

### 3. Write the HTML file

Output location: `apps/product-<name>/<product-name>-overview.html`

Use the reference template's CSS/JS as-is — do **not** rewrite the framework. Only change:
- Hero content (title, subtitle, stats)
- Nav buttons (update emoji + labels if needed; keep the same JS `showSection()` calls)
- Section content inside each `<section>` tag
- JS data arrays: `journeyDetails`, `questions`, `journeySteps`, etc.
- Color theme variables in `:root {}` if the product has a distinct identity color (optional)

### 4. Validate before saving

Mental checklist:
- [ ] Every `onclick="showSection('X', this)"` in nav has a matching `<section id="X">`
- [ ] `journeyDetails` array length matches the number of `.journey-step` divs
- [ ] `questions` array has exactly 5 items with `correct` index in range
- [ ] `selectStep(0)` and `initQuiz()` are called in the init block at bottom of `<script>`
- [ ] All `toggleRwPhase`, `togglePersona`, `toggleFeature` functions are present
- [ ] No broken `<div>` nesting (count opens vs closes mentally for complex sections)

## Content guidelines (Vietnamese, business tone)

- Write in **informal but professional Vietnamese** — "bạn", not "quý khách"; "dễ dàng", not "thuận tiện"
- **Avoid technical jargon** in user-facing text. If a technical term is necessary, explain it in
  parentheses on first use.
- For the **Thực tế** tab: pick a realistic Vietnamese company name and industry. Make numbers
  believable (not "10x overnight"). Show actual config values and API calls — this is where
  technical detail is appropriate because it demonstrates concretely how things work.
- For the **Kiểm tra** quiz: make wrong answers plausible (not obviously wrong). Good distractors
  teach by contrast.

## Hero stats

Pick 4 stats that are honest and impactful. Typical candidates:
- Time to first value (e.g., "~3 phút", "~10 phút")
- Management model ("Fully managed", "Zero-ops")
- Underlying technology ("Powered by X")
- Platform ("Chạy trên Flava Cloud")

## Adding a tab to an existing explainer

If the user wants to add/modify a single tab (e.g., "thêm tab Thực tế"):
1. Read the existing file
2. Add the nav `<button>` in the right position
3. Add the `<section>` with the right `id`
4. Add any required JS data/functions
5. Do NOT rewrite the whole file — use targeted edits with `replace_string_in_file` or
   `multi_replace_string_in_file`

## Example invocations

- "Tạo explainer HTML cho product Load Balancer"
- "Làm trang giới thiệu Object Storage bằng tiếng Việt"
- "Giải thích Kubernetes Engine cho business stakeholder, dạng HTML"
- "Thêm tab Thực tế vào file dns-overview.html"
- "Cập nhật quiz trong product-lb-overview.html"
