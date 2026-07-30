---
name: Explore Codebase
description: Navigate and understand codebase structure using the knowledge graph
---

## Explore Codebase

Use the codebase-memory-mcp knowledge-graph tools to explore and understand the codebase.

### Steps

1. Run `get_graph_schema` first to see node/edge counts and available labels.
2. Run `get_architecture` for a high-level overview: languages, packages, entry points, routes, hotspots, clusters, ADRs.
3. Use `search_graph` (by label, `name_pattern`, `file_pattern`, degree filters) to find specific functions or classes.
4. Use `trace_path` to trace call chains — who calls a function and what it calls (depth 1-5). Find the exact name with `search_graph(name_pattern=".*PartialName.*")` first if `trace_path` returns 0 results.
5. Use `query_graph` for Cypher-like queries, e.g. `MATCH (f:Function)-[:CALLS]->(g) WHERE f.name = 'main' RETURN g.name`.
6. Use `get_code_snippet` to read a function's source by qualified name; `search_code` for grep-like text search.
7. Use `detect_changes` to map a git diff to affected symbols + blast radius with risk classification.

### Tips

- Start broad (`get_graph_schema`, `get_architecture`) then narrow to specific areas with `search_graph`.
- Prefer one graph query over dozens of grep/read cycles — it is far cheaper in tokens.
- If queries return the wrong project's results, pass `project="<name>"` (see `list_projects`).

### Token Efficiency Rules

- Lead with a structural query (`search_graph` / `trace_path` / `query_graph`) instead of reading files one by one.
- Target: complete any review/debug/refactor task in ≤5 tool calls.
