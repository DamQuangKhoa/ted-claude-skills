---
name: flava-blueprint-skill
description: Authoritative coding conventions and implementation guide for **product-cloud-blueprint** (Cloud Blueprint) in the Flava Console monorepo. Covers enum/type placement, Model suffix naming, client `@/` vs BFF `src/` imports, API class patterns, table names, TanStack Query composables, BFF module layout, helpers, permissions, and project-scoped external links. Use this skill whenever work touches **product-cloud-blueprint**, **cloud-blueprint**, Blueprint deployment/run flows, GitHub SCM OAuth, drift detection, configuration versions, or paths under `apps/product-cloud-blueprint/` — even if the user only says "blueprint", "deployment overview", or "CLOUDQA blueprint". Load before adding features, fixing bugs, reviewing PRs, or creating files in Blueprint BFF or client.
---

# Flava Cloud Blueprint (product-cloud-blueprint) Skill

Single source of truth for coding agents working in `apps/product-cloud-blueprint/`. Read this before changing BFF or client code.

**Product path:** `apps/product-cloud-blueprint/` (`bff/` + `client/`)  
**Commitlint scope:** `cloud-blueprint` (not `blueprint`)  
**pnpm filters:** `product-cloud-blueprint-client`, `product-cloud-blueprint-bff`  
**Router / product id:** `PRODUCT_ID.CLOUD_BLUEPRINT` from `@linecorp/lycc-enums`

---

## Repository layout

```
apps/product-cloud-blueprint/
├── bff/src/
│   ├── main.ts                    # global prefix /api/cloud-blueprint/v1/:projectName
│   ├── modules/<domain>/          # controller, service, dto/, *.module.ts
│   ├── middlewares/               # token + projectName from URL
│   ├── decorators/                # @RequestContext(), @SkipTransform()
│   └── utils/                     # handleError, getProjectNameFromUrl
└── client/src/
    ├── apis/                      # one class + singleton per domain
    ├── composables/<domain>/      # TanStack Query hooks
    ├── components/                # feature UI + modals
    ├── enums/                     # domain enums, labels, router, queryKey
    ├── helpers/                   # API ↔ UI transforms (redefine*, form mappers)
    ├── pages/                     # route-level views
    ├── router/                    # deployment, codeGenerator routes
    ├── types/                     # *Model interfaces
    └── validators/                # vee-validate / async rules
```

Primary domains today: **deployment**, **run**, **scm** (GitHub), **configuration-version**, **project**, **validation**, **available** (Tofu versions).

---

## Coding conventions

Apply these whenever modifying Blueprint code.

### 1. Enums — `enums/` only

- Define enums in `client/src/enums/<domain>.ts` (e.g. `deployment.ts`, `status.ts`, `router.ts`, `queryKey.ts`).
- Do **not** put enums inside `types/` files.
- Pair enum values with label maps / option arrays in the same file.

```ts
// ✅ client/src/enums/deployment.ts
export enum DeploymentColumnKey {
  Name = 'name',
  LatestRunStatus = 'latestRunStatus',
}
export const DEPLOYMENT_COLUMN_LABEL = {
  [DeploymentColumnKey.Name]: 'Name',
  [DeploymentColumnKey.LatestRunStatus]: 'Latest run status',
};
```

Also keep here: `DeploymentActionKey` + `DEPLOYMENT_ACTION_LABEL`, router name constants (`BLUEPRINT_DEPLOYMENT_ROUTER_*`), and `QueryKey` entries.

### 2. Types — `types/` only, `Model` suffix

- Define interfaces in `client/src/types/<Domain>.ts` (PascalCase filename).
- Do **not** put types/interfaces in `enums/` files.
- Shared shapes → `types/common/`.
- Interface names **must** end with `Model` (API, form, list, redefined UI shapes).

```ts
// ✅ client/src/types/Deployment.ts
export interface DeploymentModel { ... }
export interface RedefinedDeploymentModel extends DeploymentModel { ... }
export interface DeploymentListResponseModel { items: DeploymentModel[]; total: number }
export interface CreateDeploymentRequestModel { ... }
export interface DeploymentFormModel { ... }

// ❌ WRONG — missing Model suffix
export interface Deployment { ... }
export interface DeploymentResponse { ... }
```

**Redefined models:** raw API types stay `*Model`; UI-enriched copies use `Redefined*Model` and are built in `helpers/` (e.g. `redefineDeployment` adds formatted dates, `latestRunStatus`).

Enums may be **imported into types** as types only (`import type { ConfigInputMode } from '@/enums/deployment'`).

