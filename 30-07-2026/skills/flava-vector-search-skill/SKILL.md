---
name: flava-vector-search-skill
description: Authoritative implementation guide for **product-dbs-for-vector-search** (Vector Search as a Service) in the Flava Console monorepo. Covers the full product: service create/delete/extend-lifetime, index management, index templates, ML model deploy/register, DB roles, user/IAM management, BFF module structure, client composable patterns, validation, and modal conventions. Use this skill whenever work touches **product-dbs-for-vector-search**, vector search services, service creation form, node groups, engine versions, availability zones, storage config, index CRUD, index templates, ML model catalog, DB roles, system accounts, IAM users, or any service-level modal — even if the user only mentions "vector search", "VS service", "service nodes", "DB role", or "register model". Load this skill before adding features, modifying BFF DTOs, adding composables, or changing modal/form behavior. **For pipeline internals** (processors, serialization, visual/code editor, simulate, pipelineMapping/Creation/Edit/Comparison) use `flava-vector-pipeline-skill` instead or in addition.
---

# Flava Vector Search (product-dbs-for-vector-search) Skill

This skill is the single source of truth for coding-agents working inside `apps/product-dbs-for-vector-search`. Read it fully before making changes.

> **Pipeline feature scope**: The pipeline builder (ingest/search processors, serialization, visual editor, simulate, phase results, `rules.ts`, etc.) is covered by **`flava-vector-pipeline-skill`**. Load that skill when the task is pipeline-specific. This skill covers everything else — and the outer shell of the pipeline pages (routing, modals, list page).

---

## Coding principles

These apply to every file in `apps/product-dbs-for-vector-search`.

### TypeScript everywhere

- No `any`, no plain `.js` files. All new files must be `.ts` or `.vue` with `<script setup lang="ts">`.
- Export types from `types/vectorSearch/` — do not define ad-hoc shapes inline in composables or components.
- Use `interface` for object shapes returned by the API; `type` for unions, aliases, or utility types.
- When extending an existing type (e.g. adding a field to `VectorSearchService`), update `types/vectorSearch/Service.ts` first, then fix downstream usages — never cast with `as any`.
- BFF DTOs use `class-validator` + `class-transformer`. Every field needs its type decorator even when `@IsOptional()` is present.

### DRY — Don't Repeat Yourself

- All data-fetch logic lives in `composables/hook/<domain>/useXxx.ts`. Do not call API functions directly from components.
- Domain string constants live in enums (`enums/service.ts`, `enums/node.ts`, `enums/queryKey.ts`, etc.). Never hard-code enum values or query key strings inline.
- Transformation helpers (`helpers/service.ts`, `helpers/pipeline.ts`, `helpers/indexTemplate.ts`) own form↔payload conversion. Do not re-implement conversions in components.
- Validators belong in `validators/<domain>.ts` and are registered via vee-validate rules (e.g. `import '@/validators/service'`). Do not inline regex or business rule checks in templates.

### No hard-coded strings

- **Action keys**: `ServiceActionKey`, `PipelineActionKey`, `DBRoleActionKey` in `enums/service.ts`.
- **Query keys**: always use `QueryKey.*` from `enums/queryKey.ts`. Never pass raw strings to `useQuery`/`invalidateQueries`.
- **Router names**: use `VECTOR_SEARCH_SERVICE_ROUTER_LIST` and siblings from `enums/router.ts`.
- **Status values**: `StatusEnum` from `enums/status.ts`.
- **Node roles**: `NodeRole`, `ClusterTypeEnum` from `enums/node.ts`.
- Labels: keep in the `*_LABEL` / `*_COLUMN_LABEL` maps (e.g. `SERVICE_ACTION_LABEL`, `PIPELINE_ACTION_LABEL`) — never scatter them as raw strings in templates.
- Error/snackbar titles: define a `const content = { title: '...' }` object at the top of the component; do not scatter literal strings across the template.

### Readable variable names

