---
name: flava-lb-skill
description: Authoritative implementation guide for **product-lb** (Load Balancer) in the Flava Console monorepo. Covers the dual instance model (Network LB vs Application LB), BFF module structure, revision system, client-side composables + store + form pipeline, and critical patterns for modals / validation. Use this skill whenever work touches **product-lb**, application ports, upstream clusters, revisions, rate limiting, replicas, drain, deploy, create/edit flows for Application LB or Network LB — even if the user only mentions "LB", "application load balancer", "revision", or a specific modal like "Replicas settings". Load this skill before adding new features, modifying BFF DTOs, adding fields to revision payloads, or changing modal behavior.
---

# Flava Load Balancer (product-lb) Skill

This skill is the single source of truth for coding-agents working inside `apps/product-lb`. Read it fully before making any changes.

---

## Coding principles

These principles apply to every file you touch in `apps/product-lb`. Violations must be fixed before merging.

### TypeScript everywhere

- **No `any`, no `js` files.** Every new file must be `.ts` or `.vue` with a `<script setup lang="ts">` block.
- Type all function parameters, return types, and reactive refs explicitly. Let inference work only for local variables where the type is obvious from the assignment.
- Use `interface` for object shapes, `type` for unions/aliases. Export types from `types/` — do not define ad-hoc inline shapes in composables or components.
- When extending an existing interface (e.g. adding a field to `RevisonApplicationPort`), update the canonical type in `types/` first, then fix downstream usages — never cast around a missing field with `as any`.
- BFF DTOs must have explicit class-validator decorators on every field. `@IsOptional()` does not remove type-safety; the field still needs its type decorator (`@IsString()`, `@IsInt()`, etc.).

### DRY — Don't Repeat Yourself

- If the same logic appears in more than one component/composable, extract it to `utils/` or a shared composable in `composables/common/`.
- All rate-limit logic lives in `utils/applicationRateLimitRevision.ts`. All port/cluster conversion logic lives in `utils/applicationLBUtils.ts`. **Do not reimplement** these in components.
- Query key strings live in `enums/queryKey.ts`. Never hard-code a query key string inline.
- Preset descriptions live in `APPLICATION_RATE_LIMIT_PRESET_HELP` (utils). Never duplicate the strings in the template.
- BFF error handling uses `handleError` from `src/lib/utils`. Never write a custom `catch` block that duplicates this.

### No hard-coded strings — use enums or constants

- **Never hard-code magic strings inline.** Every domain string (action keys, query keys, route names, protocol values, enum labels, polling intervals, etc.) must live in a named constant or enum.
- Enums for domain values: `ActionKey`, `VipType`, `ProtocolType`, `PathMathPolicyType`, `HAModeType`, `BalanceMethodType`, etc. — all in `enums/lb.ts`. Add new values there; do not inline `'http'`, `'roundrobin'`, `'prefix'` in components.
- Query keys: always use `QUERY_KEY.*` from `enums/queryKey.ts`. Never pass a raw string to `useQuery`/`invalidateQueries`.
- Numeric magic values: extract to a named constant with a descriptive name at the top of the file or in `constants/`. Example: `APPLICATION_RATE_LIMIT_MAX_ESTIMATE_RPS`, `APPLICATION_REPLICA_DEFAULT_VALUE`.
- URL/link strings: store in `enums/common.ts` (e.g. `DOCUMENT_APPLICATION_LINK`). Never inline a URL in a template.
- Error/snackbar title strings: define as a `const content = { title: '...' }` object at the top of the component — do not scatter literal strings across the template.
- When adding a new action, status, or protocol value: add it to the relevant enum **first**, then use the enum member everywhere — including in `ActionKeyLabel` or equivalent label maps.

### Arrow functions in `<script setup>`

- Prefer **`const fn = (...) => { ... }`** for helpers inside SFCs (e.g. `ChangeAppReplicaModal.vue`). Do **not** use `function fn()` declarations in component script.
- Utils under `utils/` may use `export function` when the file is not a Vue SFC.

### Readable variable names

