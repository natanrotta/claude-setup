# Frontend Architecture — Canonical Lifecycle (Authority)

**This document is the single source of truth for how data flows from a user action → API → render in the frontend.**

Every frontend skill (`/frontend`, `/fullstack`, `/ui-design`, `/code-review`, `/test-e2e`) MUST defer to this document. If a skill contradicts this file, this file wins. If you discover a divergence between this file and the actual code, update this file.

---

## Stack

- **Bundler:** Vite
- **Framework:** React 18 (functional + hooks, no class components)
- **Router:** React Router v6 (config-based, lazy + Suspense)
- **UI:** Chakra UI 2.8 with custom theme + semantic tokens
- **State (server):** TanStack Query v5
- **State (global UI):** React Context only (Auth, Sidebar, Copilot) — **no Redux, no Zustand**. Documented feature-scoped exception: `ScheduleCalendarContext` carries **navigation state only** (workplaceId/year/month/currentMonth + prev/next/today) for the workplace-calendar tree — never server data, which lives in the focused `useScheduleProfessionals`/`useScheduleSectors`/`useScheduleShifts` hooks.
- **Forms (validated):** react-hook-form + Zod (lazy schema builders for i18n)
- **Forms (simple modals):** `useFormState` hook
- **HTTP:** Axios with interceptors (session cookie ride-along, refresh, CSRF, language, envelope unwrap). The one non-Axios transport is the copilot SSE stream — `HttpCopilotRepository.streamChat` uses native `fetch` (Axios can't stream in the browser) and re-attaches `credentials: "include"` + the CSRF header manually.
- **Animations:** Framer Motion (`motion(Box)` pattern, organic easing)
- **i18n:** react-i18next (3 locales: pt-BR default, en, es). Only **pt-BR** (the fallback) is bundled in the entry chunk; en/es load on demand as one lazy chunk each (see `shared/i18n/index.ts` + `locales/{en,es}/index.ts`).
- **Tests:** Vitest (co-located `*.spec.ts(x)` unit/component tests, `jsdom`) + Playwright (e2e in `apps/web/e2e/`)
- **TypeScript:** strict, no `any` (use `unknown` and narrow)

---

## Layer Structure (`apps/web/src/`)

```
app/                              # App-level setup (one-time)
  router/AppRouter.tsx            # Lazy + Suspense + guards
  router/RoutePaths.ts            # All paths centralized — no string literals in components
  theme/foundations/semantic-tokens.ts  # bg.*, text.*, border.*, status.* (with _dark variants)
  theme/components/               # Chakra component overrides
  providers/                      # AppProviders (QueryClient, Chakra, i18n, Auth)

core/                             # Cross-cutting infrastructure
  di/repositories.ts              # Singleton repository registry
  domain/CrudRepository.ts        # Base repository interface (extend in feature repos)
  http/httpClient.ts              # Axios + interceptors (refresh, envelope unwrap, CSRF, language)
  errors/AppError.ts              # message, code, statusCode, details
  query/queryClient.ts            # TanStack QueryClient config
  query/queryKeys.ts              # ALL query keys (factory pattern, hierarchical)
  query/entityQueryKeys.ts        # Generic key types

modules/{feature}/                # Feature modules (one per domain — patients, schedules, ...)
  domain/
    entities/{Entity}.ts          # Plain TS interface + Create/Update input types
    repositories/{Entity}Repository.ts  # extends CrudRepository<T, TC, TU> [+ BulkDeletable]
    services/                     # (optional) pure, reusable domain logic
  application/                    # (OPTIONAL, on demand) framework-agnostic orchestration
    use-case/                     #   headless use-cases when a hook outgrows itself
    dto/                          #   Zod form schemas + inferred types
  infrastructure/
    repositories/Http{Entity}Repository.ts  # implements the interface
  presentation/                   # every React surface of the module
    pages/                        # Route-level components (own all queries)
    components/                   # Module-specific components (group by feature when large)
    hooks/                        # use{Entity} (detail), use{Entities} (list), use{Entity}Schemas — the FE "use case"
    context/                      # Context providers scoped to the module (definition + provider)
    constants/                    # Module-specific constants
    styles/                       # (optional) local recipes/sx, if any
    utils/                        # presentation helpers
    types/                        # (optional) local view-models
  routes.tsx                      # (optional) module-owned <Route> tree, aggregated by app/router
  index.ts                        # BARREL — public API (MANDATORY): entity types + public hooks

shared/                           # Cross-module reuse
  components/
    ui/                           # AppModal, EntityCard, ListPageLayout, EmptyState, ProfileHeader, ...
    forms/                        # FormField, SelectField, DateField, RichTextField, PasswordField, ...
    layout/                       # AppShell, Sidebar, Topbar
    skeletons/                    # ListPageSkeleton, DetailPageSkeleton, ...
    animations/                   # FadeIn, StaggerContainer, StaggerItem
  hooks/                          # useEntityList, useEntityDetail, useListPageController,
                                  #   useDetailPageController, useFormState, useAutoSave,
                                  #   useNotify, useBulkSelection, useConfirm, useDebounce,
                                  #   useUnsavedChangesGuard, useInfiniteListPage, useServerSearch
  contexts/                       # SidebarContext, CopilotContext
  i18n/locales/{pt-BR,en,es}/     # One JSON per namespace
  utils/                          # date, phone, document, mergeEdits, pagination
  constants/                      # Animation constants (EASE_ORGANIC, TRANSITION_*), enums
  types/                          # PaginationParams, PaginatedResponse, ...
```

**Dependency rule:** `domain` ← `infrastructure` ← `presentation`. Components never import from `infrastructure` directly — always go through `core/di/repositories.ts` and a hook.

---

## Canonical Data-Fetching → Render Lifecycle

For "user opens patient detail" (illustrative):

1. `<Route path="/patients/:id" element={<PatientDetailPage />} />` matches
2. `<PatientDetailPage />` mounts; `useParams()` reads `id`
3. `usePatient(id)` is called — wraps `useEntityDetail({ id, queryKey: queryKeys.patients, repository: repositories.patient })`
4. TanStack Query checks cache for `queryKeys.patients.detail(id)`; if stale or missing → `queryFn` runs
5. `queryFn` → `repositories.patient.getById(id)` → `Http{Patient}Repository.getById(id)` → `httpClient.get("/patients/" + id)`
6. Axios request interceptor: the session rides the httpOnly `app_at` cookie automatically (`withCredentials: true`) — JS never holds the JWT; the interceptor attaches `X-CSRF-Token` (from cookie) and `Accept-Language` (from localStorage). The only Bearer header still built by hand is the short-lived scoped `email:verify` token on `/auth/email-verification/*` routes.
7. API responds `{ ok: true, data: { id, name, ... } }`
8. Axios response interceptor unwraps: returns `data` directly (or throws `AppError` on `{ ok: false }` / network error)
9. TanStack Query caches under `queryKeys.patients.detail(id)`; component re-renders with `entity` populated
10. `<DetailPageGuard isLoading={isLoading} error={error} entity={entity}>` decides: skeleton / error / not-found / children
11. On success → `ProfileHeader`, `EditableInfoGrid`, `AppTabs` render the content
12. On user edit → `useDetailPageController` updates local state, marks `isDirty=true`, debounces 1500ms → `useAutoSave` triggers `onSave(localData)` → `update.mutateAsync()` → repository PUT → on success: `setQueryData(detail(id), updated)` + `invalidateQueries(search())` + `showAutoSaved()`

---

## Patterns by Layer

### Entity (Domain)

```typescript
// modules/patients/domain/entities/Patient.ts
export type PatientStatus = "ACTIVE" | "INACTIVE";

export interface Patient {
  id: string;
  accountId: string;
  name: string;
  birthDate: string | null;     // ISO string from API; convert to Date only at render boundary
  status: PatientStatus;
  createdAt: string;
  updatedAt: string;
}

export interface CreatePatientInput { name: string; birthDate?: string | null; }
export interface UpdatePatientInput extends Partial<CreatePatientInput> {}
```

**Rules:** plain TS interfaces (not classes); dates as ISO strings (matches API DTO exactly); separate `Create*Input` (required) and `Update*Input` (all-optional with `| null` for clearable). Field names mirror backend response DTO 1:1.

### Repository Interface (Domain)

```typescript
// modules/patients/domain/repositories/PatientRepository.ts
import type { CrudRepository, BulkDeletable } from "@/core/domain/CrudRepository";

export interface PatientRepository
  extends CrudRepository<Patient, CreatePatientInput, UpdatePatientInput>,
    BulkDeletable {}
```

**Rules:** always extend `CrudRepository` (gives `list/listPaginated/getById/create/update/delete` for free); add `BulkDeletable` if `bulkDelete(ids)` exists; only add custom methods for relations (`linkContact`, `unlinkContact`, etc.).

### HTTP Repository (Infrastructure)

```typescript
// modules/patients/infrastructure/repositories/HttpPatientRepository.ts
export class HttpPatientRepository implements PatientRepository {
  async listPaginated(params: PaginationParams): Promise<PaginatedResponse<Patient>> {
    return httpClient.get<never, PaginatedResponse<Patient>>("/patients/search",
      { params: buildPaginationQuery(params) });
  }
  async getById(id: string): Promise<Patient> {
    return httpClient.get<never, Patient>(`/patients/${id}`);
  }
  async create(data: CreatePatientInput): Promise<Patient> {
    return httpClient.post<never, Patient>("/patients", data);
  }
  async update(id: string, data: UpdatePatientInput): Promise<Patient> {
    return httpClient.put<never, Patient>(`/patients/${id}`, data);
  }
  async delete(id: string): Promise<void> { await httpClient.delete(`/patients/${id}`); }
  async bulkDelete(ids: string[]): Promise<void> { await httpClient.delete("/patients/bulk", { data: { ids } }); }
}
```

**Rules:** every method has explicit return type; use `httpClient.<verb><never, ResponseType>(...)` (the `never` is request-body slot — Axios convention here); use `buildPaginationQuery(params)` to serialize search params.

### DI Registration (`core/di/repositories.ts`)

```typescript
import { HttpPatientRepository } from "@/modules/patients/infrastructure/repositories/HttpPatientRepository";
import type { PatientRepository } from "@/modules/patients/domain/repositories/PatientRepository";

export const repositories = {
  patient: new HttpPatientRepository() as PatientRepository,
  // ... other singletons
} as const;
```

**Rules:** singletons via the const object; type-cast to interface so consumers depend on the contract, not the impl; never `new HttpXxxRepository()` inside a hook or component — always go through `repositories`.

### Query Keys (`core/query/queryKeys.ts`)

```typescript
patients: {
  all: ["patients"] as const,
  list: () => [...queryKeys.patients.all, "list"] as const,
  search: () => [...queryKeys.patients.all, "search"] as const,
  detail: (id: string) => [...queryKeys.patients.all, "detail", id] as const,
  linkedContacts: (id: string) => [...queryKeys.patients.all, "linkedContacts", id] as const,
},
```

**Rules:** factory pattern (functions for parameterized keys); hierarchical (`all` is the root, narrow keys nest under it); **never** invalidate a broader key than necessary; **never** `queryClient.invalidateQueries()` without a `queryKey`.

### Hooks — Decision Tree (Reuse First)

**Paging default:** every list pages by 20, by infinite scroll (`useInfiniteListPage`, `useListPageController`, `useServerSearch` and the `SearchPicker`). Search on the server once a list is paged: a client filter misses what is not loaded. **Exceptions:** the agenda loads by month (a bounded window: the day modal reads the same data, and only its filters page); the knowledge base holds at most `KNOWLEDGE_BASE_MAX_DOCUMENTS_PER_ACCOUNT` (15), below one page; `useTags()`/`useWorkplaces()` remain bounded catalogs for what must resolve an id into a name or color.

| Need | Hook | Source |
|------|------|--------|
| Full list (no pagination) + optimistic delete | `useEntityList` | `shared/hooks/useEntityList.ts` |
| Paginated list with debounced search | `useServerListPage` (via `useInfiniteListPage`) | `shared/hooks/useInfiniteListPage.ts` |
| Full list page (search + bulk + delete confirm + create modal) | `useListPageController` | `shared/hooks/useListPageController.ts` |
| Patient tab list / sub-resource, 20 per page | `useServerSearch` + `useInfiniteScrollSentinel` inside `TabFillScroll` | `modules/records/presentation/hooks/useConsultations.ts` |
| Single entity CRUD | `useEntityDetail` | `shared/hooks/useEntityDetail.ts` |
| Detail page with auto-save (1500ms) + dirty + validation | `useDetailPageController` | `shared/hooks/useDetailPageController.ts` |
| Modal/standalone form (simple) | `useFormState` | `shared/hooks/useFormState.ts` |
| Validated form (login, register, complex) | `useForm` (RHF) + `zodResolver(buildXSchema())` | direct |
| Toast | `useNotify` (`showSuccess`, `showError`, `showInfo`, `showAutoSaved`) | `shared/hooks/useNotify.tsx` |
| Bulk selection state | `useBulkSelection` | `shared/hooks/useBulkSelection.ts` |
| Confirm dialog state | `useConfirm` | `shared/hooks/useConfirm.ts` |
| Unsaved-changes nav guard | `useUnsavedChangesGuard(isDirty)` | `shared/hooks/useUnsavedChangesGuard.ts` |
| Debounce a value | `useDebounce(value, 300)` | `shared/hooks/useDebounce.ts` |
| Centralized error handling | `useErrorHandler()` → `handleError(error, fallback)` | `core/query/useErrorHandler.ts` |

```typescript
// modules/patients/presentation/hooks/usePatient.ts (canonical)
export function usePatient(id?: string) {
  const base = useEntityDetail<Patient, CreatePatientInput, UpdatePatientInput>({
    id, repo: repositories.patient, keys: queryKeys.patients,
    errorMessages: errorMessages.crud("paciente"),
  });
  // Add custom relation queries/mutations here if needed (linkedContacts, etc.)
  return base;
}
```

### Page Component (Composition)

Pages own queries, controllers, modal state, and orchestration. Sub-components are dumb and receive `value`, `onChange`, `onClick`.

```typescript
export default function PatientsListPage() {
  const { t } = useTranslation("patients");
  const ctrl = useListPageController({
    queryKey: queryKeys.patients.search(),
    fetchFn: (params) => repositories.patient.listPaginated(params),
    deleteFn: (id) => repositories.patient.delete(id),
    bulkDeleteFn: (ids) => repositories.patient.bulkDelete(ids),
    entityLabel: { singular: t("entity"), plural: t("entityPlural") },
  });
  return <ListPageLayout {...ctrl} renderCard={(item) => <EntityCard ... />} />;
}
```

### UI Component (Dumb)

```typescript
interface EntityRowProps { title: string; onAction?: () => void; }

export const EntityRow = memo(function EntityRow({ title, onAction }: EntityRowProps) {
  return (
    <Box bg="bg.surface" p={4} borderWidth="1px" borderColor="border.subtle" borderRadius="lg">
      <Text color="text.primary">{title}</Text>
    </Box>
  );
});
```

**Rules:** `memo()` on anything rendered inside `.map()`; explicit Props interface (no inline types for repeated components); no queries here — receive data via props.

---

## Cross-Cutting Concerns

### Routing (`app/router/AppRouter.tsx`, `RoutePaths.ts`)

- **Config-based** with `lazy()` + `Suspense` for every route
- Guards: `ProtectedRoute` (requires auth), `PublicOnlyRoute` (redirects authenticated), `ModuleRoute` (checks module permission)
- All paths in `RoutePaths.ts` — never hardcode `"/patients/:id"` in a component; use `ROUTE_PATHS.patientDetail.replace(":id", id)`
- Wrap protected routes in `withAppShell()` (applies `AppShell` + `ProtectedRoute` + `RouteErrorBoundary`)

### HTTP Client (`core/http/httpClient.ts`)

- baseURL: `import.meta.env.VITE_API_URL || "/api"`, timeout 30s, `withCredentials: true` (httpOnly `app_at` session + refresh cookies)
- Request interceptor: the session cookie is sent automatically — no `Authorization` header for normal calls. Attaches CSRF header + `Accept-Language`; deletes `Content-Type` for `FormData` (browser sets boundary). The scoped `email:verify` Bearer is the sole exception (email-verification routes only). `getCsrfToken` is exported for the one non-Axios transport (the copilot SSE fetch).
- Response interceptor:
  - Success: unwraps `{ ok: true, data }` → returns `data`
  - 401: queues request, calls `/auth/refresh`, retries on success; on refresh failure clears auth + redirects to sign-in
  - Other failures: throws `AppError(message, code, statusCode, details)`
- All consumers (repositories) get the inner data already typed — never deal with `{ ok, data }` directly

### Forms

**Validated forms (auth, complex):** RHF + Zod with **lazy schema builders**:

```typescript
// modules/auth/domain/schemas.ts
export function buildRegisterSchema() {
  return z.object({
    name: z.string().trim().min(1, tAuth("register.nameRequired")),
    email: z.string().trim().email(tAuth("register.emailRequired")),
    password: z.string().refine(isPasswordStrong, { message: tAuth("register.passwordWeak") }),
  });
}
export type RegisterFormValues = z.infer<ReturnType<typeof buildRegisterSchema>>;

// In the page
const { register, handleSubmit, control, formState: { errors } } = useForm<RegisterFormValues>({
  resolver: zodResolver(buildRegisterSchema()),
  defaultValues: { name: "", email: "", password: "" },
  mode: "onSubmit",
});
```

**Why lazy builders:** `t()` is called when the form mounts, so error messages reflect the current language (i18n changes don't require remounting).

**Simple modals:** `useFormState` with manual validation:

```typescript
const { formData, setField, errors, validate, reset } = useFormState(
  { name: "", status: "ACTIVE" as const },
  { name: (v) => (!v ? tc("forms.required") : null) }
);
```

**Form primitives (`shared/components/forms/`):** Always reuse `FormField`, `SelectField`, `DateField`, `MultiSelectField`, `PasswordField`, `RichTextField`, `DocumentField`, `PhoneField`, `MonetaryField`, `NumberField`, `TextAreaField`, `ColorPicker`, `FileUploadField`, `SearchField`, `TimeField` — **do not** wrap raw Chakra `<Input>` in feature code.

### Modals

- Controlled by parent state via `useDisclosure()` from Chakra
- Wrap in `<AppModal isOpen onClose title primaryActionLabel onPrimaryAction isPrimaryLoading>` — gives standard footer (cancel + primary)
- **No** global modal store; **no** URL sync for modals (modals are ephemeral, not bookmarkable)
- Sticky headers on long modals; `size="md"` default, `"lg"` for forms with many fields

### Loading / Error / Empty States

| Surface | Use |
|---------|-----|
| Detail page | `<DetailPageGuard isLoading error entity skeletonVariant="profile" notFoundMessage>{children}</DetailPageGuard>` |
| List page | `<ListPageLayout isEmpty emptyTitle emptyDescription emptyActionLabel onEmptyAction />` |
| Section / card | `<SectionCardSkeleton />`, `<StatCardSkeleton />`, `<EntityCardSkeleton />` |
| Manual empty | `<EmptyState icon title description actionLabel onAction />` |
| Manual error | `useNotify().showError(error, fallback)` toast |
| Render error | `<RouteErrorBoundary>` (per route via `withAppShell`); `<GlobalErrorBoundary>` (root) |

**Never** use a bare `<Spinner />` for primary content — always a skeleton matching the target layout. **Never** show a blank area when there's no data — always `<EmptyState>` with helpful CTA.

### Mutations + Cache Invalidation

| Mutation | Cache Update | Invalidate |
|----------|--------------|-----------|
| **create** | `setQueryData(detail(newId), newEntity)` | `search()` |
| **update** | `setQueryData(detail(id), updated)` | `search()` |
| **delete (single)** | optimistic remove from `search()` (rollback on error) | `search()` on settled |
| **bulkDelete** | optimistic remove ids from `search()` | `search()` on settled |
| **linkRelation** | — | `linked{Related}(parentId)` |
| **unlinkRelation** | — | `linked{Related}(parentId)` |
| **saveFieldValues** | `setQueryData(fieldValues(entityId), values)` | — |

**Rules:**
- **Never** invalidate `all` — clears the whole entity tree, refetches everything, kills perf
- Use `setQueryData` for the entity you just mutated (instant UI)
- Use `invalidateQueries` for list/search keys (background refetch)
- On create → navigate to detail; the detail will already be in cache so no flash
- On delete from detail → navigate back to list

### Error Handling

- API errors arrive as `AppError(message, code, statusCode, details)` (interceptor wraps everything)
- In a mutation: `onError: (error) => handleError(error, fallback)` from `useErrorHandler()`
- `useNotify().showError(error)` extracts the message; for `code === "VALIDATION_ERROR"` flattens `details` into a readable string
- **Every mutation has an `onError`** — silent failures are bugs

### Optimistic Updates

`useEntityList` already implements optimistic delete:

```typescript
onMutate: async (deletedId) => {
  await queryClient.cancelQueries({ queryKey: keys.list() });
  const previous = queryClient.getQueryData<T[]>(keys.list());
  queryClient.setQueryData<T[]>(keys.list(), (prev) => prev?.filter((x) => x.id !== deletedId) ?? []);
  return { previous };
},
onError: (_err, _id, ctx) => { if (ctx?.previous) queryClient.setQueryData(keys.list(), ctx.previous); },
```

Use this pattern only when the operation is fast and rollback is cheap; otherwise prefer `invalidate-then-refetch` for correctness.

### Data-fetching scope, lazy mount, and prefetch

**Princípio:** o usuário só paga por dados que está prestes a ver.

1. **Lazy mount via tab boundary.** Toda `<AppTabs>` é lazy por default (`isLazy lazyBehavior="keepMounted"`). Componentes dentro de um painel de aba SÓ disparam queries quando o usuário clica naquela aba pela primeira vez (mantém montado depois — não refetch ao retornar). Opt-out (`isLazy={false}`) só com motivo documentado.

2. **Section-scoped fetch (não kitchen-sink).** Cada section/aba é responsável pelo próprio fetch. NÃO chamar hooks de relação no parent e passar dados por prop — quebra o lazy boundary. Padrão correto: `<LinkedContactsSection patientId={id} />` chama `usePatientLinkedContacts(id)` internamente. Modais auxiliares (`LinkEntityModal`) também devem viver dentro da section que os usa.

3. **Hooks focados (não kitchen-sink).** Hook de feature deve encapsular UMA query principal + suas mutations relacionadas. Se um hook tem >2 `useQuery` distintos, está virando kitchen-sink — quebrar em hooks menores. Aceitar `{ enabled }` opcional para callers fora de tab que precisam suspender manualmente (ex: `RecordDetailPage` chama `usePatient(id)` só pelo breadcrumb name).

4. **Prefetch on hover.** Em list pages, usar `usePrefetchEntity({ repo, keys })` para retornar `prefetch(id)`. Passar para `<EntityCard onHover={() => prefetch(item.id)}>`. Pre-aquece o cache no hover/focus — sem custo se o user não clicar (TanStack Query gerencia gc/stale, segundo prefetch dentro do staleTime é no-op).

5. **Stale tiers (`STALE_TIMES` em `core/query/staleTimes.ts`):**
   - `default: 60_000` — entidades transacionais (patient, contact, consultation). Match com o `queryClient` default; passar é opcional.
   - `reference: 5*60_000` — reference data (tags, templates, field-definitions). Mudam raramente, evita refetch agressivo. Já aplicado em `useTags` e `useTemplates`.
   - `volatile: 15_000` — dados muito dinâmicos (ai-usage stats, dashboards realtime).
   - `subscription: 30_000` — polling de status de assinatura (entre default e volatile).
   Hooks compartilhados (`useEntityList`, etc.) aceitam `staleTime?: number` opcional para escolher o tier.

6. **`gcTime` ≥ 3× `staleTime` (`GC_TIMES` em `staleTimes.ts`):** o `queryClient` default define `gcTime: 15min` enquanto o maior `staleTime` (`reference`) é `5min`. Por que importa: `gcTime` controla quando uma query INATIVA sai da memória. Se igualar ao `staleTime`, o cache é evictado no instante que vira stale — navegação away-and-back sempre refetcha. Use `GC_TIMES.x` quando um hook precisar sobrescrever ambos juntos. Anti-pattern `F-H23`.

7. **`useInfiniteQuery` com filtros: `placeholderData: keepPreviousData`.** Hooks que constroem `useInfiniteQuery` direto (sem passar pelo `useInfiniteListPage`) DEVEM declarar `placeholderData: keepPreviousData` quando o `queryKey` inclui filtros/search — caso contrário o grid colapsa pra skeleton em cada keystroke. `useInfiniteListPage` já cobre — hooks como `useAiUsageLogs`/`useTokenTransactions` precisam adicionar manualmente. Anti-pattern `F-H22`.

8. **Hooks de ações focados (mutations-only) para callers que não precisam da query.** Padrão definitivo: quando um caller só precisa de mutations (delete em ListPage, create em modal), consumir `useXActions()` / `useCreateX()` em vez de `useX({ enabled: false })`. Backbone compartilhado: `useEntityActions` e `useEntityCreate` em `shared/hooks/` — implementam mesma semântica de optimistic update + cross-key invalidation dos hooks com query. Pattern aplicado: `usePatientActions`, `useContactActions`, `useTagActions`, `useTemplateActions`, `useCreatePatient`, `useCreateContact`, `useDocumentTemplates`, `useKnowledgeBaseActions`. **Elimina observers fantasmas** (`entity.list` Fresh sem fetch, `entity.detail,null`) que poluíam o devtools com o pattern transicional `{ enabled: false }`. `F-M15`.

9. **`queryKey` factory com params na assinatura.** Quando uma query depende de filtros/paginação, os params DEVEM fazer parte da assinatura do factory em `queryKeys.ts` (ver `subscription.invoices`, `aiUsage.stats`, `aiUsage.search`). NUNCA estender o key inline via spread `[...queryKeys.X.Y(), params]` — quebra contrato. Anti-pattern `F-H21`.

10. **Query/mutation definida SEMPRE em hook — nunca inline no componente.** Todo `useQuery`/`useInfiniteQuery`/`useMutation` vive em `modules/<m>/presentation/hooks/` (ou `shared/hooks/` quando genuinamente cross-módulo) — componentes, páginas e contexts CONSOMEM hooks. Coreografia de UI acoplada ao ciclo da mutation (overlay de processamento, redirect) entra por callbacks do hook (`useCancelSubscription({ onFlowStart, ... })` em `subscription/hooks/useSubscriptionChange.ts` é o precedente). Por quê: definição inline esconde a superfície de server-state do módulo, deixa opções (staleTime/enabled/invalidations) divergirem por call site e não é testável isoladamente. Anti-pattern `F-H29`.

11. **Um hook canônico por resource key.** Cada query key tem UM dono — o hook que define `queryFn`/`enabled`/`staleTime` (ex.: `useWorkplaceMembers` para `workplaces.members`, `useWorkplaceSectors` para `workplaces.sectors`, `useTokenWallet` para `aiUsage.wallet`). Consumidores com necessidades diferentes derivam do dono (`useScheduleProfessionals` deriva via `useMemo`) ou passam opções sancionadas (`{ enabled }`, tier override). Segunda definição do mesmo key com opções divergentes = drift silencioso de cache (o TanStack deduplica a request, mas cada observer aplica o próprio staleTime/refetch). Exceção documentada: um segundo observer com `refetchInterval` próprio sobre um key de polling compartilhado (`useTranscriptionStatusPoll`) — comentar o porquê no hook. Anti-pattern `F-H30`.

**Anti-pattern (não fazer):**
- Hook que retorna `patient + linkedContacts + linkedTemplates + fieldValues` (kitchen sink) — quebrar em hooks focados.
- Parent page que chama `useTags()`, `useTemplates()`, `useConsultations()` no mount junto com o `useDetail` — mover para dentro das sections/sub-componentes que efetivamente consomem.
- `<AppTabs>` com `isLazy={false}` sem justificativa.
- `<EntityCard>` em list page sem `onHover` para prefetch (perde-se ganho gratuito de UX).
- Mutation que invalida `queryKeys.X.all` quando dá pra ser cirúrgica (`.byPatient(id)`, `.byMonth(year, month)`) — `F-C6`.

**Anchor codes:** `F-C6` (broad invalidation — Critical), `F-C20` (kitchen-sink hook — Critical), `F-H18` (eager AppTabs — High), `F-H19` (hook sem `enabled` opcional — High), `F-H20` (staleTime literal — High), `F-H21` (factory key extension — High), `F-H22` (placeholderData ausente em useInfiniteQuery — High), `F-H23` (gcTime ≤ staleTime — High), `F-H29` (query/mutation inline em componente — High), `F-H30` (resource key com N definições de query — High), `F-M13` (eager section fetch sem `enabled` — Medium), `F-M14` (prefetch sem staleTime matching — Medium), `F-M15` (ListPage duplica list+search — Medium).

### Auth

- `AuthContext` provides `{ user, isAuthenticated, isLoading, signIn, signUp, signOut, updateProfile, resetPassword }`
- `useAuth()` to read; the session JWT lives in the httpOnly `app_at` cookie — JS never sees or stores it (closes XSS→session theft). `AuthSession` carries only `{ user }`.
- After login, `i18n.changeLanguage(user.language)` is called automatically
- Token refresh handled transparently by `httpClient` interceptor (cookie-only)
- **Session-termination hygiene:** every sign-out path — explicit `signOut()` AND the token-expiry handler (`setAuthExpiredHandler`) — must both `queryClient.clear()` and wipe any browser-persisted, session-scoped data (e.g. `clearScheduleNotesStorage()`). A shared device must never leak one account's data to the next.

### i18n

- Namespaces: `common`, `auth`, `patients`, `contacts`, `records`, `templates`, `tags`, `settings`, `dashboard`, `copilot`, `aiUsage`, etc. (defined in `shared/i18n/index.ts` `NAMESPACES`)
- File per namespace per language: `shared/i18n/locales/{pt-BR,en,es}/{namespace}.json`
- Keys use **dot notation**: `"list.title"`, `"actions.save"`, `"register.nameRequired"`
- Interpolation: `t("crud.created", { entity: tc("entities.patient") })`
- Common keys (always available): `actions.*`, `status.*`, `entities.*`, `crud.*`, `errors.*`, `notify.*`, `list.*`, `forms.*`
- `useTranslation("{namespace}")` at component level; pass `t` and `tc` as separate consts when both are needed

**Rule:** every user-visible string is i18n. Adding any string requires entries in all **3** locale files.

---

## Styling System

**Absolute rule:** Chakra UI inline props only. **Never** CSS modules, styled-components, or external `.css` files.

### Semantic Tokens (mandatory — never hardcode hex)

| Category | Token | Light → Dark |
|----------|-------|--------------|
| Background | `bg.canvas` | `#f3f7fc` → `#0b1220` (page bg) |
| Background | `bg.surface` | `#ffffff` → `#121a2b` (card/panel) |
| Background | `bg.elevated` | `#ffffff` → elevated |
| Background | `bg.sunken` | `#f0f4f8` (inset) |
| Background | `bg.glass` | `rgba(255,255,255,0.80)` (frosted) |
| Text | `text.primary` | `#1f2937` → `#e6eaf2` |
| Text | `text.secondary` | `#4b5563` → `#a9b3c6` |
| Border | `border.subtle` | `rgba(15,23,42,0.07)` |
| Border | `border.default` | `rgba(15,23,42,0.12)` |
| Border | `border.strong` | `rgba(15,23,42,0.20)` |
| Status | `status.success.fg` | `green.600` → `green.300` |
| Status | `status.error.fg` | `red.600` → `red.300` |

Dark mode is automatic via `_dark` keys in the token definitions — **never** write color-mode conditionals (`useColorMode().colorMode === "dark" ? ... : ...`) in components.

### Color Palettes

| Palette | Usage |
|---------|-------|
| `brand` | Primary actions, links, focus rings (`colorScheme="brand"`) |
| `accent` | Success states, secondary actions (`colorScheme="accent"`) |
| `neutral` | Text, borders, backgrounds (slate scale) |
| `purple` | Warnings / attention states |

**Hard rule (user preference):** **NEVER use yellow or orange tones.** Use `purple` for warnings, `red` for errors, `green` (`accent`) for success. This applies to backgrounds, borders, text, badges, icons, gradients — everywhere.

### Shadows

`card`, `card-hover`, `panel`, `lg` (modals), `inner` (sunken), `brand-glow`, `accent-glow`, `input-focus`, `input-error`.

### Spacing

Chakra scale: `1` (4px), `2` (8px), `3` (12px), `4` (16px — standard gap), `6` (24px — section padding), `8` (32px — section margin).

### Responsive

Always responsive object syntax:

```tsx
<SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} gap={4}>
<Stack direction={{ base: "column", md: "row" }}>
<Text fontSize={{ base: "sm", md: "md" }}>
<Box display={{ base: "none", lg: "block" }}>
```

### Typography

Global font-size: `sm` (14px). FormLabel: `xs`, `600`, `gray.600`. Section heading: `sm`, `600`, `gray.700`.

### Animations (`shared/constants/animation.ts`)

- `EASE_ORGANIC = [0.22, 1, 0.36, 1]`
- `TRANSITION_FAST` (200ms), `TRANSITION_DEFAULT` (250ms), `TRANSITION_SLOW` (300ms)
- Components: `<FadeIn delay y>`, `<StaggerContainer staggerDelay>`, `<StaggerItem>`
- MotionBox pattern: `const MotionBox = motion(Box)`
- Card hover: `_hover={{ boxShadow: "card-hover", transform: "translateY(-2px)", borderColor: "brand.200" }}`
- Quick actions reveal: `<Flex opacity={0} _groupHover={{ opacity: 1 }} transition="opacity 0.15s ease">`
- Fetching state: `<Box opacity={isFetching ? 0.5 : 1} transition="opacity 0.15s ease">`

---

## Reuse-First Catalog

### Layout & Page-Level UI (`shared/components/ui/`)

| Component | Purpose |
|-----------|---------|
| `ListPageLayout` | Full list page (search + filter + grid + pagination + empty + delete confirm). Its header IS `PageHeader` (module `icon` + `tone` + `description`), with the search/filters as the card's second row |
| `PageHeader` | The ONE module header — list pages (via `ListPageLayout`), single-page modules and detail/editor screens: breadcrumb (inner screens only) + gradient icon tile (`tone`) + h1 with count pill / `titleMeta` badge + `metaItems` or `description` + `actions` (left of the primary) + optional `toolbar` row (the "with filters" state) + tone accent line; sticky (below the mobile top bar) |
| `AppTabs` | Tab nav within detail pages (optional URL sync) |
| `AppBreadcrumb` | Breadcrumb nav |
| `ProfileHeader` | Detail page header with avatar + meta + breadcrumbs |
| `EntityCard` | List card (avatar + title + badges + meta + actions + quick actions on hover) |
| `SectionCard` | Content section (variants: `default` / `glass` / `sunken`) |
| `StatCard` | Statistic display |
| `EntityAvatar` | Avatar with initials fallback |
| `StatusBadge` | Colored status badge |
| `TagBadge` | Tag display |
| `EmptyState` | Empty state with icon + title + description + CTA |
| `ActionMenu` | Dropdown 3-dot menu |
| `BulkActionBar` | Floating bar during bulk select |
| `ConfirmDialog` | Confirmation before destructive action |
| `AppModal` | Standard modal wrapper |
| `LinkEntityModal` | Generic link/search modal |
| `SaveButton` | Save with isDirty/isSaving |
| `EditableInfoGrid` | Grid of editable fields (text, date, select, textarea, readonly, document, phone) |
| `DataTable` | Generic table |
| `PaginationControls` | Pagination footer |
| `FilterBar` | Search + tag filter (or `inlineFilter`, same slot) + actions — the 44px bar of list pages |
| `compactControl` | The one measure of tab/toolbar headers: `COMPACT_CONTROL_HEIGHT`, `COMPACT_CONTROL_RADIUS`, `COMPACT_BUTTON_PROPS`, plus the filter popover surface. `SearchField variant="compact"` reads it |
| `FilterTrigger` / `InlineFilterTrigger` | The ONE filter trigger: standalone (compact) / inside the `FilterBar`. Never hand-roll one |
| `FilterPopover` | Surface of a filter without a search list (date range). Same 300px panel and eyebrow as `SearchPickerPopover` |
| `DateField` / `DateRangeCalendar` | The one date picker (`DateCalendar` = single day, `DateRangeCalendar` = range), both Chakra `DatePicker`. Never native selects or a second calendar lib. `CalendarPanel` is only for day/month navigation with marked days |
| `DetailPageGuard` | Loading/error/not-found wrapper for detail pages |

**Rule:** check this catalog **before** creating any new shared UI. Duplication is a defect.

### Skeletons (`shared/components/skeletons/`)

`ListPageSkeleton`, `DetailPageSkeleton` (`profile` / `two-column` / `single`), `EntityCardSkeleton`, `FilterBarSkeleton`, `SectionCardSkeleton`, `StatCardSkeleton`, `DashboardSkeleton`.

### Animations (`shared/components/animations/`)

`FadeIn`, `StaggerContainer`, `StaggerItem`.

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Component | `PascalCase.tsx` | `EntityCard.tsx` |
| Props | `{Component}Props` | `EntityCardProps` |
| Hook | `use{Name}.ts` | `usePatient.ts`, `usePatients.ts` |
| Entity | `{Entity}.ts` | `Patient.ts` |
| Repo interface | `{Entity}Repository.ts` | `PatientRepository.ts` |
| Repo impl | `Http{Entity}Repository.ts` | `HttpPatientRepository.ts` |
| Page | `{Feature}{Action}Page.tsx` | `PatientsListPage.tsx`, `PatientDetailPage.tsx` |
| i18n namespace | `{feature}.json` | `patients.json` |
| Constants | `UPPER_SNAKE_CASE` | `TRANSITION_DEFAULT` |

**Prefixes:** `use` (hooks), `on` (callback props: `onSubmit`, `onChange`), `handle` (internal handlers: `handleSubmit`), `is`/`has` (booleans: `isLoading`, `isDirty`, `hasErrors`).

**TypeScript:** interfaces for objects + props; types for unions/intersections/aliases; **no `any`** (use `unknown` and narrow); strict mode (no implicit any, no unchecked index access).

---

## Tests

Two layers, both live in this project:

- **Unit / component (Vitest + jsdom):** co-located `*.spec.ts(x)` next to the source (`yarn workspace @app/web test`). Cover pure utils, hooks, and component logic; mock at the repository boundary, never `httpClient`. This is the fast inner loop — a red `yarn test` blocks the PR.
- **E2E (Playwright):** in `apps/web/e2e/`, run only when `apps/web/**` changed. Details below.

### E2E (Playwright)

- **Location:** `apps/web/e2e/`
  - `tests/` — specs by module (`auth/`, `patients/`, `schedules/`, ...)
  - `pages/` — Page Objects (`LoginPage.ts`, `PatientsListPage.ts`, `components/Sidebar.ts`, ...)
  - `fixtures/` — `auth.fixture.ts` (auto-login), `api.fixture.ts` (data setup)
  - `global.setup.ts` — pre-test setup
- **Selectors priority:** `getByRole` > `getByLabel` > `getByText` > `getByPlaceholder` > `getByTestId` (last resort). **Never** CSS class selectors; **never** XPath.
- **Auth:** use the `auth.fixture` (`authenticatedPage`); never log in manually in each test
- **Data isolation:** unique data per test (timestamp/UUID); cleanup in `afterEach` / via API fixture
- **Waits:** `waitForURL`, `waitForSelector`, `expect().toBeVisible()` — never `waitForTimeout` except for explicit debounce (300ms search, 1500ms auto-save)

See `/test-e2e` skill for the full template.

---

## Adding a New CRUD Module — Order of Operations

1. **Entity type** — `modules/{feature}/domain/entities/{Entity}.ts`
2. **Repository interface** — `modules/{feature}/domain/repositories/{Entity}Repository.ts` (extends `CrudRepository`)
3. **HTTP repository** — `modules/{feature}/infrastructure/repositories/Http{Entity}Repository.ts`
4. **DI registration** — add to `core/di/repositories.ts`
5. **Query keys** — add namespace to `core/query/queryKeys.ts`
6. **List hook** — `modules/{feature}/presentation/hooks/use{Entities}.ts` (uses `useEntityList` or custom)
7. **Detail hook** — `modules/{feature}/presentation/hooks/use{Entity}.ts` (uses `useEntityDetail` + custom relations)
8. **List page** — `pages/{Feature}ListPage.tsx` (`useListPageController` + `ListPageLayout` + `EntityCard`)
9. **Create modal** — `components/{Entity}CreateModal.tsx` (`AppModal` + `useFormState` or RHF)
10. **Detail page** — `pages/{Feature}DetailPage.tsx` (`useDetailPageController` + `EditableInfoGrid` + `DetailPageGuard`)
11. **Route paths** — add to `app/router/RoutePaths.ts`
12. **Router** — add to `AppRouter.tsx` with `withAppShell()` + `lazy()`
13. **i18n** — create `shared/i18n/locales/{pt-BR,en,es}/{feature}.json`; register namespace in `shared/i18n/index.ts`
14. **Sidebar** — add nav item

**Canonical reference:** `modules/patients/` is the most complete module — copy its shape.

**Cross-reference:** see `.claude/patterns/code-review-checklist.md` for what gets flagged in review.