- Boolean refs: prefix with `is`, `has`, `can` — e.g. `isCreatingService`, `hasLoadedModels`.
- Loading states from `useMutation`/`useQuery`: destructure with a descriptive alias — e.g. `const { isPending: isDeletingService } = useMutation(...)`.
- Form field bindings: name the vee-validate destructured aliases explicitly — e.g. `const { value: serviceName, errorMessage: serviceNameError } = useField(...)`.

---

## App roots

| Layer | Path | Package name |
|---|---|---|
| Client (Vue 3) | `apps/product-dbs-for-vector-search/client/src/` | `product-dbs-for-vector-search-client` |
| BFF (NestJS) | `apps/product-dbs-for-vector-search/bff/src/` | `product-dbs-for-vector-search-bff` |

---

## Mental model — what this product is

**Vector Search as a Service** — a managed OpenSearch cluster (with vector search extensions) hosted on Flava infrastructure. Users:

1. **Create a service** — configure engine version, VPC/network, node groups (roles, flavors, storage, AZs), backup, lifetime.
2. **Use indices/index templates** — create/manage OpenSearch indices and templates inside the service.
3. **Configure pipelines** — ingest + search pipelines with processor chains (see `flava-vector-pipeline-skill`).
4. **Register ML models** — link models from the ML catalog for neural/hybrid search.
5. **Manage DB roles** — fine-grained access control (index patterns, permissions, field-level/document-level security).
6. **Manage users** — system accounts and IAM users; assign DB roles.

---

## Architecture — data flow

```
Client page / modal
  │
  ├─ composable (composables/hook/<domain>/useXxx.ts)
  │     └─ useMutation / useQuery via @tanstack/vue-query
  │           └─ api function in apis/<domain>.ts
  │                 └─ HTTP → BFF /api/...
  │
  ├─ helpers/<domain>.ts   ← form model ↔ API payload transformation
  │
  ├─ validators/<domain>.ts  ← vee-validate rules, registered globally
  │
  └─ vee-validate (useForm + useField)
        └─ DebounceValidateInput for async validation (e.g. name uniqueness)
```

### BFF module flow

```
NestJS Controller (*.controller.ts)
  └─ validates request body with class-validator DTO
        └─ Service (*.service.ts)
              └─ proxies to upstream vector-search API via HttpService
```

---

## BFF — module structure

```
bff/src/modules/
  services/        ← Service CRUD (create, get, delete, extend lifetime)
  indices/         ← Index CRUD inside a service
  index-templates/ ← Index template CRUD inside a service
  pipelines/       ← Pipeline CRUD + simulate (ingest + search)
  available/       ← Processor definitions, engine versions, storage types, server types, AZs
  models/          ← ML model catalog, model links (deploy/undeploy/register)
  dbroles/         ← DB role CRUD
  network/         ← Network list
  vpc/             ← VPC list
  iam/             ← IAM user lookups
  approval/        ← Quota requests
  validation/      ← Input validation proxy (e.g. name uniqueness check)
  shared/          ← Common DTOs (CommonQueryParamsDto)
```

### BFF DTO rules

- **Class declaration order matters** when using `@Type(() => NestedClass)` in the same file. Always declare nested DTO classes **above** the parent.
- Every field needs its class-validator decorator (`@IsString()`, `@IsInt()`, `@IsOptional()`, etc.) even when optional.
- BFF services are **pure proxies** — transform only when necessary; do not add business logic.

---

## Client — directory guide