- Boolean refs: prefix with `is`, `has`, `can`, `should` — e.g. `isRateLimitBlocked`, `isModalDataLoading`, `hasLoadedRevision`.
- Computed values derived from a ref: suffix with `Computed` only when disambiguation is needed — e.g. `instanceIdComputed`.
- Avoid single-letter variables outside `Array.map`/`Array.find` callbacks.
- Composable return values: destructure with the original name; only rename when there is a collision — e.g. `const { isPending: createRevisionLoading } = useMutation(...)`.
- Form refs for field values: `const { value: replica, errorMessage: replicaErrorMessage } = useField(...)` — always name the destructured aliases descriptively.

---

## Specific use cases

### API change → updating the full stack

When the upstream LB API changes a request/response shape, follow this order strictly — do not skip layers:

1. **BFF DTO** (`bff/src/modules/*/dtos/*.dto.ts`)
   - Add/remove/rename the field with the correct class-validator decorator.
   - If the field is a nested object, define its DTO class **above** the parent class in the same file (class declaration order matters — see BFF DTO rules).
   - Run `pnpm --filter product-lb-bff run type:check` to confirm.

2. **Client type** (`client/src/types/`)
   - Update the matching interface in `types/application/index.ts`, `types/request/applicationReq.ts`, or `types/response/revisionRes.ts`.
   - If it is part of the revision POST payload, also update `types/request/instanceReq.ts` (`CreateRevisionPayload`).

3. **Composable** — update existing or create new:
   - If the data is fetched: update the relevant `useXxx` composable in `composables/` (or create a new one following the `useQuery` pattern).
   - If the data is mutated: update or create a `useMutation` wrapper following `useRevisionAction.ts` as a template.
   - New composable naming: `use<Resource><Action>.ts` (e.g. `useApplicationDrainAction.ts`).
   - Register the new API function in `apis/index.ts` before wiring the composable.

4. **API function** (`apis/index.ts`)
   - Add a typed function using `getHttpClientBuilder()`. Set `Flava-Region` header when region is needed.
   - Add the corresponding `QUERY_KEY` in `enums/queryKey.ts` if it introduces a new cache entry.

5. **UI** — apply in the component last, after all lower layers are typed and tested.

### Building UI components

- **Use Flava UI components only.** Import from `@linecorp/flava-ui`. Do not create wrapper divs for layout that Flava already handles.
  - Inputs: `FlavaInput`, `FlavaSelect`, `FlavaCheckbox`, `FlavaRadio`
  - Labels: `FlavaFormLabel`, `FlavaFormRow`
  - Feedback: `FlavaModal`, `FlavaButton`, `FlavaTextLink`
  - Notifications: use `useLocalSnackbar` (in-modal) or `useGlobalNotification` (page-level toast)
- **Tailwind CSS for layout/spacing.** Use the project's Tailwind utility classes (e.g. `lp_mb12`, `lp_mt8`, `lp_flex`, `lp_gap_15`) for margins, flex, and gaps. Do not write inline `style` attributes for spacing — only use `style` for one-off overrides that Tailwind cannot express (e.g. `max-width: 220px`).
- Do not write `<style scoped>` rules for layout that Tailwind already covers.
- Follow existing component file structure: `<script setup lang="ts">` → `<template>` → `<style scoped lang="scss">` (only if needed).

### Validating UI errors (vee-validate)

Always match the pattern already used in the codebase — check other usages before implementing validation from scratch.

**Option A — standalone form field (reusable component)**

Use `useLazyValidation` + `useField` (from `vee-validate`):

```ts
import { useField } from 'vee-validate';
import { useLazyValidation } from '@/composables/common/useLazyValidation';

const { shouldValidate, handleBlur } = useLazyValidation({
  modelValue: myFieldRef,
  startWhen: (value) => value !== '',
});

const { value: myField, errorMessage } = useField<string>('fieldName', validationRules, {
  label: 'Field Label',
});
```

Wire to `FlavaInput`:

```vue
<FlavaInput
  v-model="myField"
  v-model:invalid="state.invalid"
  :validate="myValidateFn"
  :validationMessage="errorMessage"
  required
  @blur="handleBlur"
/>
```

**Option B — modal with `useField` + custom rules (Replicas settings)**

`ChangeAppReplicaModal.vue` uses vee-validate `useField` per input, dynamic rules via `computed`, and `isRateLimitBlocked` for submit:

```ts
const rateLimitRequestsPerSecondRules = computed(() =>
  rateLimitEnabled.value ? { applicationLbRateLimitRps: [presetModel.value] } : {},
);

const { value: rateLimitRequestsPerSecond, errorMessage: rateLimitRequestsPerSecondErrorMessage } =
  useField<string>('replica_modal_rate_limit_requests_ps', rateLimitRequestsPerSecondRules, {
    label: 'Requests per second (RPS)',
    validateOnBlur: true,
    validateOnModelUpdate: true,
  });

const isRateLimitBlocked = computed(() => {
  if (!rateLimitEnabled.value) return false;
  if (rateLimitRequestsPerSecondErrorMessage.value) return true;
  // … refill errors, NaN payload guards
  return false;
});
```

Guard submit: `if (isRateLimitBlocked.value) return;`

**Key rules:**
- Replicas settings: use `validateOnBlur` / `validateOnModelUpdate` on rate-limit `useField`s; gate the whole form behind `isModalDataLoading` until API seed completes.
- Never clamp an invalid value to a "safe" default silently — let vee-validate or `Number.NaN` payload guards block submit.
- Before writing a new validator, search `grep -r "useField\|useLazyValidation\|applicationLbRateLimit" apps/product-lb/client/src` for existing patterns.

### Adding a new modal or updating an existing modal

#### Creating a new modal

1. **File location**: `client/src/components/modal/application/MyActionModal.vue` (Application LB) or `components/modal/network/` (Network LB).

2. **Props interface**: define a typed `ItemModal` + `NetworkModalProps` (or equivalent) interface at the top of `<script setup lang="ts">`. Export it so the parent page can import the type.

   ```ts
   export interface ItemModal {
     id: string;
     // only fields this modal needs — do not pass the full instance object
   }
   export interface MyActionModalProps {
     selectedData: ItemModal[];
   }
   const props = defineProps<MyActionModalProps>();
   ```

3. **Composables to always include**:
   - `useModalManager` → `closeModal()`
   - `useLocalSnackbar` → `showLocalErrorSnackbar` for in-modal API errors
   - `useGlobalNotification` → `showSuccessToast` after success
   - `useAuth` → `projectName`
   - `useRegion` → `region`

4. **Action key**: add a new `ActionKey` value in `enums/lb.ts` and its label in `ActionKeyLabel`. Wire the modal open in the list/detail page using `useModalManager`.

5. **If the modal needs the latest revision** (any mutation that POSTs a new revision):
   - Fetch the revision list with `useQuery` (same pattern as `ChangeAppReplicaModal`) to derive `latestRevisionNumber`.
   - Fetch revision detail with `useRevisionsDetail(revisionIdComputed, instanceIdComputed)`.
   - Guard submission with a `revisionReady` computed and show `revisionDetailLoadingBanner` while loading.

6. **Template structure**:
   ```vue
   <FlavaModal visible close-button @close="closeModal" noClickOutsideClose>
     <template #title><h2 class="title">{{ content.title }}</h2></template>
     <template #content>
       <SnackbarManager :snackbars="snackbars" @close-snackbar="closeLocalSnackbar" />
       <!-- content here -->
     </template>
     <template #button>
       <FlavaButton appearance="outlined" size="large" @click="closeModal">Cancel</FlavaButton>
       <FlavaButton :color="BUTTON_COLOR.PRIMARY" size="large" @click="handleSubmit" :disabled="saveDisabled" :loading="submissionLoading">
         Save
       </FlavaButton>
     </template>
   </FlavaModal>
   ```

7. **Submit handler pattern**:
   ```ts
   const handleSubmit = () => {
     // 1. validate — show errors and return early if blocked
     if (isBlocked.value) { validationVisible.value = true; return; }
     // 2. no-op if nothing changed
     if (!isDirty.value) { closeModal(); return; }
     // 3. run mutation
     myMutation(payload, {
       onSuccess() { finalizeSuccess(); },
       onError(error) { showLocalErrorSnackbar(error as FlavaHttpError<any>); },
     });
   };

   const finalizeSuccess = () => {
     closeModal();
     showSuccessToast();
     // invalidate all affected query keys
     queryClient.invalidateQueries({ queryKey: [QUERY_KEY.Application.GetList, projectName.value] });
     queryClient.invalidateQueries({ queryKey: [QUERY_KEY.GET_REVISIONS] });
   };
   ```

8. **String literals**: define a `const content = { title: 'My Action' }` object — never scatter raw strings in the template.

