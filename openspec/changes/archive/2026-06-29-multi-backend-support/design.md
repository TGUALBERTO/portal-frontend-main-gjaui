## Context

Today the frontend reaches one backend through a single global `Dio`. The base URL is
computed by `AppEnvironment.baseUrl`, which hardcodes the `/api` prefix and has a
web-only branch that returns the same-origin relative path `/api` when served by the
edge (Traefik strips `/api` before forwarding to the backend). Every repository calls
`AppConfig.dio.*` directly; the `DioService` singleton wraps the same `Dio` but is
unused.

We now need the app to talk to **several distinct backends simultaneously**, each
reached **directly at its own host at the root** (no `/api`). The backend list is fixed
in code. Environments (LOCAL/QAS/PRD) still exist; each backend has an env-specific
host. Authentication stays as-is: the single Microsoft login token is attached to every
backend (assumes a shared Entra audience).

Constraints: `auto_injector` resolves constructor parameters **by type**, so two raw
`Dio` parameters are ambiguous. `setEnvironment` mutates the live `Dio` base URL in
place; the DI container holds references to the `Dio` instances.

## Goals / Non-Goals

**Goals:**
- A fixed, code-defined registry of backends, each with env-specific root hosts.
- One `Dio` per backend, selectable by identifier; env switch updates all of them.
- Repositories bound to their backend's `Dio` via DI, unambiguously.
- Remove `/api` from all URL construction.
- Per-backend startup health checks.
- Keep the existing single-token auth injection on every backend.

**Non-Goals:**
- Implementing the `inbound` backend's concrete repository/endpoints or registering its
  controller (placeholder only; follow-up).
- Per-backend token acquisition / multiple audiences.
- Runtime-configurable backend lists.
- Backend-side CORS/deploy changes (covered by the `direct-access-drop-api` change).

## Decisions

**1. `BackendService` enum holds a per-env host table.**
A const enum with a `Map<AppEnvironment, String>` host table and a `baseUrlFor(env)`
that builds the root URL. Enum + const map is the smallest "fixed in code" model and
mirrors the existing `AppEnvironment` shape. Alternative considered: a separate
`BackendDescriptor` class registry — more flexible (per-backend timeouts, health path)
but heavier than needed now; can be promoted later without changing call sites.

**2. `AppEnvironment` becomes environment-only.**
Remove `_host` and the entire `baseUrl` getter (where `/api` and the web relative-path
branch live). Keep `label`, `secure` (now only the scheme decider), `isDesktopOnly`,
`available`, `fallback`, `fromName`. Hosts move to `BackendService`. Rationale: a host
is now a property of a (backend, environment) pair, not of the environment alone.

**3. `AppConfig` holds `Map<BackendService, Dio>` + `dioFor(service)`.**
`init()` builds one `Dio` per backend with the same auth interceptor and logger;
`setEnvironment` mutates each `Dio.options.baseUrl` in place. Instances are never
replaced, so injected references stay valid. Alternative considered: recreate `Dio`s on
switch — rejected because the DI container caches the instances and would strand repos
on stale clients.

**4. Typed marker wrappers for DI (`CoreDio` / `InboundDio`).**
`auto_injector` resolves by type; two raw `Dio`s collide. Thin wrappers
(`class CoreDio { final Dio dio; }`) make the dependency explicit and mockable.
Alternatives considered: a `backendId` method parameter on every call (noisy,
error-prone) or repos calling `AppConfig.dioFor(...)` directly (couples repos to the
global, hard to test). Wrappers win on clarity and testability.

**5. Delete the unused `DioService` singleton.**
No repository uses it; they already wrap calls in `runTask`. Removing it avoids a second
path bound to the old single `Dio`. If a shared verb-wrapper is wanted later, make it
per-backend.

**6. Keep single-token auth.**
The existing interceptor (refresh + Bearer) is attached to every backend `Dio`. Per the
product decision, auth is handled only at login; no per-backend token work. This assumes
all backends accept the same Entra token.

## Risks / Trade-offs

- **Web cross-origin / mixed content** → Today web uses a same-origin relative `/api`
  (no CORS). Hitting absolute backend hosts at the root makes web calls cross-origin and
  requires HTTPS backends. Mitigation: the backend `direct-access-drop-api` change adds
  explicit CORS origins and serves backends over HTTPS; verify per host before PRD.
- **Shared audience assumption** → If a backend validates a different audience, the
  shared token is rejected. Mitigation: ensure all backends share the Entra audience or
  disable the audience check; otherwise scope a per-backend token follow-up.
- **Build breakage during migration** → Removing `AppConfig.dio`/`baseUrl` breaks every
  reference until migrated. Mitigation: migrate in one pass, or land an optional
  transitional `dio => dioFor(core)` shim and remove it at the end.
- **Mutate-in-place required** → `setEnvironment` must mutate, never replace, `Dio`
  instances. Mitigation: covered by a DI smoke test + the env-switch spec scenario.
- **Inbound placeholder hosts** → `inbound` hosts are placeholders; using it for real
  needs the actual hosts. Mitigation: marked TODO; concrete wiring is out of scope.
- **No existing tests** → No regression net. Mitigation: add a unit test for
  `BackendService.baseUrlFor` (root, no `/api`, scheme per env) and a DI smoke test.

## Migration Plan

1. Add `backend_service.dart` (additive, non-breaking).
2. Refactor `app_environment.dart` (drop `_host`/`baseUrl`) together with `app_config.dart`
   (multi-`Dio` + `dioFor`) and its consumers `home_page.dart` and `backend_health_check.dart`
   in one pass — they break together.
3. Add `backend_dio.dart` wrappers and wire them in `app_injector.dart`.
4. Migrate core repositories to the injected `CoreDio`.
5. Add the `inbound` registry entry (placeholder) and its `InboundDio` registration.
6. Update the health check to loop per backend.
7. Update the Home env-switcher subtitle (no longer reads the removed `env.baseUrl`).
8. Add the unit + DI smoke tests.

Rollback: revert the change set; the single-`Dio` + `/api` model is self-contained and
has no data migration.

## Open Questions

- Confirm the real `inbound` hosts/ports per environment before enabling it for real.
- Confirm all backends share the Entra audience (otherwise a per-backend token follow-up
  is required).
