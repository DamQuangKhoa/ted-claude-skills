---
name: flava-flag-feature
description: Add a runtime feature flag for a Jira ticket in the Flava Console monorepo so a feature can be turned on/off per environment. Use whenever the user wants to "add a feature flag", "gate this feature", "put X behind a flag", "feature toggle", "flag this ticket", "make this env-configurable", or provides a Jira ticket (LYCC-1234, CLOUDQA-12345) whose feature should be flag-controlled. This skill knows the Flava flag mechanism is NOT a plain .env read — a flag only works when registered in ALL FOUR places (`.env`, `vite.config.ts` `inject.data`, `index.html` `window.flava`, and an `envUtils` const) and then consumed via `getProperty`. Setting only `.env` silently does nothing (getProperty returns undefined). Prefer this skill over ad-hoc edits so the flag actually toggles and follows the existing per-product pattern.
---

# Flava Feature Flag

Add a runtime feature flag for a ticket's feature. In Flava Console, flags are **runtime-injected properties**, not build-time `.env` reads. `getProperty(key)` (from `@flava-federation/shell/index`) reads `window.flava`, which is populated from the HTML template, which is fed by Vite `inject.data`, which reads `process.env`. Miss any link and the flag silently returns `undefined` — the #1 mistake here (someone edits only `.env`, restarts, and the feature still shows).

Why runtime not build-time: the same built bundle ships to dev/stage/prod, and each environment's container substitutes its own values (`$VAR` placeholders via `envsubst`). So a flag must round-trip through the property system, not `import.meta.env`.

## The flag chain (must wire ALL of it)

```
.env  →  vite.config.ts inject.data  →  index.html window.flava  →  getProperty(key)  →  envUtils const  →  component gate
```

Every product under `apps/product-*/client` uses this identical pattern. Locate each file per product before editing (paths below).

## Workflow

1. **Fetch the ticket** — understand the feature (see §1).
2. **Pick the product + flag name** — which `apps/product-*` and a `ENABLE_...` key (§2).
3. **Wire the flag in all four places** (§3) — `.env`, `vite.config.ts`, `index.html`, `envUtils`.
4. **Gate the UI** — guard the feature's component(s)/tab/route with the const (§4).
5. **Verify** — type check, confirm the const reads the property; remind the user to restart the dev server (§5).
6. **Commit** — `feat(<scope>): TICKET: ...` via flava-commit conventions (§6).

Present the plan (flag name + files + gate points) and get a quick OK before editing if the gating scope is non-obvious. Wiring the four plumbing files is safe to just do.

## 1. Fetch the ticket

Use Jira MCP `jira_get_issue(issue_key=..., fields="*all", comment_limit=20)`. Extract: what feature ships, which product/component, and whether it should default **on** or **off**. If the ticket doesn't say, ask the user (unreleased features usually default off).

## 2. Choose product + flag name

- **Product**: from the ticket component/summary, or the code the feature lives in → `apps/product-<name>/client`.
- **Flag key**: uppercase `ENABLE_<AREA>_<FEATURE>`, matching neighbors. Look at the product's existing keys in `envUtils` for the naming style (e.g. LB uses `ENABLE_ALB_YJ_NETWORK_FEATURES`, `ENABLE_APPLICATION_LB`).
- **Default semantics** — pick the boolean expression deliberately, because unset/unsubstituted values matter:
  - Default **off**: `getProperty('KEY') === 'true'` (undefined → off). Use for unreleased work.
  - Default **on**: `getProperty('KEY') !== 'false'` (undefined/`$KEY` placeholder → on). Use when shipping-on but wanting a kill switch.

## 3. Wire the flag (four files)

Find the four files for the chosen product (paths shown for `product-lb`; other products mirror them):

**a. `apps/product-<name>/client/.env`** — add the key with the intended local value:
```
ENABLE_ALB_RESPONSE_TRANSFORMER=true
```

**b. `apps/product-<name>/client/vite.config.ts`** — add to `createHtmlPlugin`'s `inject.data`, copying the exact ternary shape of the neighbors (the `$VAR` branch is for production static builds):
```ts
ENABLE_ALB_RESPONSE_TRANSFORMER: isBuildToStaticFile
  ? '$ENABLE_ALB_RESPONSE_TRANSFORMER'
  : process.env.ENABLE_ALB_RESPONSE_TRANSFORMER,
```

