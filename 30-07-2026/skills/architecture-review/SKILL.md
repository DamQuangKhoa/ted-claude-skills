---
name: architecture-review
description: >-
  Read a codebase and generate a comprehensive **ARCHITECTURE.md** with a fixed
  27-section structure and Mermaid diagrams (system-architecture diagram is
  mandatory). Use whenever the user asks to "review the architecture", "generate
  an architecture doc / ARCHITECTURE.md", "document this codebase", "map the
  system", "onboarding doc", "architecture overview", "how is this project
  structured", or hands over a repo/folder and wants a structural write-up — even
  if they don't say "27 sections". Explores structure/dependencies/flows via the
  codebase-memory graph first (falls back to file reads), fills every section
  from real evidence, and marks anything it cannot confirm as `> Not Found`
  rather than guessing. Section prose defaults to Vietnamese; diagrams are Mermaid.
  Do NOT use for a single-file explanation, a PR review (that's a diff review), or
  writing new code — this produces a read-only architecture document.
---

# Architecture Review

Read a codebase and write **`ARCHITECTURE.md`** — a structural map a new engineer can read to understand the whole system. Fixed 27-section skeleton, Mermaid diagrams, and an ironclad rule: **only document what the code actually shows; mark everything unconfirmed as `> Not Found`.** A confident-but-wrong architecture doc is worse than an honest gap — readers trust it and get misled.

**Output:** `ARCHITECTURE.md` at the repo root (or a path the user gives). Section prose in **Vietnamese**; diagrams in **Mermaid** code blocks (render in any markdown preview with Mermaid support).

**Grounding rule (non-negotiable):** every claim traces to a real file / graph edge / config value. If you can't find evidence for a section (or a field within it), write `> Not Found` for that item. Do NOT infer a mobile app, a cache, an auth scheme, etc. from vibes — either it's in the code or it's Not Found.

---

## Explore: graph first

Fill the sections from evidence, cheapest source first:

1. **codebase-memory graph** (preferred) — if the repo is indexed (`index_status`), use it:
   - `search_graph` / `search_code` — locate modules, entrypoints, symbols (§3, §5).
   - `query_graph` (Cypher over CALLS/IMPORTS edges) — dependency graph (§12), request/business flows (§6, §11), call chains.
   - `get_architecture` / `trace_path` — high-level structure + specific flows.
   - If not indexed and the repo is large, offer to `index_repository` (mode `fast`) first — one index beats dozens of grep passes.
2. **File reads** (fallback / for the things the graph doesn't hold) — `package.json`/`go.mod`/`pyproject`/etc. (§2 tech stack), config files + `.env(.example)` (§14), Dockerfile/compose/k8s (§4, §20), route definitions (§10), migration/schema files (§9), CI configs (§20). The graph maps CODE; config/infra/docs come from files.

Delegate the heavy exploration to a subagent if it would read many files — keep only the synthesized findings.

---

## The 27 sections (fixed order — emit ALL, in this order)

Use these exact numbered headings. Under each, write what the evidence supports; if none, the whole section body is `> Not Found`.

1. **Tổng quan dự án** — what the project is, business domain, overall architecture style (monolith / modular-monolith / microservice / monorepo), the main pieces (frontend/backend/mobile/API/DB/infra) as a bullet list. Any piece with no evidence → `> Not Found`.
2. **Tech Stack** — languages, frameworks, major libs, runtime versions — from manifests, not guesses.
3. **Folder Structure** — top-level layout + what each key dir holds. A trimmed tree.
4. **System Architecture (Diagram Mandatory)** — a **Mermaid diagram** of the runtime topology (clients → gateway → services → datastores → external). This diagram is REQUIRED; if you truly can't derive topology, say so explicitly and draw what you can.
5. **Module Breakdown** — the modules/packages/services and each one's responsibility.
6. **Request Flow** — how a request travels end to end (entrypoint → middleware → handler → data). Mermaid sequence or flowchart.
7. **Authentication** — how identity is established (session/JWT/OAuth/…), where. `> Not Found` if none.
8. **Authorization** — how access is decided (roles/permissions/policies), deny paths.
9. **Database** — engines, ORM, schema shape / key tables, migrations.
10. **API Architecture** — style (REST/GraphQL/gRPC/RPC), route groups, versioning, realtime (websocket/SSE).
11. **Business Flow** — a key domain flow end to end (Mermaid).
12. **Dependency Graph** — module/service dependencies (Mermaid graph from IMPORTS/CALLS edges). Note cycles if any.
13. **External Services** — third-party APIs, SaaS, queues, object storage the code integrates with.
14. **Configuration** — config sources, env vars, secrets handling, per-environment config.
15. **Logging** — logging lib, levels, structured?, where logs go.
16. **Error Handling** — error strategy, central handler, error types, ret/catch conventions.
17. **Security** — input validation, secrets, transport, headers, known controls. `> Not Found` per item absent.
18. **Performance** — caching, pooling, pagination, async/batching, hot-path notes.
19. **Scalability** — statelessness, horizontal scaling, bottlenecks, queues.
20. **Deployment** — how it ships: Docker/compose/k8s, CI/CD, environments, infra.
21. **Testing** — test frameworks, layers (unit/integration/e2e), where tests live, coverage if visible.
22. **Coding Convention** — lint/format config, naming, import rules, enforced style.
23. **Design Pattern** — architectural + code patterns actually used (repository, DI, factory, CQRS, …) with a real example.
24. **Strengths** — what the architecture does well, evidence-based (not flattery).
25. **Technical Debt** — real debt spotted: dead code, TODOs, tight coupling, missing tests, cycles.
26. **Improvement Proposal** — concrete, prioritized suggestions tied to the debt in §25.
27. **Appendix** — extra diagrams (a detailed sequence is great here), glossary, references, links.

---

## Diagrams (Mermaid)

- §4 is **mandatory**; §6, §11, §12 strongly encouraged; §27 for extra depth.
- Use fenced ```mermaid blocks. Prefer `graph TD`/`flowchart` for topology/deps, `sequenceDiagram` for flows.
- Keep node labels short + real (actual service/port/db names from the code). Don't invent components to make the diagram look full — a smaller true diagram beats a padded fictional one.
- **Verify Mermaid actually parses — "balanced fences" is NOT enough** (a lexer error still fails to render). Common breakers to check every diagram for:
  - **No `\n` in node/edge labels** — Mermaid needs `<br/>` for a line break, not `\n`. `["a\nb"]` fails; use `["a<br/>b"]`.
  - **Dotted/thick links with a label need spaces**: `A -. "label" .-> B` and `A == "label" ==> B` — NOT `A -.label.-> B` (the label's own dots/chars collide with the link tokens; this is a classic "Lexical error on line N, Unrecognized text").
  - **Labels with special chars** (`/`, `:`, `(`, `.`, `#`) must be **quoted**: `["/api/lb/v1"]`, `["nginx :80"]`.
  - `flowchart`/`graph` edges use `-->` / `-.->` / `==>`; `sequenceDiagram` uses `->>` / `-->>`. Don't mix a bare `->` into a flowchart.
  - Every `subgraph` has a matching `end`.
  - If unsure a diagram parses, keep it simpler — a plain `graph TD` with quoted labels almost always renders. A diagram that errors is worse than a smaller one that works.

## Header block (top of the file)

Open the doc with a short note stating: it follows this skill's fixed 27-section structure, is generated **from evidence in the codebase**, and anything unconfirmed is marked `> Not Found`. List the repos/packages actually scanned.

## Workflow

1. **Locate the target** — whole repo, or a subpath/package if the user scoped it. Confirm the output path (default `ARCHITECTURE.md` at root).
2. **Explore** graph-first (§Explore), delegating a broad read to a subagent if large. Gather evidence per section.
3. **Draft all 27 sections in order.** For each, write evidence-backed content or `> Not Found`. Never skip or reorder a section.
4. **Draw the mandatory §4 diagram** (+ §6/§11/§12/§27 where evidence supports). Validate Mermaid syntax.
5. **Write `ARCHITECTURE.md`.** Header block first, then §1–§27.
6. **Report** to the user: path, which sections came back `> Not Found` (the coverage gaps), and offer to open the preview. Do NOT claim a section is complete when it's `> Not Found`.

## Rules / anti-patterns

- **Never invent.** No fabricated components, endpoints, or flows. Evidence or `> Not Found`.
- **All 27, in order** — even if half are `> Not Found` (that itself is a useful signal about the codebase).
- **Diagrams reflect reality** — real names/ports, no decorative fictional nodes.
- **Config/infra from files, code-structure from the graph** — don't ask the graph for Dockerfiles or the file tree for call chains.
- **Read-only** — this skill writes ONE doc; it does not modify source, open PRs, or run builds.
- Large repo: say what you scanned and what you sampled/skipped — silent partial coverage reads as "fully reviewed" when it wasn't.

## Related skills
- **explore-with-codebase-memory** — the graph navigation this skill leans on for §5/§6/§12.
- **flava-md-to-html** — if the user wants the doc as a styled standalone HTML page instead of `.md`.
