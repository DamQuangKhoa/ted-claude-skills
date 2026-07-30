---
name: explore-with-codebase-memory
description: >-
  Explore, navigate, and understand any codebase using the codebase-memory-mcp
  knowledge graph instead of raw grep/Read/Explore-agent cycles. Use this skill
  WHENEVER a task requires understanding code you haven't just written — "where
  is X defined", "how does Y work", "find everything that calls Z", "trace this
  flow", "what's the architecture", "what breaks if I change this function",
  locating symbols, mapping call chains, finding hot paths, or scoping a
  refactor/bugfix/review across multiple files. Prefer this over grep, Read, and
  the Explore agent for any question that would otherwise mean reading 2+ files,
  because one graph query is far cheaper in tokens and returns structure (callers,
  callees, blast radius) that text search cannot. The graph must be indexed first;
  this skill handles indexing automatically if it isn't.
---

## Explore with codebase-memory

The `codebase-memory-mcp` server holds a queryable knowledge graph of the repo:
every function/method/class/variable as a node, with `CALLS`, `IMPORTS`, and
similarity edges between them, plus per-function complexity metrics. Structural
questions ("who calls this", "what's the blast radius", "where's the hot path")
are answered in one query — text search can't see edges, so it forces you to
read file after file to reconstruct what the graph already knows.

**Default reflex:** for any code-understanding task, reach for these tools before
grep/Read/Explore. Fall back to plain file reading only when the graph genuinely
can't answer (e.g. reading exact source you're about to edit — `get_code_snippet`
or Read is right there).

### Step 0 — Resolve the project (do this first, always)

Tool schemas are deferred. Load them with ToolSearch before first use:
`ToolSearch("select:mcp__codebase-memory-mcp__list_projects,mcp__codebase-memory-mcp__index_status,mcp__codebase-memory-mcp__search_code,mcp__codebase-memory-mcp__query_graph,mcp__codebase-memory-mcp__get_architecture")`
— pull others (`search_graph`, `trace_path`, `get_code_snippet`, `detect_changes`,
`index_repository`, `get_graph_schema`) the same way when a step needs them.

The project name is **not** the repo folder name — it's a mangled absolute path
(e.g. `Users-...-flava-console`). Never hardcode it.

1. Call `list_projects`.
2. Find the entry whose name ends with the current repo's folder name. Pass its
   exact `project` value to every subsequent call.
3. If `list_projects` is empty, or the repo isn't listed → **auto-index** (Step 0a).

### Step 0a — Auto-index when missing

Run `index_repository(repo_path="<absolute repo root>", mode="fast")`. `fast`
skips similarity/semantic edges — quickest, enough for structural exploration.
Use `moderate`/`full` only if a task needs similarity edges (e.g. "find code
similar to X"). Big monorepo indexes in seconds; the return reports node/edge
counts. Then re-run `list_projects` to get the name and continue.

Do NOT re-index on every invocation. If the project already appears in
`list_projects`, use it. Re-index only when the user says the code changed
materially and results look stale, or `detect_changes` is needed on a fresh diff.

### Step 1 — Go broad, then narrow

- `get_architecture(aspects=["all"])` — packages, entry points, routes, hotspots,
  Leiden clusters (the de-facto modules, which often cut across folders). Best
  first move for "explain this codebase" / "how is this structured".
- `get_graph_schema` — node labels + edge types available, when you need to know
  what you can query.

Then narrow:

- `search_code(pattern, project, limit)` — grep, but deduped into containing
  functions and ranked by structural importance (definitions first, tests last).
  `mode="compact"` (default) for signatures, `mode="files"` for just paths,
  `mode="full"` for source. Response carries `total_grep_matches` /
  `total_results` — compare to `limit` to detect truncation; raise `limit` or add
  `path_filter` regex rather than paging.
- `search_graph` — find nodes by label + `name_pattern` / `file_pattern` / degree
  filters. Use this to get a symbol's exact `qualified_name` before `trace_path`.

### Step 2 — Follow the structure

- `trace_path` — call chains: who calls a function, what it calls (depth 1–5). If
  it returns 0 rows, your name is wrong — `search_graph(name_pattern=".*Partial.*")`
  first, then feed the exact `qualified_name`.
- `query_graph` — Cypher for multi-hop / aggregation / complexity. Every Function
  and Method carries `complexity`, `cognitive`, `loop_depth`,
  `transitive_loop_depth`, `linear_scan_in_loop`, `alloc_in_loop`, `recursive`,
  etc. Hot-path hunt in one query:
  `MATCH (f:Function) WHERE f.transitive_loop_depth >= 3 OR f.linear_scan_in_loop >= 1 RETURN f.qualified_name, f.transitive_loop_depth ORDER BY f.transitive_loop_depth DESC`
- `get_code_snippet(qualified_name)` — read one function's source without opening
  the whole file.
- `detect_changes` — map a git diff to affected symbols + blast radius with risk
  classification. Use it to scope "what could this change break".

### query_graph — avoid the token trap

Return **specific properties**, not whole nodes, and always cap rows:

- ✅ `RETURN f.qualified_name, f.transitive_loop_depth ... ORDER BY ... ` with
  `max_rows` set (e.g. 20).
- ❌ `MATCH (n) RETURN n` or broad `count(*)` aggregations over all nodes — these
  can return >1MB and blow the token limit. If you need a count, cap hard with
  `max_rows` and project scalar columns.

There's a 100k-row ceiling; put `LIMIT` in the Cypher for broad matches.

### Token discipline

- Lead with a structural query. One graph call replaces a dozen grep/Read cycles.
- Target: finish any explore / debug / refactor-scoping / review task in ≤5 tool
  calls.
- Only drop to raw `Read` for source you're about to edit, or when the graph has
  no answer.