```
client/src/
  apis/
    index.ts          ← barrel: re-exports all API modules
    service.ts        ← serviceApi (create, get, delete, extend)
    pipeline.ts       ← pipelineApi (CRUD + simulate, ingest + search)
    pipelines.ts      ← pipelinesApi (list pipelines)
    indices.ts        ← indicesApi
    indexTemplate.ts  ← indexTemplateApi
    mlModel.ts        ← mlModelApi (list, deploy, undeploy, register, unregister)
    available.ts      ← availableApi (processor defs, versions, server types, AZs, storage, quota)
    approval.ts
    iam.ts
    dbroles.ts
    network.ts / vpc.ts
  enums/
    queryKey.ts       ← QueryKey enum (ALWAYS use instead of raw strings)
    service.ts        ← ServiceActionKey, PipelineActionKey, DBRoleActionKey, VectorSearchMode, enums...
    node.ts           ← NodeRole, ClusterTypeEnum
    status.ts         ← StatusEnum
    router.ts         ← VECTOR_SEARCH_SERVICE_ROUTER_LIST and other route name constants
    common.ts         ← TABLE_NAME and other cross-domain constants
    mlModel.ts / role.ts / user.ts / ...
  types/
    vectorSearch/
      Service.ts      ← VectorSearchService, NodeGroup, ServiceList, CreateServiceFormModel, ...
      pipeline.ts     ← PipelineFormValues, CreationMode, IngestPipelineItem, SearchPipelineItem, ...
      processor.ts    ← ProcessorType, ProcessorField enums
      Available.ts    ← ProcessorDefinition and available types
      Index.ts        ← CreateIndexRequest and index types
      IndexTemplate.ts
      MlModel.ts
      DatabaseRole.ts
      ServiceUser.ts
      Vpc.ts / Network.ts / Quota.ts / ...
    common/
      Error.ts / Response.ts / Pagination.ts / mutation.ts / ...
  helpers/
    service.ts        ← convertToCreateServicePayload, formatQuotaItems, calculateResourceUsage
    pipeline.ts       ← formatPipelineError
    indexTemplate.ts
    serviceUser.ts
  validators/
    service.ts        ← vee-validate rules for service create (import once to register)
    serviceName.ts / pipelineName.ts / indexName.ts / dbRole.ts / accountName.ts / ...
    common.ts         ← shared validation rules
  composables/
    common/
      useProjectInfo.ts        ← projectName from route params
      useGlobalNotification.ts ← showSuccessToast (global toast)
      useModalLocalSnackbar.ts ← isolated in-modal snackbar
      useModalWithSnackbar.ts  ← wraps useModalLocalSnackbar with aliased API
      useEnv.ts
      useAutoFocus.ts / useFocusInvalidDom.ts / useScrollToTop.ts / useTable.ts
    available/
      useAvailableVersions.ts / useAvailabilityZones.ts / useAvailableServerTypes.ts
      useAvailableStorageOptions.ts / useAvailableStorageTypes.ts / useAvailableQuota.ts
      useAvailableModel.ts / useAvailableModels.ts / useAvailableTemplates.ts
      useIngestProcessorDefinitions.ts / useSearchPhaseProcessorDefinitions.ts / ...
      useAvailableFieldTypes.ts   ← QueryKey.GetAvailableFieldTypes; fallback ['knn_vector','sparse_vector']
      useAvailableFieldTypes.ts   ← field types for pipeline index (knn_vector / sparse_vector)
    hook/
      service/
        useCreateService.ts     ← createService mutation
        useDeleteService.ts
        useExtendLifetime.ts
        useServiceDetail.ts     ← useQuery with polling (DEFAULT_POLLING_INTERVAL)
        useServices.ts          ← list query
        useServiceConfig.ts
        useServicePermission.ts
        useUpdateServiceDescription.ts
      index/
        useCreateIndex.ts / useDeleteIndex.ts / useIndex.ts / useBulkIndexDocuments.ts
      indexTemplate/
        useCreateIndexTemplate.ts / useUpdateIndexTemplate.ts / useDeleteIndexTemplate.ts
        useIndexTemplate.ts / useIndexTemplates.ts
        useUpdateIndexTemplateDescription.ts
        useIndexTemplatePermission.ts / useActionMenu.ts
      mlModel/
        useDeployModel.ts / useUndeployModel.ts
        useRegisterModel.ts / useUnregisterModel.ts
        useListModels.ts / useAllModels.ts / useModels.ts / useModel.ts
        useLinkedModel.ts / useLinkedPipelines.ts
        useAvailableModels.ts / useRegisterListModel.ts
        useMlModelPermission.ts / useUpdateModelDescription.ts
      pipeline/
        useCreateOrUpdatePipelines.ts  ← all pipeline save/simulate mutations
        useDeletePipeline.ts / usePipelines.ts / usePipelineDetail.ts
        useIngestPipeline.ts / useSearchPipeline.ts
        usePipelinePermission.ts / useUpdatePipelineDescription.ts
      user/
        useServiceUserList.ts / useServiceUserRoles.ts / useAssignRole.ts
        useCreateSystemAccount.ts / useDeleteSystemAccount.ts / useDeleteUser.ts
        useResetPasswordSystemAccount.ts
      role/
        useRolePermission.ts
      iam/ node/ ...
  store/
    snackbar.ts   ← useSnackbarStore (Pinia): global snackbar list, showSnackbar, closeSnackbar
  components/
    modal/
      service/   ← DeleteServiceModal.vue, ExtendLifetimeModal.vue, SetLifetimeModal.vue
                    service/user/ → CreateSystemAccountModal.vue, DeleteUserModal.vue, ResetPasswordModal.vue, EditDBRoleModal.vue, ConfirmPasswordModal.vue
      pipeline/  ← DeletePipelineModal.vue, DuplicatePipelineModal.vue, ChangeCreationModeModal.vue
      model/     ← DeployModelModal.vue, UndeployModelModal.vue, RegisterModelModal.vue, UnregisterModelModal.vue, RedeployModelModal.vue, RegisterListModelModal.vue
      indexTemplate/ ← DeleteIndexTemplateModel.vue
      DBRole/    ← DeleteDBRoleModal.vue, ViewDBRoleModal.vue
      connector/ ← DeleteConnectorModal.vue
      common/    ← ApprovalSuccessModel.vue
    common/
      form/
        DebounceValidateInput.vue  ← async validation (e.g. name uniqueness)
        CodeEditor.vue / MultiInput.vue / RoleMultiSelector.vue
      button/ ← ActionDropdown.vue, PermissionButton.vue, TooltipIconButton.vue
      snackbar/useLocalSnackbar.ts
      table/ ← CommonTable.vue, FilterWrap.vue
    layout/    ← Layout.vue (main), ServiceLayout.vue, PipelineOverviewLayout.vue, ...
    service/
      create/  ← EngineVersion.vue, NodeGroupsManager.vue, ArchitectReview.vue, AvailabilityZone.vue,
                  VpcNetworkSelection.vue, AutoBackup.vue, VectorModeSelection.vue, NodeGroupForm.vue,
                  NodeFlavor.vue, NodeCount.vue, NodeStorage.vue, NodeRoles.vue, CustomizeConfigNodeGroup.vue
      detail/  ← BasicInfo.vue, Endpoint.vue, NetworkConfiguration.vue, NodeConfiguration.vue
      details/ ← DBRole/*, pipeline/* (see flava-vector-pipeline-skill for pipeline internals)
    SnackbarManager.vue  ← renders global snackbar list from useSnackbarStore
  pages/
    service/
      List.vue        ← service list with search, filter, sort
      Create.vue      ← multi-section create form (no multi-step wizard — single-page with sections)
      LandingPage.vue
      detail/
        Index.vue     ← detail wrapper (tabs routing)
        Overview.vue  ← service overview tab
        Pipeline.vue  ← pipeline tab (see flava-vector-pipeline-skill)
        DBRole.vue    ← DB role tab
        MLModel.vue   ← ML models tab
        index/        ← index management sub-pages
        mlModel/      ← ML model detail
        pipeline/     ← pipeline create/edit/overview sub-pages
        user/         ← user management
    mlModelCatalog/
      List.vue / Detail.vue  ← global ML model catalog
    mlConnector/
      List.vue
    ErrorView.vue
```

