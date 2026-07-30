# Token Optimization

## Why This Matters

Token waste compounds. A session that reads 5 files unnecessarily at startup costs
those tokens on every single session for the life of the project. Over 100 sessions
that is a significant drain on daily limits and a meaningful cost in paid plans.

Three Man Team addresses token waste structurally — the rules are in CLAUDE.md so they
fire automatically, not as a reminder you might follow.

## The Five Rules

Built into every Three Man Team session router:

```
Is this in a skill or memory?   → Trust it. Skip the file read.
Is this speculative?            → Kill the tool call.
Can calls run in parallel?      → Parallelize them.
Output > 20 lines you won't use → Route to subagent.
About to restate what user said → Delete it.
```

## RTK — Bash Output Compression

Token optimizer controls how the team thinks, reads, and responds. RTK handles what
comes back from bash commands.

[RTK](https://github.com/rtk-ai/rtk) is a separate tool that compresses bash command
output before it hits Claude's context window. Tools like `find`, `ls`, and `grep` can
return hundreds of lines Claude doesn't need — RTK intercepts that output and compresses
it, often cutting 50-70% of bash output tokens automatically.

RTK is not part of Three Man Team and we don't manage it. Install it separately if you
use Claude Code CLI heavily. The combination of RTK (bash layer) + token-optimizer
(behavior layer) is where the real savings compound.

Install: https://github.com/rtk-ai/rtk

## Grep Before Read

Never read an entire file to find one thing. Grep for the exact string or line number
first. If you need context around it, use offset and limit on the Read. This single
rule has the highest impact in active build sessions.

## Graph First — do NOT use the Explore agent for code

For ANY question about existing code — "where is X / who calls Z / what breaks if I
change this / trace this flow / find the definition / map this feature" — query the
**codebase-memory-mcp** graph. The index is built for this monorepo (72k+ nodes) and
answers in ~1s. Do **NOT** spawn the generic `Explore` subagent for these — an unscoped
Explore over this repo can run 15+ min because it walks `node_modules`/`dist`, and it
doesn't reliably reach for the graph. That fallback is the slowness the Owner flagged.

**Rule:**
- **Code questions → the `explore-with-codebase-memory` skill** (it queries the graph),
  or the MCP tools directly (`search_graph`, `query_graph`, `trace_path`, `search_code`,
  `get_code_snippet`, `index_status`). This is the default for all code exploration.
- **Never spawn the `Explore` agent for a code/symbol/callers/trace question.** Reserve
  the Explore agent ONLY for non-code file-finding (config files, assets, "which dir has
  the workflow yaml") — and even then scope it to a subdir, never the repo root.
- **When spawning ANY subagent (Bob/Richard/other) that must explore code**, tell it in
  the prompt: "use the codebase-memory-mcp graph (`search_graph`/`trace_path`), not a
  grep/read loop." Otherwise the subagent defaults to slow grep.
- MCP down? CLI fallback: `codebase-memory-mcp cli search_graph '{"project":"<name>","query":"..."}'`
  (project name via `list_projects`). Note: `timeout` is absent on macOS — background + `kill`.
- If the graph looks stale after big changes, re-index (`index_repository`) rather than
  falling back to Explore.

See [[codebase-memory-primary-nav]] in memory for the chosen-tool decision + project name.

## Role-Scoped Loading

Each role loads only what their job requires:
- Architect: checkpoint + BUILD-LOG + ARCHITECT-BRIEF
- Builder: ARCHITECT-BRIEF + relevant reference files only
- Reviewer: REVIEW-REQUEST + specific files Builder listed

The full project spec, schema, and flow docs stay on disk until explicitly needed.

## Checkpoint-First

SESSION-CHECKPOINT.md replaces reading BUILD-LOG and the full spec when it is current.
Architect writes it at the end of every session. It should cover: where we stopped,
what was decided, what is open, and the exact resume prompt.

## CLAUDE.md as Router

CLAUDE.md should never exceed ~50 lines. It is a routing file, not a knowledge base.
Every byte in CLAUDE.md costs tokens on every session. Keep it lean.
