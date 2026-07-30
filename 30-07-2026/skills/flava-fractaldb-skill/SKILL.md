---
name: flava-fractaldb-skill
description: Authoritative coding conventions and implementation guide for **product-dbs-for-fractaldb** (DBS for FractalDB) in the Flava Console monorepo. Covers enum/type placement, Model suffix naming, client `@/` vs BFF `src/` imports, API class patterns, table names, TanStack Query composables, BFF module layout, namespace/database/user/backup domains, VPC/network integration, lifetime approval, and project-scoped external links. Use this skill whenever work touches **product-dbs-for-fractaldb**, **dbs-for-fractaldb**, FractalDB namespace/keyspace/database flows, service users, backup/restore, quota, Query Runner links, or paths under `apps/product-dbs-for-fractaldb/` — even if the user only says "fractaldb", "FractalDB namespace", or "DBS fractal". Load before adding features, fixing bugs, reviewing PRs, or creating files in FractalDB BFF or client.
---

# Flava DBS for FractalDB (product-dbs-for-fractaldb) Skill

Single source of truth for coding agents working in `apps/product-dbs-for-fractaldb/`. Read this before changing BFF or client code.

**Product path:** `apps/product-dbs-for-fractaldb/` (`bff/` + `client/`)  
**Commitlint scope:** `dbs-for-fractaldb` (not `fractaldb` alone)  
**pnpm filters:** `product-dbs-for-fractaldb-client`, `product-dbs-for-fractaldb-bff`  
**Router prefix:** `FRACTALDB_ROUTER_PREFIX` in `client/src/enums/router.ts` (currently `'dbs-for-fractaldb'`)  
**Product id:** `FRACTALDB_PRODUCT_ID` in `client/src/enums/common.ts` — migrate to `PRODUCT_ID.DBS_FOR_FRACTALDB` from `@linecorp/lycc-enums` when available  
**Auth provider domain (BFF):** `flava-fractaldb` (`normal-token.middleware.ts`)  
**Upstream endpoint key (BFF):** `DBS_FOR_FRACTALDB` via `SharedService.getDbsForFractaldbEndpoint()`

---

## Repository layout

```
apps/product-dbs-for-fractaldb/
├── bff/src/
│   ├── main.ts                         # global prefix /api/dbs-for-fractaldb/v1/:projectName
│   ├── app.module.ts                   # middleware routing (normal/openstack/iam/monitoring)
│   ├── modules/<domain>/               # controller, service, dto/, *.module.ts
│   ├── modules/shared/                 # SharedService + shared DTOs (page, qos, storage, network)
│   ├── middlewares/                    # token exchange per upstream (normal, iam, monitoring, …)
│   ├── decorators/                     # @RequestContext()
│   ├── mocks/                          # namespace, database, user, backup, quota mocks
│   └── utils/                          # handleError, getProjectNameFromUrl
└── client/src/
    ├── apis/                           # one class + singleton per domain (some stubs — see below)
    ├── composables/<domain>/           # TanStack Query hooks + common/*
    ├── components/common/              # shared table, form, PermissionButton, Status
    ├── enums/                          # domain enums, labels, router, queryKey, status
    ├── helpers/                        # API ↔ UI transforms (network, future redefine*)
    ├── layout/                         # PageTemplate, EtcTemplate
    ├── router/                         # feature routes (children mostly TODO)
    ├── types/
    │   ├── fractaldb/                  # FractalDB-specific *Model interfaces
    │   └── common/                     # cross-cutting *Model (Vpc, Network, Response, …)
    └── validators/                     # vee-validate / async rules
```

**Primary domains:** **namespace** (top-level resource), **database** (keyspace / database under namespace), **user** (service users), **backup** / **restore**, **quota**, **available**, **validation**, **approval** (unlimited lifetime), **iam**, **vpc**, **network**, **monitoring**, **log**.

**Product maturity note:** BFF modules are largely implemented; several client `apis/*.ts` files are **stubs** with swagger path comments only (`namespace.ts`, `database.ts`, `validation.ts`, …). When implementing client APIs, follow the fully wired examples: `vpc.ts`, `approval.ts`.

---

## Domain vocabulary

FractalDB uses namespace-scoped resources. Match UI labels to API types:

| API / enum | UI label | Notes |
|------------|----------|-------|
| `DatabaseType.Cql` | Keyspace | CQL access |
| `DatabaseType.Rest` | Database | REST access |
| Namespace | Namespace | Top-level; has lifetime, farm, endpoints, backup, QoS |
| User (DBS) | Service user | Auth: password or IAM service account |
| Farm | Farm | Placement; from `available` API |