---

## Service creation form

The service create form is a **single page** (not a multi-step wizard), using `vee-validate` (`useForm`/`useField`) for validation.

### Key composables

- `useCreateService` — wraps `useMutation` for `serviceApi.createService`. Payload built by `convertToCreateServicePayload(formData)` from `helpers/service.ts`.
- `useAvailableQuota` — quota check before submit; `isQuotaExceeded(resourceUsage, quota)` from utils.
- `useAvailableVersions`, `useAvailableServerTypes`, `useAvailabilityZones`, `useAvailableStorageTypes`, `useAvailableStorageOptions` — drive the selects/options in the form.

### Node groups

- Node groups are configured via `NodeGroupsManager.vue` — supports **Easy create** (`VectorSearchMode.EasyCreate`) and **Customize** (`VectorSearchMode.Customize`) modes.
- Node roles are `NodeRole` enum values; all required roles are listed in `ALL_REQUIRED_ROLES` from `enums/node.ts`.
- Multi-AZ: `NODE_FOR_3_AZ` constant gates AZ-specific options.
- Quota validation: `calculateResourceUsage(nodeGroups, serverTypes)` and `isQuotaExceeded(usage, quota)` from `utils/serviceFormTransformers.ts`.

### Validation pattern

1. Import and register validators: `import '@/validators/service'`
2. Use `useForm` + `useField` from vee-validate.
3. Use `DebounceValidateInput.vue` for async name-uniqueness checks.
4. Use `useFocusInvalidDom` to auto-scroll to the first invalid field on failed submit.