**c. `apps/product-<name>/client/index.html`** — add to the `window.flava = { ... }` block:
```html
ENABLE_ALB_RESPONSE_TRANSFORMER: '<%= ENABLE_ALB_RESPONSE_TRANSFORMER %>',
```

**d. `apps/product-<name>/client/src/utils/envUtils.{js,ts}`** — export the typed const next to the other flags:
```js
// TICKET-ID: <feature>. Defaults on unless explicitly disabled per environment.
export const IS_ENABLE_ALB_RESPONSE_TRANSFORMER =
  getProperty('ENABLE_ALB_RESPONSE_TRANSFORMER') !== 'false';
```

**Sanity check:** the key string must be byte-identical across all four files. A typo here is invisible — `getProperty` just returns `undefined` and the feature won't toggle.

## 4. Gate the UI

**First, scope the gate to the ticket's actual delta — not the whole feature area.** A ticket like "Add a custom response body to the Response Transformer" adds a *part* of an existing feature; the Response Transformer tab, header transformer, and tab layout already existed. Gating the whole tab would hide pre-existing, already-shipped functionality when the flag is off. Before gating, check what existed *before* the ticket (read the ticket's "background"/"plan", `git log`/`git blame` the surrounding code, or diff against the ticket's own PR) and wrap **only the new pieces**. When the flag is off, the feature should look exactly as it did before this ticket — no more, no less.

Import the const and guard wherever the *new* part surfaces — usually more than one place. Trace it end to end so you don't leave a half-gated feature (form shows it, overview doesn't, or vice versa):

- **Tabs / list items**: filter the entry out of the array when off (and guard its panel with `v-if`). If the tab set is index-mapped (e.g. `FlavaTab` v-model by position), drop trailing entries so earlier indices stay stable — or otherwise keep index alignment intact.
- **Sections / components**: `v-if="IS_ENABLE_..."` on the wrapping element or combined with the existing condition (`v-if="IS_ENABLE_... && existingCond"`).
- **Routes**: guard route registration / navigation entries.
- **Overview + edit + create**: the same feature often renders in a detail/overview view AND a form. Gate all of them.

In `<script setup>`, a top-level `import { IS_ENABLE_... }` is auto-exposed to the template — no need to re-declare.

Do NOT gate the read-back/serialization layer unless the ticket wants stored data hidden too — usually you gate rendering/entry points, not data mapping.

## 5. Verify

- Type check the product: `pnpm --filter <pkg> run type:check` (discover pkg via that package's `package.json` name). Compare error count to baseline — the repo may already have unrelated type errors; your job is **zero new** ones, not zero total.
- Confirm the key matches in all four files (grep the key across the product dir — expect 4 hits + the gate usages).
- **Tell the user to restart the dev server** — `.env` and `index.html` are read at startup, so a running `serve` won't pick up the flag until restarted. This is the second most common "why isn't it working" after missing a wiring file.

## 6. Commit

Use flava-commit conventions: `feat(<scope>): TICKET-ID: Sentence case description`. Stage only the four wiring files + the gated component(s). Don't commit AI/editor files. If asked, follow with the PR via flava-pr-skill.

## Common pitfalls (why the flag "does nothing")

- **Only edited `.env`** → key absent from `inject.data`/`window.flava` → `getProperty` returns `undefined`. Wire all four.
- **Default-on expression + unset key**: `!== 'false'` with an undefined value is `true` → feature stays on even when you "turned it off". Register the key (so the value is really `'false'`) or use `=== 'true'` for default-off.
- **Dev server not restarted** after editing `.env`/`index.html`.
- **Key typo** across the four files → silent `undefined`.
- **Half-gated feature** — gated the form but not the overview (or route), so it half-appears.
- **Over-gated (wrong scope)** — gated the whole feature area when the ticket only added a part, so flag-off hides pre-existing functionality too. Gate the ticket's delta; confirm flag-off matches the pre-ticket state.