Status codes: `StatusEnum` in `client/src/enums/status.ts` (Active, InProgress, Error, Deleting, LifetimeEnd, Unknown).

---

## Coding conventions

Apply these whenever modifying FractalDB code.

### 1. Enums — `enums/` only

- Define enums in `client/src/enums/<domain>.ts` (e.g. `database.ts`, `serviceUser.ts`, `status.ts`, `storage.ts`, `network.ts`, `router.ts`, `queryKey.ts`).
- Do **not** put enums inside `types/` files.
- Pair enum values with label maps / option arrays in the same file.
- Column keys, action keys, filter keys, and table name aliases live with their domain enum file.

```ts
// ✅ client/src/enums/database.ts
export enum DatabaseType {
  Cql = 'cql',
  Rest = 'rest',
}
export const DATABASE_TYPE_LABEL: Record<DatabaseType, string> = {
  [DatabaseType.Cql]: 'Keyspace',
  [DatabaseType.Rest]: 'Database',
};
```

Also keep here: `ServiceUserColumnKey` + `SERVICE_USER_COLUMN_LABEL`, `ServiceUserActionKey`, router name constants, and `QueryKey` entries (centralized in `queryKey.ts`).

### 2. Types — `types/` only, `Model` suffix

- **FractalDB domain types:** `client/src/types/fractaldb/<Domain>.ts`
- **Shared/cross-product types:** `client/src/types/common/<Domain>.ts`
- Do **not** put types/interfaces in `enums/` files.
- Interface names **must** end with `Model` (API, form, list, redefined UI shapes).

```ts
// ✅ client/src/types/fractaldb/Storage.ts
export interface StorageModel {
  sizeInGB: number;
  type: string;
}

// ✅ client/src/types/common/Vpc.ts
export interface VpcModel { ... }
```

**Redefined models:** raw API types stay `*Model`; UI-enriched copies use `Redefined*Model` and are built in `helpers/` when formatting is non-trivial.

Enums may be **imported into types** as types only (`import type { DatabaseType } from '@/enums/database'`).

**BFF DTOs** use `*Dto` suffix in `bff/src/modules/<domain>/dto/` — not `Model`.

### 3. Import aliases

| Layer | Alias | Example |
|-------|--------|---------|
| **Client** | `@/` → `src/` | `import { StatusEnum } from '@/enums/status'` |
| **BFF** | `src/` prefix | `import { handleError } from 'src/utils'` |

Client shell imports: `@flava-federation/shell/index` (`useCurrentProject`, `useRegion`, `useUserRoles`, `useErrorPage`).

### 4. API classes — class + singleton + region header

- One file per domain: `client/src/apis/<domain>.ts`.
- Export **class** and **singleton** (`export const vpcApi = new VpcApi()`).
- Methods take `(projectName, region, ...)` — follow parameter order in the domain file being extended.
- Set `'Flava-Region'` on every request via `getHttpClientBuilder().setHeaders({ 'Flava-Region': region })`.
- Base path from `API_PREFIX` in `@/enums/common` (`/api/dbs-for-fractaldb/v1`).
- Unwrap list responses consistently (see `vpc.ts`: `result.data?.items ?? []`).
- Use `BFFResponse<T>` from `@/types/common/Response` for typed responses.

Naming: prefer `*Api` + `*Api` singleton (`vpcApi`). Existing `ApprovalApiService` / `approvalApiService` is the exception — match the file you edit.

When filling stub APIs, preserve the swagger path comments at the top — they map to C-Plane API v1.2.0.

```ts
// ✅ client/src/apis/vpc.ts
export class VpcApi {
  async getVpcs(projectName: string, region: string) {
    const result = await getHttpClientBuilder()
      .setHeaders({ 'Flava-Region': region })
      .build()
      .get<BFFResponse<{ items: VpcModel[] }>>(`${API_PREFIX}/${projectName}/vpcs`);
    return result.data?.items ?? [];
  }
}
export const vpcApi = new VpcApi();
```

### 5. Table names — `TABLE_NAME` in `enums/common.ts`

Format: `` `${FRACTALDB_PRODUCT_ID}-<entity>:v1` `` (will become `PRODUCT_ID.DBS_FOR_FRACTALDB` when enum ships).