---

## Service detail — tabs

| Tab | Route | Component | Key composables |
|---|---|---|---|
| Overview | `.../overview` | `detail/Overview.vue` | `useServiceDetail` |
| Pipeline | `.../pipeline` | `detail/Pipeline.vue` | `usePipelines` |

> **Pipeline index field types:** See `flava-vector-pipeline-skill` — **Pipeline Index — field type selection** section — for `FieldType` enum caveats, sparse vector form components, payload shape, and `n_postings` Integer coercion.
| Index | `.../index` | `detail/Index.vue` | indices composables |
| ML Model | `.../mlModel` | `detail/MLModel.vue` | mlModel composables |
| DB Role | `.../dbrole` | `detail/DBRole.vue` | `useRolePermission` |
| User | implicit | user sub-pages | user composables |

### useServiceDetail

```ts
const { serviceDetail, serviceStatus, isFetching, isPending } = useServiceDetail(serviceName);
```

- Uses `refetchInterval: DEFAULT_POLLING_INTERVAL` (from `@linecorp/lycc-enums`) for status polling.
- On 404/error, calls `showErrorPage` from `useErrorPage`.
- `serviceStatus` is a computed that returns `StatusEnum.Unknown` if data not yet loaded.

---

## Composable pattern

All composables follow this structure:

```ts
// composables/hook/service/useXxx.ts
import { useMutation } from '@tanstack/vue-query';
import { serviceApi } from '@/apis/service';
import { useProjectInfo } from '@/composables/common/useProjectInfo';
import { useRegion } from '@flava-federation/shell/index';

export const useXxx = () => {
  const { projectName } = useProjectInfo();
  const { region } = useRegion();

  const { mutateAsync: doSomething, isPending: isDoingSomething } = useMutation({
    mutationFn: (payload: SomePayload) =>
      serviceApi.doSomething(projectName.value, payload, region.value),
  });

  return { doSomething, isDoingSomething };
};
```

Always pass `projectName.value` and `region.value` to API calls — never access them from route params directly in components.

### Query pattern

```ts
const { data, isFetching, isPending } = useQuery({
  queryKey: [QueryKey.GetServiceDetail, projectName, region, serviceName],
  queryFn: () => serviceApi.getServiceDetail(projectName.value, serviceName, region.value),
  initialData: undefined,
  refetchInterval: DEFAULT_POLLING_INTERVAL,
  enabled: !!serviceName,
});
```

---

## API change → updating the full stack

When the upstream vector search API changes a request/response shape, follow this order:

1. **BFF DTO** — `bff/src/modules/<domain>/dto/*.dto.ts`
   - Add/remove/rename the field with class-validator decorators.
   - Nested DTO class must be declared **above** the parent class.
   - Run `pnpm --filter product-dbs-for-vector-search-bff run type:check`.