9. **`saveDisabled` computed**: always combine loading states + validation blocked state:
   ```ts
   const saveDisabled = computed(
     () => mutationLoading.value || isBlocked.value,
   );
   ```

#### Updating an existing modal

- **Never add** unrelated concerns to an existing modal. If the new feature is independent, create a new modal.
- When adding a new field/section:
  1. Add the reactive state (`ref`, `computed`) in `<script setup>` — grouped near related state.
  2. Add per-field validation computed (see validation pattern above).
  3. Wire `:invalid` + `:validationMessage` on the `FlavaInput`.
  4. Include the new field in the dirty-check logic so the submit guard correctly detects changes.
  5. Include the new field in the success invalidation if it affects cached data.
- When adding a new mutation to an existing modal (e.g. adding rate-limit to a replica modal):
  - Keep it **independent** from the existing mutation — separate dirty checks, separate `isPending` refs.
  - Chain mutations in `onSuccess` callbacks if ordering matters (revision first, then replica patch). Never run them in parallel with `Promise.all`.
  - Update `saveDisabled` to include the new loading state.
  - Update `submissionLoading` to `OR` all active loading states.

---

## App roots

| Layer | Path |
|---|---|
| Client (Vue 3) | `apps/product-lb/client/src/` |
| BFF (NestJS) | `apps/product-lb/bff/src/` |

---

## Mental model — two instance types

Product-lb manages **two distinct LB flavors** that share some infrastructure but differ substantially:

| | **Network LB** | **Application LB** |
|---|---|---|
| Pages | `pages/network/` | `pages/application/` |
| BFF modules | `modules/instance/`, `modules/network/` | `modules/application/` |
| Revision ports key | `network_ports`, `network_inline_ports` | `application_ports`, `upstream_clusters` |
| Replica control | N/A | `l7_replicas` via `PATCH /applications/:id` |
| Create flow | Multi-step wizard under `pages/network/create/` | Multi-step wizard under `pages/application/Create.vue` + `components/application/form/ApplicationStep0*.vue` |
| Edit flow | `pages/network/edit/` | `pages/application/Edit.vue` |

**Do not mix patterns from Network LB into Application LB code and vice versa.**

---

## Architecture — data flow

```
Client page / modal
  │
  ├─ composable (useXxx)          ← business logic, mutation wiring
  │     └─ useQuery / useMutation via @tanstack/vue-query
  │           └─ api function in apis/index.ts
  │                 └─ HTTP → BFF /api/lb/v1/...
  │
  ├─ Pinia store (create flows)   ← step-by-step form state
  │     store/application/form/{general,config,cluster,routing}
  │
  └─ vee-validate (field validation)
        └─ useLazyValidation composable for lazy error display
```

### BFF module flow

```
NestJS Controller (*.controller.ts)
  └─ validates request body with class-validator DTO
        └─ Service (*.service.ts)
              └─ proxies to upstream LB API via HttpService
```

---

## BFF — module structure

```
bff/src/modules/
  application/          ← Application LB CRUD
    application.controller.ts    @Controller('applications')
    application.service.ts
    dtos/
      create-app-instance.dto.ts   ← CreateAppInstanceDTO, ApplicationPort, ApplicationRateLimitDto, UpstreamCluster, ...
      update-app-instance.dto.ts
      get-applications-query.dto.ts
  revision/             ← Revision list + detail + create (all instance types)
    revision.controller.ts    @Controller('instances/:instanceId/revisions')
    revision.service.ts
    dtos/
      create-revision.dto.ts    ← imports ApplicationPort, UpstreamCluster from application dtos
  instance/             ← Network LB (shared)
  network/              ← Network LB specific
  shared/               ← shared services (AppService for endpoint resolution)
```

### BFF DTO rules

- **Class declaration order matters.** A class used in a `@Type(() => SomeClass)` decorator must be declared **before** the class that references it in the same file. Violating this causes a `ReferenceError: Cannot access 'X' before initialization` at runtime.
  - Example: `ApplicationRateLimitDto` must come before `ApplicationPort` in `create-app-instance.dto.ts`.
- All DTOs use `class-validator` decorators (`@IsInt`, `@IsString`, `@IsOptional`, etc.) and `class-transformer` `@Type()`.
- Optional fields on revision payload use `@IsOptional()`. The BFF whitelist strips unsupported keys before forwarding to the upstream API.
- `ApplicationRateLimitDto` has `@Min(1)` on both fields — the upstream API treats `0` as "not configured".