```ts
export const TABLE_NAME = {
  NAMESPACE: `${FRACTALDB_PRODUCT_ID}-namespace:v1`,
  DATABASE: `${FRACTALDB_PRODUCT_ID}-database:v1`,
  USER: `${FRACTALDB_PRODUCT_ID}-user:v1`,
  BACKUP: `${FRACTALDB_PRODUCT_ID}-backup:v1`,
  // ...
};
```

Reference from domain enums: e.g. export `ServiceUserTableName` — prefer `TABLE_NAME.*` over hard-coded strings when adding new tables.

---

## Client patterns

### Composables (TanStack Query)

- Location: `client/src/composables/<domain>/use*.ts` (shared utilities under `composables/common/`).
- Always use `useCurrentProject()` + `useRegion()`; pass `projectName.value` and `region.value` into API methods.
- Query keys: `[QueryKey.GetNamespaces, projectName, region, ...]` — never hard-code strings.
- Register new keys in `client/src/enums/queryKey.ts`.
- Errors: `parseRequestError` + `useErrorPage().showErrorPage` for page-level failures.

Template for reads:

```ts
const { name: projectName } = useCurrentProject();
const { region } = useRegion();

useQuery({
  queryKey: [QueryKey.GetNamespaces, projectName, region, params],
  queryFn: () => namespaceApi.getNamespaces(projectName.value, region.value, params.value),
  enabled: computed(() => !!projectName.value),
});
```

Mutations: wrap `useMutation` (see `useSetUnlimitedLifetime`); invalidate related `QueryKey` entries on success.

### Tables

- Use `useTable` from `composables/common/useTable.ts` with `TABLE_NAME.*` and column defs from domain enums.
- Shared UI: `CommonTable.vue`, `FilterWrap.vue`, `MoreActionButton.vue` (CSS prefix `fractaldb_*`).

### Helpers — API ↔ UI

- `helpers/<domain>.ts`: `redefine*`, `transform*ToFormModel`, `build*Request`, domain-specific derivations.
- Example: `helpers/network.ts` maps network tags → storage type via `STORAGE_TYPE`.
- **Label getters with branching logic** (e.g. `getDatabaseTypeLabel`, `getCreateDatabaseActionLabel`, `getDeleteDatabaseActionLabel`) belong in `helpers/`, **not** `enums/`. `enums/` holds enums + static label maps only — any function with `if`/branching is helper code.

### Status strings — raw, not mapped

C-Plane state strings (`'active'`, `'creating'`, `'preparing'`, `'error'`, `'deleting'`) flow **raw** through helpers → UI. Do **not** introduce a `mapXyzStateToStatus` function.

- Pass `db.state` / `table.state` / `index.state` directly to `<Status :status="rowData.state" />`.
- Unknown states render as gray "Unknown" — accept that, don't enrich.
- Permission comparisons can use `StatusEnum.Active` because its value `'active'` matches C-Plane. Other states should be compared as raw strings when needed.
- In `redefineXxx` helpers, put raw `state` strings into both `data[]` (table cell) and `rowData` (slot context). Never call a mapper.

### List + transform pattern — expose multiple computed from the composable

When the same list endpoint feeds different table shapes (e.g. CQL nested keyspace/table/index vs REST flat database), the composable owns the fetch **and** every transform as separate `computed` properties. The caller picks the one it needs.

```ts
// ✅ composables/database/useDatabases.ts
const databases = computed(() => data.value?.content ?? []);
const restRows = computed(() => redefineRestDatabases(databases.value));
const cqlRows = computed(() => redefineCqlDatabases(databases.value));
return { databases, restRows, cqlRows, totalItems, refetchDatabases, ... };
```

Do **not** branch the transform inside the composable on a `databaseType` parameter — that couples the data source to one consumer.

### One table component per resource shape

When a list page must support two distinct resource types with **different action sets, modals, and column behavior** (e.g. Database vs Keyspace), split into one component per shape. The page becomes a thin selector.

```vue
<!-- pages/namespace/detail/Database.vue -->
<KeyspaceTable v-if="isCqlNamespace" ... />
<DatabaseTable v-else ... />
```

- Each `*Table.vue` owns its own `columnSetting`, `useTable(TABLE_NAME.*)`, submenu builders, and modal handlers.
- Add a distinct `TABLE_NAME.*` per table (e.g. `DATABASE`, `KEYSPACE`) so column/filter state persists independently.
- For multi-row-kind tables (keyspace → table → index), dispatch by row kind using a **`Record<RowKind, () => Actions>` map**, not chained `if`/`else`. Type-guards (`isKeyspaceRow`, `isTableRow`, `isIndexRow`) determine the kind once.

### List-page column conventions