2. **Client type** — `client/src/types/vectorSearch/<Domain>.ts`
   - Update the matching interface or add a new one.
   - Export from `types/vectorSearch/index` if needed.

3. **Helper** — `client/src/helpers/<domain>.ts`
   - If the field needs form↔payload conversion, update the relevant transformer.
   - Example: adding a field to service create → update `convertToCreateServicePayload` in `helpers/service.ts`.

4. **API function** — `client/src/apis/<domain>.ts`
   - Add/update the typed function.
   - Add a `QueryKey` constant in `enums/queryKey.ts` for any new query.

5. **Composable** — `composables/hook/<domain>/useXxx.ts`
   - Update an existing composable or create a new one (naming: `use<Resource><Action>.ts`).

6. **UI** — components/pages — last, after all lower layers are typed.

---

## Modal conventions

All modals live under `components/modal/<domain>/`. Patterns:

- Use `useModalWithSnackbar` (wraps `useModalLocalSnackbar`) for in-modal snackbar.
- Use `useGlobalNotification` → `showSuccessToast` for post-submit success.
- On success: call `closeModal` / close handler, `showSuccessToast`, then `queryClient.invalidateQueries`.
- Use `SnackbarManager.vue` with `:snackbars="snackbars"` in the modal template for error display.

### Standard modal template

```vue
<FlavaModal visible close-button @close="handleClose" noClickOutsideClose>
  <template #title><h2 class="title">{{ content.title }}</h2></template>
  <template #content>
    <SnackbarManager :snackbars="snackbars" @close-snackbar="closeLocalSnackbar" />
    <!-- form content -->
  </template>
  <template #button>
    <FlavaButton appearance="outlined" size="large" @click="handleClose">Cancel</FlavaButton>
    <FlavaButton :color="BUTTON_COLOR.PRIMARY" size="large" @click="handleSubmit"
      :disabled="isSubmitting" :loading="isSubmitting">
      Confirm
    </FlavaButton>
  </template>
</FlavaModal>
```

### Standard submit handler

```ts
const handleSubmit = async () => {
  // 1. validate
  const { valid } = await validate(); // vee-validate form-level
  if (!valid) return;
  // 2. run mutation
  try {
    await doSomething(payload);
    handleClose();
    showSuccessToast();
    queryClient.invalidateQueries({ queryKey: [QueryKey.GetServices, projectName.value] });
  } catch (error) {
    showLocalErrorSnackbar(error as FlavaHttpError<any>);
  }
};
```

### Adding a new modal

1. Create `components/modal/<domain>/MyActionModal.vue`.
2. Add a new `ActionKey` value to the relevant enum in `enums/service.ts`.
3. Wire in the list/detail page with the relevant `useModal` pattern.
4. Follow the template structure above.
5. Define `const content = { title: '...' }` — never scatter literal strings in the template.

---

## ML Model feature

- ML models are registered from the global ML catalog (`mlModelCatalog/`) into a specific vector search service.
- Key composables: `useDeployModel`, `useUndeployModel`, `useRegisterModel`, `useUnregisterModel`.
- `useLinkedModel` — fetches models linked to a service.
- `useAvailableModels` — fetches models available to register.
- `DeployModelModal`, `UndeployModelModal`, `RegisterModelModal`, `UnregisterModelModal` — all follow the standard modal pattern.

---

## DB Role feature

- DB Roles control index-level, field-level, and document-level access.
- Create/Edit flows use `DBRoleForm.vue` (under `service/details/DBRole/`).
- Key form items: `IndexPatternFormItem`, `IndexPermissionItem`, `AnonymizeFieldFormItem`, `DocumentLevelSecurityFormItem`, `FieldLevelSecurityFormItem`.
- Validators: `validators/dbRole.ts`.
- `DBRoleActionKey` (in `enums/service.ts`): `CreateDBRole`, `EditDBRole`, `ViewDBRole`, `DeleteDBRole`.

---

## Validation pattern

### Form-level (vee-validate)