### Adding a new field to Application Port (BFF)

1. Add the field + decorator to `ApplicationPort` in `create-app-instance.dto.ts`.
2. If the field is a nested object, define its DTO class **above** `ApplicationPort` in the same file.
3. `CreateRevisionDTO` in `revision/dtos/create-revision.dto.ts` re-uses `ApplicationPort` via import — no changes needed there unless you add a new top-level revision field.
4. Run `pnpm --filter product-lb-bff run lint` and `pnpm --filter product-lb-bff run type:check`.

---

## Client — directory guide

```
client/src/
  apis/index.ts          ← all HTTP calls (single file, grouped by resource)
  enums/
    lb.ts                ← ActionKey, VipType, ProtocolType, PathMathPolicyType, ...
    queryKey.ts          ← QUERY_KEY constants for TanStack Query
  types/
    application/index.ts ← ApplicationConfigPortRule, RevisonApplicationPort, RevisionCluster, ...
    request/
      applicationReq.ts  ← CreateApplicationLBPayload, ApplicationPort (create-form shape)
      instanceReq.ts     ← CreateRevisionPayload (shared revision POST body)
    response/
      revisionRes.ts     ← RevisionDetailResponse, ApplicationLBItem, ...
      applicationRes.ts
  composables/
    common/
      useAuth.ts         ← projectName, token
      useLazyValidation.ts ← lazy validation pattern (see Validation section)
      useLocalSnackbar.ts
      useGlobalNotification.ts
      useModalManager.ts
    application/
      useApplicationCreate.ts  ← step orchestration for create wizard
      api/
        useApplicationInstanceAction.ts  ← updateAppReplicaMutation, ...
    revision/
      useRevisionAction.ts     ← createRevisionMutation
      useRevisionsDetail.ts    ← useQuery wrapper for revision detail
      useRevisions.ts
  store/application/form/
    general.ts   ← step 1: name, replica, network, vpc
    config.ts    ← step 2: ports (protocol, timeout, ACL, certs)
    cluster.ts   ← step 3: upstream clusters / backends
    routing.ts   ← step 4: virtual hosts + http paths
  utils/
    applicationLBUtils.ts          ← convertApplicationConfigPortRule, convertApplicationUpstreamCluster
    applicationRateLimitRevision.ts ← rate-limit form seed, merge, digest, preset helpers
    networkLBUtils.ts
  components/
    application/
      form/                      ← ApplicationStep01-05.vue + sub-components
      detail/                    ← detail tab components
      common/                    ← InputNumberWithButton, etc.
    modal/application/
      ChangeAppReplicaModal.vue  ← Replicas settings (replica count + rate limit)
      DrainAppTargetServerModal.vue
      DeployAppRevisionModal.vue
      DeleteAppLBModal.vue
      StartAppModal.vue / StopAppModal.vue
      SettingAppVipNetwork.vue
    form/instance/form/          ← reusable form primitives (PortNumber, DestinationPort, ...)
  pages/
    application/
      List.vue     ← Application LB list
      Detail.vue   ← tabs: Overview, Revision, Monitoring
      Create.vue   ← multi-step create wizard
      Edit.vue
    network/
      List.vue / detail/ / create/ / edit/
```

---

## Revision system (Application LB)

A **revision** is an immutable snapshot of the full LB configuration. Changing ports, upstream clusters, or rate limits requires creating a new revision (POST), not patching the existing one.

### Revision lifecycle

```
GET /instances/:id/revisions         → list (revision_number, created_at, created_by)
GET /instances/:id/revisions/:rev    → detail (full application_ports, upstream_clusters, ...)
POST /instances/:id/revisions        → create new revision (triggers redeploy if isDeployAfter=true)
```

### Client pattern for revision-based mutations

1. Fetch the **latest revision** via `useRevisionsDetail` (composable).
2. Clone `revisionDetail.application_ports`, apply your changes.
3. Call `buildApplicationRevisionCreatePayload(revisionDetail, mergedPorts)` from `applicationRateLimitRevision.ts` to produce the full POST body.
4. Submit via `createRevisionMutation` from `useRevisionAction`.
5. On success, invalidate `QUERY_KEY.GET_REVISIONS`, `QUERY_KEY.GET_REVISION_DETAIL`, `QUERY_KEY.Application.GetList`, `QUERY_KEY.Application.GetDetail`.