### 3. Import aliases

| Layer | Alias | Example |
|-------|--------|---------|
| **Client** | `@/` → `src/` | `import { StatusEnum } from '@/enums/status'` |
| **BFF** | `src/` prefix | `import { handleError } from 'src/utils'` |

Client shell imports: `@flava-federation/shell/index` (`useCurrentProject`, `useRegion`, `useUserRoles`, `useErrorPage`).

### 4. API classes — class + singleton + region header

- One file per domain: `client/src/apis/<domain>.ts`.
- Export **class** and **singleton** (`export const deploymentApi = new DeploymentApi()`).
- Methods take `(projectName, region, ...)` — region order matches existing files (some methods interleave resource ids; follow the domain file).
- Set `'Flava-Region'` on every request via `getHttpClientBuilder().setHeaders({ 'Flava-Region': region })`.
- Base path from `API_PREFIX` in `@/enums/common` (`/api/cloud-blueprint/v1`).

```ts
// ✅ client/src/apis/deployment.ts
export class DeploymentApi {
  async getDeployements(projectName: string, region: string, params?: ApiQueryParams) {
    const client = getHttpClientBuilder().setHeaders({ 'Flava-Region': region });
    return client.build().get(`${API_PREFIX}/${projectName}/deployments`, ...);
  }
}
export const deploymentApi = new DeploymentApi();
```

### 5. Table names — `PRODUCT_ID.CLOUD_BLUEPRINT`

- Define in `client/src/enums/common.ts`.
- Format: `` `${PRODUCT_ID.CLOUD_BLUEPRINT}-<entity>:v1` ``

```ts
export const TABLE_NAME = {
  DEPLOYMENT: `${PRODUCT_ID.CLOUD_BLUEPRINT}-deployment:v1`,
  DEPLOYMENT_RESOURCE: `${PRODUCT_ID.CLOUD_BLUEPRINT}-deployment-resource:v1`,
  RUN_HISTORY: `${PRODUCT_ID.CLOUD_BLUEPRINT}-run-history:v1`,
};
```

Reference from domain enums: `export const DeploymentTableName = TABLE_NAME.DEPLOYMENT`.

---

## Client patterns

### Composables (TanStack Query)

- Location: `client/src/composables/<domain>/use*.ts`.
- Always use `useCurrentProject()` + `useRegion()`; pass `projectName.value` and `region.value` into API methods.
- Query keys: `[QueryKey.GetDeploymentDetail, projectName, region, ...]` — never hard-code strings.
- Register new keys in `client/src/enums/queryKey.ts`.
- Errors: `parseRequestError` + `useErrorPage().showErrorPage` for page-level failures; composables may return `null` on 404 when a parent guard handles redirect (see `useDeploymentDetail`).

Template for reads:

```ts
const { name: projectName } = useCurrentProject();
const { region } = useRegion();

useQuery({
  queryKey: [QueryKey.GetDeployments, projectName, region, params],
  queryFn: () => deploymentApi.getDeployements(projectName.value, region.value, params.value),
  enabled: computed(() => !!projectName.value),
});
```

Mutations: wrap `useMutation` in `useCreateDeployment`-style composables; invalidate related `QueryKey` entries on success.

### Helpers — API ↔ UI

- `helpers/<domain>.ts`: `redefine*` (list/detail display), `transform*ToFormModel`, `build*Request` (form → API payload).
- Keep formatting (dates, status labels) out of Vue SFCs when a helper already exists.

### Permissions

- Deployment actions: `useDeploymentPermission({ actionKey, userRoles, deploymentName, data })` with `DeploymentActionKey` from enums.
- Run actions: `useRunPermission` + `IAMRole` enums under `client/src/enums/IAMRole.ts`.
- Gate buttons with `PermissionButton` + `conditions` from permission composables.

### Modals

- Use `useModalManager` from `@linecorp/lycc-router` to open async modal components.
- In-modal errors: `useGlobalNotification` or local snackbar patterns already in deployment modals.
- On success: toast + `refetch*` / `router.push` as in `Overview.vue`.

### External / cross-product links

Flava routes are **project-scoped**. Never link to `/iam/...` without the project segment.

```ts
const { name: projectName } = useCurrentProject();
const href = `/${projectName.value}/iam/service-account/${serviceAccountName}`;
```

Match batch, app-runner, and mcp-hub patterns for IAM links.

### Forms (vee-validate)