```ts
import { useForm, useField } from 'vee-validate';
import '@/validators/service'; // registers rules

const { validate, errors } = useForm();
const { value: name, errorMessage: nameError } = useField('name', 'required|serviceName');
```

### Async (name uniqueness)

Use `DebounceValidateInput.vue` — it debounces and calls the validation endpoint via `validationApi`.

```vue
<DebounceValidateInput
  v-model="name"
  :validate="validateServiceName"
  :error-message="nameError"
  label="Service name"
/>
```

### Focus on first error

```ts
import { useFocusInvalidDom } from '@/composables/common/useFocusInvalidDom';
const { focusInvalidDom } = useFocusInvalidDom();

const handleSubmit = async () => {
  const { valid } = await validate();
  if (!valid) { focusInvalidDom(); return; }
  // ...
};
```

---

## Notification pattern

| Scope | Composable | When |
|---|---|---|
| In-modal errors | `useModalWithSnackbar` → `showLocalErrorSnackbar` | API errors inside a modal |
| Page-level errors | `useSnackbarStore` → `showSnackbar` | Errors outside a modal |
| Success | `useGlobalNotification` → `showSuccessToast` | After successful mutation |

---

## Do NOT do

- **Do not** call API functions directly from components — always go through a composable.
- **Do not** hard-code query key strings — use `QueryKey.*` from `enums/queryKey.ts`.
- **Do not** add business logic in BFF `*.service.ts` files — they are pure proxies.
- **Do not** define a DTO class after the class that references it via `@Type()` in the same file.
- **Do not** duplicate form↔payload conversion logic that already lives in `helpers/`.
- **Do not** use `useSnackbarStore` directly inside modals — use `useModalWithSnackbar` for isolated modal snackbars.
- **Do not** access `route.params.projectName` or `region` directly in components — use `useProjectInfo()` and `useRegion()`.
- **Do not** modify pipeline serialization/processor logic without also loading `flava-vector-pipeline-skill` and extending `processorSerialization.test.ts`.

---

## Adding a new feature — checklist

### New field on an existing resource

1. **BFF DTO** — add field + decorator; check class declaration order.
2. **Client type** — update `types/vectorSearch/<Domain>.ts`.
3. **Helper** — update `helpers/<domain>.ts` if form↔payload conversion is needed.
4. **API function** — update `apis/<domain>.ts`; add `QueryKey` if new query.
5. **Composable** — update or create in `composables/hook/<domain>/`.
6. **UI** — update component/page last.

### New resource type / new domain

1. Create `bff/src/modules/<domain>/` with `controller`, `service`, `module`, `dto/` files.
2. Register the new module in `bff/src/app.module.ts`.
3. Create `client/src/apis/<domain>.ts`.
4. Add `QueryKey` entries in `enums/queryKey.ts`.
5. Add action key enum and label map in `enums/service.ts` (or a new enum file).
6. Create composables under `composables/hook/<domain>/`.
7. Add types under `types/vectorSearch/`.
8. Add validator rules under `validators/`.

### New modal action

1. Create `components/modal/<domain>/MyActionModal.vue`.
2. Add `ActionKey` value in `enums/service.ts`.
3. Wire in the list/detail page.
4. Follow the modal template pattern above.

---

## Commands

```bash
# Discover package names
pnpm -r list --depth -1 | grep vector-search

# Lint
pnpm --filter product-dbs-for-vector-search-client run lint
pnpm --filter product-dbs-for-vector-search-bff run lint

# Type check (build shell first if shared types changed)
pnpm --filter flava-shell-client run build
pnpm --filter product-dbs-for-vector-search-client run type:check
pnpm --filter product-dbs-for-vector-search-bff run type:check

# Unit tests
pnpm --filter product-dbs-for-vector-search-client run test:ci

# Processor serialization tests only (when touching pipeline core)
cd apps/product-dbs-for-vector-search/client
pnpm exec vitest run src/utils/pipeline/processorSerialization.test.ts --environment jsdom

# Dev server
pnpm --filter product-dbs-for-vector-search-client run serve --force
```