### Getting the latest revision number

Always compute it from the list, not from instance props, because props may lag after a revision is created:

```ts
const latestRevisionNumberFromList = computed(() => {
  const list = revisionsListResponse.value?.data?.revisions;
  if (!Array.isArray(list) || list.length === 0) return 0;
  return Math.max(0, ...list.map((r) => Number(r.revision_number) || 0));
});
```

---

## Rate limiting (Application LB)

All rate-limit logic lives in `utils/applicationRateLimitRevision.ts`. **Do not duplicate this logic in components.**

### Key concepts

| Concept | Detail |
|---|---|
| Token bucket | `tokens_per_fill` (RPS bucket size) + `fill_interval_msec` (refill period) |
| "Enabled" | Both fields must be `>= 1` in the revision. `0`/missing = disabled. |
| Presets | `strict` (10ms), `balanced` (100ms), `flexible` (500ms), `loose` (1000ms), `custom` |
| Preset RPS ranges | `APPLICATION_RATE_LIMIT_PRESET_RPS_RANGE` — Strict 1–10, Balanced 5–50, Flexible 20–200, Loose 50–500, Custom 1–1000 |
| Preset RPS defaults | `APPLICATION_RATE_LIMIT_PRESET_RPS_DEFAULT` — Strict 5, Balanced 25, Flexible 100, Loose 250, Custom 1 |
| Custom refill (ms) | `APPLICATION_RATE_LIMIT_CUSTOM_FILL_MS_*` — min 1, max 2000, default 1 |
| Per-replica estimate | `estimateApplicationRateLimitSustainedRps(tokensPerFill, fillIntervalMsec)` → `RPS × (1000 ÷ fill ms)` |
| Total estimate | `estimateApplicationRateLimitTotalSustainedRps(replicaCount, tokensPerFill, fillIntervalMsec)` → replicas × per-replica |
| Form seed | `getApplicationRateLimitFormSeed(ports)` — returns `{ enabled, tokensPerFill, fillIntervalMsec, preset }` |
| Merge | `mergeRevisionApplicationPortsWithRateLimit(ports, { enabled, tokensPerFill, fillIntervalMsec })` — applies to all ports |
| Dirty check | `rateLimitSubsetDigest(ports)` — JSON digest of port_number + rate_limit |

### Preset descriptions (UI copy — keep in sync)

| Preset | First sentence | Second sentence |
|---|---|---|
| Strict | Enforces the configured RPS strictly with millisecond-level control. | Recommended for resource-sensitive workloads such as real-time database transactions. |
| Balanced | Maintains stable system load while tolerating minor network jitter. | Recommended for typical service-to-service communication. |
| Flexible | Allows limited temporary bursts to improve responsiveness. | Recommended for services with variable or event-driven traffic. |
| Loose | Controls only the average throughput per second while allowing larger bursts. | Suitable for batch jobs and asynchronous processing. |
| Custom | Allows fine-grained traffic tuning by configuring the token refill behavior. | Recommended for specialized traffic shaping or strict infrastructure limits. |

Descriptions stored in `APPLICATION_RATE_LIMIT_PRESET_HELP` (utils) with `\n` separator. Template renders with `style="white-space: pre-line"`.

### Switching presets

When the user changes preset (not while seeding from API), reset RPS and refill to **preset defaults** from `APPLICATION_RATE_LIMIT_PRESET_RPS_DEFAULT` and `APPLICATION_RATE_LIMIT_PRESET_FILL_MS`. Guard with `isApplyingRateLimitSeed` so revision load does not trigger preset defaults over API values:

```ts
watch(presetModel, (preset) => {
  if (isApplyingRateLimitSeed.value) return;
  setRateLimitRequestsPerSecondValue(
    String(APPLICATION_RATE_LIMIT_PRESET_RPS_DEFAULT[preset]),
    false,
  );
  if (preset !== 'custom') {
    setRateLimitTokenRefillPeriodMsValue(
      String(APPLICATION_RATE_LIMIT_PRESET_FILL_MS[preset]),
      false,
    );
  } else {
    setRateLimitTokenRefillPeriodMsValue(
      String(APPLICATION_RATE_LIMIT_CUSTOM_FILL_MS_DEFAULT),
      false,
    );
  }
});
```