- Action column width: **150**.
- Status column: `sorting: false`, `type: 'filter'`, `cannotRemove: true`.
- Name column: `sorting: 'ascending'`, `type: 'search'`, `cannotRemove: true`.
- Don't enrich list rows with per-item detail API calls — the list endpoint already returns `name`, `state`, `sizeBytes`, etc.

### Permissions

- Role checks: `useCheckUserPermission(roles)` with IAM role name strings.
- Gate buttons with `PermissionButton` + `conditions` from `DisabledConditionModel[]`.
- `PermissionResultModel` in `types/common/DisabledCondition.ts` for structured allow/deny + tooltip messages.

### External / cross-product links

Flava routes are **project-scoped**. Never link to `/iam/...`, `/vpc/...`, or `/monitoring/...` without the project segment.

Prefer `useExternalLink()` for cross-product URLs:

```ts
const { createVpcLink, getQueryRunnerLink, approvalPageLink } = useExternalLink();
// Query Runner: /query/{project}/fractaldb/{serviceName}/connect?region={abbrev}
```

Document links: `FRACTALDB_DOCUMENT_LINK`, `SET_LIFETIME_DOCUMENT_LINK`, etc. in `enums/common.ts`.

### Forms (vee-validate)

- Reusable items under `components/common/form/` (`DebounceValidateInput`, `FloatingSelect`, …).
- Async name validation: wire through BFF `validation` module + `DebounceValidateInput`.
- Invalid field scroll: `useFocusInvalidDom` + `FORM_INVALID_CLASS_NAME`.
- Storage bounds: `STORAGE_SIZE_MIN` / `STORAGE_SIZE_MAX` from `enums/storage.ts` (prod vs non-prod via `IS_CONTEXT_PROD`).

### Router

- Route names/paths: `FRACTALDB_ROUTER_PREFIX` + child constants in `enums/router.ts` as features land.
- Register feature routes under `router/index.ts` `children` (namespace, database, user, backup, monitoring, log).
- Navigate with `{ name: ROUTE_NAME, params: { namespace, ... } }` — shell injects `projectName`.

### Notifications

- Global toasts: `useGlobalNotification`.
- Local/snackbar: `useLocalSnackbar` + `SnackbarManager.vue`.

---

## BFF patterns

### Module structure

Each domain under `bff/src/modules/<domain>/`:

- `<domain>.controller.ts` — `@RequestContext()` params
- `<domain>.service.ts` — upstream via `SharedService.getDbsForFractaldbEndpoint(context.projectName, context.region)`
- `dto/*.dto.ts` — request/response DTO classes (`*Dto` suffix)
- `<domain>.module.ts`

Global prefix: `/api/dbs-for-fractaldb/v1/:projectName` (see `main.ts`).

### SharedService

- `getDbsForFractaldbEndpoint(projectName, region)` → `{endpoint}/projects/{projectName}`
- `getVpcEndpoint`, `getNeutronEndpoint`, `getIamEndpoint`, `approvalEndpoint`, `getMonitoringEndpoint`
- `getHeaders(context)` → `{ Authorization: context.normalBearerToken }`
- `getRegionCode(region)` → `KKS` / `SSK` for services needing uppercase codes

### Middleware (app.module.ts)

| Middleware | Routes |
|------------|--------|
| `NormalTokenMiddleware` + `OpenstackTokenMiddleware` | All (`{*path}`) |
| `AuthorizedTokenMiddleware` | `IamController` |
| `IamTokenMiddleware` | `ApprovalController` |
| `MonitoringTokenMiddleware` | `MonitoringController` |

`NormalTokenMiddleware` uses provider TLD `flava-fractaldb`.

### Error handling

- Use `handleError(e, logger, url)` from `src/utils` in services — do not duplicate catch logic.

### Shared DTOs

Reusable shapes in `bff/src/modules/shared/dto/`: `CommonQueryParamsDto`, `PageDto`, `QoSSettingsDto`, `StorageDto`, `NetworkDto`, `AutoBackupDto`, `EndpointDto`.

List responses typically: `{ content: T[], page: PageDto }` (see `NamespaceListDto`).

### Mock data

- `bff/src/mocks/` — namespace, database, user, backup, quota.
- Follow existing sibling DBS products for env-gated mock usage when adding local dev support.

---

## API change → full stack order

When upstream or BFF contract changes, update layers in order:

1. **BFF DTO** — `bff/src/modules/<domain>/dto/*.dto.ts`
2. **BFF service/controller** — forward new fields, query params
3. **Client type** — `client/src/types/fractaldb/<Domain>.ts` or `types/common/` (`*Model`)
4. **Client API** — `client/src/apis/<domain>.ts` (replace stubs with real methods)
5. **Helper** — mappers in `client/src/helpers/<domain>.ts` if display/form shape changes
6. **Enum/label** — column keys, status labels, form paths
7. **Composable** — query/mutation hooks + `QueryKey`
8. **UI** — components / routes last

Run scoped checks:

```bash
pnpm --filter product-dbs-for-fractaldb-bff run type:check
pnpm --filter product-dbs-for-fractaldb-client run type:check
pnpm --filter product-dbs-for-fractaldb-client run lint
```

---

## UI components

- Use **Flava UI** from `@linecorp/flava-ui` (`FlavaHeadLine`, `FlavaButton`, `FlavaTooltip`, table hooks via `useTableColumn` / `useTableFilter` / `useTablePagination`).
- Page shell: `layout/PageTemplate.vue` (wires `FRACTALDB_DOCUMENT_LINK`, optional `Status`).
- Status display: `components/common/Status.vue` + `StatusEnum`.
- Layout spacing: Tailwind / `lp_*` utilities and existing `tw-*` classes; table/filter wrappers use `fractaldb_*` BEM-style classes.

---

## Checklists

### New namespace (or database / user) field

1. BFF DTO + service mapping
2. `*Model` in `types/fractaldb/` (or extend BFF-aligned nested type)
3. Client API method if new endpoint or payload
4. `redefine*` / form helper if UI displays formatted value
5. Enum/label if user-facing label or filter column
6. Composable + `QueryKey` if fetched separately
7. Component / form item / route

### New enum-driven action (e.g. service user)

1. Add `ServiceUserActionKey` (or domain equivalent) + label map in domain enum file
2. Wire permission / disabled conditions
3. Add UI entry (`MoreActionButton` / `PermissionButton`)
4. Modal or navigation handler

### New list/table

1. `*ColumnKey` enum + `*_COLUMN_LABEL` + `TABLE_NAME` entry in `enums/common.ts`
2. `useTable` with table name constant
3. Search/filter keys in same enum file when applicable

### Implement a stub client API

1. Read swagger comments at top of stub file
2. Match BFF controller path under `API_PREFIX/${projectName}/...`
3. Copy pattern from `vpc.ts` or `approval.ts`
4. Add composable + `QueryKey`
5. Type response with `*Model` interfaces

---

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Path `apps/product-fractaldb/` | Use `apps/product-dbs-for-fractaldb/` |
| Commit scope `fractaldb` | Use `dbs-for-fractaldb` |
| Types in `enums/` or enums in `types/` | Split per rules above |
| Interface without `Model` suffix | Rename to `*Model` |
| Hard-coded query key string | Add to `QueryKey` in `queryKey.ts` |
| `/iam/...` or `/vpc/...` without project | Use `useExternalLink()` or `/${projectName.value}/...` |
| BFF import without `src/` | Use `src/modules/...` |
| Client API without `Flava-Region` header | Always set via `getHttpClientBuilder()` |
| Confuse Keyspace vs Database | Check `DatabaseType` + `DATABASE_TYPE_LABEL` |
| Skip BFF when adding client endpoint | Client calls BFF, not C-Plane directly |
| Use `PRODUCT_ID.DBS_FOR_FRACTALDB` before enum release | Keep `FRACTALDB_PRODUCT_ID` until lycc-enums ships it |
| Mapping `state` → `StatusEnum` in helpers | Pass raw C-Plane state strings straight to `<Status>` |
| Branching label getter in `enums/` (e.g. `if (type === Cql)`) | Move to `helpers/<domain>.ts` |
| Composable branches transform on `databaseType` | Expose `restRows` + `cqlRows` as separate `computed`, let caller pick |
| Chained `if/else` for row-kind in shared table | Split into one `*Table.vue` per resource shape; dispatch via `Record<RowKind, ...>` map |
| Per-row detail fetch for list display | List endpoint is sufficient — no enrichment |
| Action column width ≠ 150 in FractalDB tables | Use `width: 150` |

---

## Related skills

- **flava-blueprint-skill** — parallel product skill structure (reference only; different domain)
- **flava-jira-check** — ticket investigation on branch `CLOUDQA-*` / `LYCC-*`
- **flava-commit-skill** / **flava-pr-skill** — commit scope `dbs-for-fractaldb`, PR labels
- **flava-vector-search-skill** — another DBS-family product skill pattern
