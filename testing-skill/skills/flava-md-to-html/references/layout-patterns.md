# Layout patterns for flava-md-to-html

Quick outlines. Combine sections; skip what does not apply.

**Language:** Section titles below are English labels for the author; render tab headings and body copy in **Vietnamese** by default (e.g. Nguyên nhân gốc, Thay đổi, Kế hoạch kiểm thử, Tổng quan, Rủi ro).

## Structured spec / implementation plan

1. **Hero** — title, ticket link, status badge, last updated
2. **Nav** — sticky sidebar or top tabs: Context | Approach | Changes | Risks | Test plan
3. **Context** — problem, constraints, out of scope
4. **Approach** — numbered decisions with rationale
5. **Changes** — table: area | file | what | why
6. **Diagrams** — SVG data-flow or sequence (one per major flow)
7. **Mockups** — optional wireframe boxes in CSS (not screenshots unless provided)
8. **Risks** — table: risk | mitigation | owner
9. **Test plan** — checklist `<ul>` with pass/fail placeholders

## PR / code review

1. **Summary** — 3–5 bullets
2. **Scope** — files touched, LOC estimate
3. **Focus areas** — what reviewer should care about (user-stated)
4. **Findings** — cards grouped by severity; each: location, issue, suggestion
5. **Diff highlights** — `<pre>` chunks with line refs; margin notes via CSS grid
6. **Flow** — SVG for unfamiliar subsystems
7. **Verdict** — approve / comment / request changes (neutral tone)

## Technical explainer

1. **One-liner** — what this system does
2. **Diagram** — main components (SVG)
3. **Walkthrough** — 4–6 steps with code snippets
4. **Gotchas** — callout list
5. **Related** — links to files, tickets, wikis

## Comparison grid (N options)

- CSS `display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));`
- Each card: title, thumbnail/wireframe, **tradeoff** tag, pros/cons
- Footer: "Recommended" callout only if user asked for a recommendation

## Report / incident / status

1. Executive summary (short)
2. Timeline table
3. Impact metrics
4. Root cause (5-whys or fishbone as nested lists)
5. Actions — open vs done
6. Appendix — raw logs in collapsible `<details>`

## Micro-editor (interactive)

Required elements:

- UI for the task (drag-drop, toggles, text areas)
- Live preview if applicable
- **Export button** — copies Markdown, JSON, or a Claude prompt string
- Brief instruction at top: "Tune values → Copy → paste into Claude Code / commit"

Copy button pattern (inline in page):

```javascript
function copyText(id) {
  const el = document.getElementById(id);
  navigator.clipboard.writeText(el.value || el.innerText);
  // optional: toast "Copied"
}
```

## Visual system (defaults)

Use CSS variables in `:root`:

- `--bg`, `--surface`, `--text`, `--muted`, `--accent`, `--border`
- Severity: `--sev-blocker`, `--sev-major`, `--sev-minor`, `--sev-nit`
- Prefer system font stack: `system-ui, sans-serif`
- Max content width ~ `960px` for prose; full width for grids