### Estimated total sustained rate (Replicas settings UI)

Display only when rate limiting is enabled and inputs are valid. Formula (match product spec):

**Replicas (A) × RPS/replica (B) × (1000 ÷ Token refill period (C) ms) = Total RPS**

Example: `3 × 7 × (1000 ÷ 10) = 2,100 RPS`. Use `estimateApplicationRateLimitTotalSustainedRps` + `toLocaleString()` for the result line.

### Replicas settings validation (vee-validate)

Rules live in `validator/application.ts`; messages in `constants/error.ts` (`ErrorMessages.rateLimitRps`, `rateLimitRefillMs`, `replica`).

| Field | Rule name | Notes |
|---|---|---|
| Replica | `replica` | Required; Dev fixed 2; Stage/Prod range via `maxReplica` (see modal) |
| RPS | `applicationLbRateLimitRps` | Param: preset key; range per `APPLICATION_RATE_LIMIT_PRESET_RPS_RANGE` |
| Token refill (ms) | `applicationLbRateLimitRefillMs` | Custom preset only; 1–2000 |

Wire in modal with `useField` + dynamic `computed()` rules (empty rules when rate limit disabled).

---

## Validation pattern (client)

The project uses `vee-validate` with a **lazy validation** approach — errors show only after the user has interacted with a field (blur), not immediately on mount.

### Standard pattern (reusable form fields)

Use `useLazyValidation` composable:

```ts
const { shouldValidate, handleBlur } = useLazyValidation({
  modelValue: myFieldRef,
  startWhen: (value) => value !== '',
});
```

Wire to `FlavaInput`:

```vue
<FlavaInput
  v-model="myField"
  :invalid="state.invalid"
  :validate="myValidateFn"
  :validationMessage="validationMessage"
  @blur="handleBlur"
/>
```

**Do not clamp invalid values to a valid default silently** — use vee-validate errors and/or `Number.NaN` in payload computeds so submit stays blocked.

---

## Modal conventions

All Application LB action modals live under `components/modal/application/`. Patterns:

- Use `useModalManager` for open/close.
- Use `useLocalSnackbar` for in-modal error display (not global toast).
- Use `useGlobalNotification` (`showSuccessToast`) for post-submit success.
- On success: call `closeModal()`, `showSuccessToast()`, then invalidate relevant TanStack Query keys.
- Use `revisionReady` guard before submitting any revision-dependent action (prevents submitting before revision data has loaded).

### ChangeAppReplicaModal (Replicas settings)

This modal handles two independent mutations that may run together:

| Mutation | Condition | API |
|---|---|---|
| `updateAppReplicaMutation` | `replicaDirty` | `PATCH /applications/:id` |
| `createRevisionMutation` | `rateLimitDirty` | `POST /instances/:id/revisions` |

If both are dirty, the revision is created first, then the replica patch runs in the `onSuccess` callback. Never run them in parallel.

#### Loading gate (avoid wrong first paint)

**Do not** render the form or seed rate-limit fields until API data is ready. Wrong pattern: `watch(..., { immediate: true })` that calls `getApplicationRateLimitFormSeed(undefined)` when `revisionId` is still empty — user sees defaults, then a flash when revision loads.

**Do:**

1. `didInitRateLimitForm` ref — `false` until one-shot init completes.
2. `isModalDataLoading` = `!!instanceId && !didInitRateLimitForm`.
3. Template: `FlavaLoading` when loading; `v-else` wraps replica + rate-limit UI.
4. `saveDisabled` includes `isModalDataLoading`.
5. Init watch waits for **`revisionsListFetched`**, then **`revisionDetailFetched`** when `revisionIdComputed` is non-empty, then `initializeModalFormFromApi()`:
   - `applyRateLimitSeed(ports, seed)` with `isApplyingRateLimitSeed` guard on preset watch
   - `setValue(l7_replicas)` from `props.selectedData[0]` (same tick as rate limit)
   - `didInitRateLimitForm = true`
6. On instance/revision id change, `resetInitialization()` sets `didInitRateLimitForm = false` (loading shows again).