- Form field paths: `DEPLOYMENT_FORM_PATHS` in `enums/deployment.ts`.
- Reusable items: `components/deployment/create/*FormItem.vue` owning their `useField`.
- Async name validation: `validators/deployment.ts` + `DebounceValidateInput`.

### Router

- Route names: `BLUEPRINT_*` constants in `enums/router.ts` (prefix = `PRODUCT_ID.CLOUD_BLUEPRINT`).
- Navigate with `{ name: BLUEPRINT_DEPLOYMENT_ROUTER_DETAIL_EDIT, params: { deploymentName } }` — shell injects `projectName`.

---

## BFF patterns

### Module structure

Each domain under `bff/src/modules/<domain>/`:

- `<domain>.controller.ts` — `@CommonData()` / `@RequestContext()` params
- `<domain>.service.ts` — upstream calls via `SharedService.getBlueprintEndpoint(context.projectName, context.region)`
- `dto/*.dto.ts` — request/response DTO classes (`*Dto` suffix on BFF; not `Model`)
- `<domain>.module.ts`

Global prefix: `/api/cloud-blueprint/v1/:projectName` (see `main.ts`).  
Exception: GitHub OAuth callback is excluded from `:projectName`; project context comes from `state` (`scm-oauth.controller.ts`).

### Error handling

- Use `handleError(e, logger, url)` from `src/utils` in services — do not duplicate catch logic.

### Mock data

- `mockData.ts` per module; gated by env flags (e.g. `USE_MOCK_DEPLOYMENTS`).

---

## API change → full stack order

When upstream or BFF contract changes, update layers in order:

1. **BFF DTO** — `bff/src/modules/<domain>/dto/*.dto.ts`
2. **BFF service/controller** — forward new fields, query params
3. **Client type** — `client/src/types/<Domain>.ts` (`*Model`)
4. **Client API** — `client/src/apis/<domain>.ts`
5. **Helper** — mappers in `client/src/helpers/<domain>.ts` if display/form shape changes
6. **Composable** — query/mutation hooks
7. **UI** — pages/components last

Run scoped checks:

```bash
pnpm --filter product-cloud-blueprint-bff run type:check
pnpm --filter product-cloud-blueprint-client run type:check
pnpm --filter product-cloud-blueprint-client run lint
```

---

## UI components

- Use **Flava UI** from `@linecorp/flava-ui` (`FlavaDescriptionList`, `FlavaTextLink`, `FlavaTab`, `FlavaButtonGroup`, etc.).
- Layout spacing: Tailwind / `lp_*` utilities and existing `tw-*` classes in blueprint components.
- Page shell: `layout/PageTemplate.vue`, detail shell: `DeploymentDetailTemplate.vue`.
- Loading: `ContentsDimmedLoader` for section-level fetch states.

---

## Checklists

### New deployment (or run) field

1. BFF DTO + service mapping
2. `DeploymentModel` / `RunModel` (or nested type) in `types/`
3. API method if new endpoint or payload
4. `redefine*` / form helper if UI displays formatted value
5. Enum/label if user-facing label or filter column
6. Composable + `QueryKey` if fetched separately
7. Component / form item

### New enum-driven action

1. Add `DeploymentActionKey` (or run equivalent) + label map in `enums/deployment.ts`
2. Wire permission rules in `useDeploymentPermission.ts`
3. Add UI entry (button / more actions menu)
4. Modal or navigation handler

### New list/table

1. `DeploymentColumnKey`-style enum + `*_COLUMN_LABEL` + table name from `TABLE_NAME`
2. `useTable` / filter keys aligned with enum keys
3. Search/filter keys in same enum file (`*_SEARCH_KEYS`, `*_FILTER_KEYS`)

---

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Path `apps/product-blueprint/` | Use `apps/product-cloud-blueprint/` |
| Commit scope `blueprint` | Use `cloud-blueprint` |
| `PRODUCT_ID.BLUEPRINT` | Use `PRODUCT_ID.CLOUD_BLUEPRINT` |
| Types in `enums/` or enums in `types/` | Split per rules above |
| Interface without `Model` suffix | Rename to `*Model` |
| Hard-coded query key string | Add to `QueryKey` enum |
| `/iam/...` link without project | Prefix with `/${projectName.value}/` |
| BFF import without `src/` | Use `src/modules/...` |

---

## Related skills

- **flava-jira-check** — ticket investigation on branch `CLOUDQA-*` / `LYCC-*`
- **flava-commit-skill** / **flava-pr-skill** — commit scope `cloud-blueprint`, PR labels
- **flava-lb-skill** — parallel product skill structure (reference only; different domain)