```ts
const applyRateLimitSeed = (ports, seed) => {
  isApplyingRateLimitSeed.value = true;
  // set rateLimitEnabled, presetModel, RPS, refill, initialRateLimitPortsDigest
  isApplyingRateLimitSeed.value = false;
};

const initializeModalFormFromApi = () => {
  if (didInitRateLimitForm.value) return;
  const revId = revisionIdComputed.value;
  const ports = revisionDetail.value?.application_ports ?? [];
  const seed = getApplicationRateLimitFormSeed(revId && ports.length ? ports : undefined);
  applyRateLimitSeed(ports, seed);
  if (props.selectedData.length > 0) {
    setValue(props.selectedData[0].l7_replicas, false);
    initialL7Replicas.value = props.selectedData[0].l7_replicas;
  }
  didInitRateLimitForm.value = true;
};

watch(
  () => [revisionsListFetched.value, revisionDetailFetched.value, revisionIdComputed.value] as const,
  () => {
    if (didInitRateLimitForm.value || !revisionsListFetched.value) return;
    const revId = revisionIdComputed.value;
    if (revId && !revisionDetailFetched.value) return;
    initializeModalFormFromApi();
  },
  { immediate: true },
);
```

Place `initializeModalFormFromApi` **after** `useField('replica')` so `setValue` exists when the watch runs.

---

## Adding a new Application LB feature — checklist

### New field on existing Application Port / Revision

1. **Type** — add to `RevisonApplicationPort` in `client/src/types/application/index.ts`.
2. **Request type** — add to `ApplicationPort` in `client/src/types/request/applicationReq.ts` (create flow) and/or `CreateRevisionPayload` in `instanceReq.ts` (revision flow).
3. **BFF DTO** — add to `ApplicationPort` class in `bff/src/modules/application/dtos/create-app-instance.dto.ts`. If it's a nested object, define its DTO class **above** `ApplicationPort`.
4. **UI util** — if the field needs form ↔ payload conversion, add a helper to `applicationLBUtils.ts` (create flow) or `applicationRateLimitRevision.ts` (revision flow).
5. **Component** — update the relevant form step (`ApplicationStep02.vue` for port config) or modal (`ChangeAppReplicaModal.vue`).
6. **Tests** — if you added a utility function, add a unit test in the adjacent `.test.ts` file.

### New Application LB modal action

1. Create `components/modal/application/MyActionModal.vue`.
2. Register the `ActionKey` in `enums/lb.ts`.
3. Wire in the list/detail page using `useModalManager`.
4. Follow the modal conventions above.

### New BFF endpoint

1. Add the route handler in the appropriate `*.controller.ts`.
2. Create or update the DTO in `dtos/`.
3. Add the service method in `*.service.ts` (proxy to upstream, use `handleError` from `src/lib/utils`).
4. Add the API function in `client/src/apis/index.ts`.
5. Add the `QUERY_KEY` constant in `client/src/enums/queryKey.ts`.

---

## Do NOT do

- **Do not** add business logic in `*.service.ts` BFF files — they are pure proxies; transform only when necessary.
- **Do not** define a DTO class after the class that references it via `@Type()` in the same file.
- **Do not** run `updateAppReplicaMutation` and `createRevisionMutation` in parallel — always chain them.
- **Do not** read `revision_number` from instance props for revision fetching — always derive from the revision list to avoid stale data.
- **Do not** initialize Replicas settings (or seed rate-limit defaults) before `revisionsListFetched` / required `revisionDetailFetched` — use full-modal loading until `didInitRateLimitForm`.
- **Do not** use `function` declarations for helpers inside Vue SFCs — use `const fn = () => {}`.
- **Do not** clamp invalid numeric field values to `1` silently — store `0` so validation can fire properly.
- **Do not** add Network LB patterns (e.g. `network_ports`, HA mode, hash policy) to Application LB code paths.
- **Do not** mix Application LB Pinia stores (`store/application/form/*`) with Network LB state.

---

## Commands (scope to product-lb)

```bash
# Find the package name first
pnpm -r list --depth -1 | grep product-lb

# Lint
pnpm --filter product-lb-client run lint
pnpm --filter product-lb-bff run lint

# Type check (build shared packages first if needed)
pnpm --filter flava-shell-client run build
pnpm --filter product-lb-client run type:check
pnpm --filter product-lb-bff run type:check

# Unit tests
pnpm --filter product-lb-client run test:ci

# Dev server
pnpm --filter product-lb-client run serve --force
```
