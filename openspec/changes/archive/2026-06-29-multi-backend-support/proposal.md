## Why

The app talks to a single backend reached through an edge proxy under the `/api`
path, with one global `Dio` and a base URL that hardcodes `/api`. We need the app
to talk to **multiple distinct backends at the same time** (e.g. a core/portal API
and a separate inbound/vehicles API), each reached **directly at its own host
(IP:port or DNS) at the root** — no `/api` prefix — so the frontend's own URL path
stays free for its (path-based) routes.

## What Changes

- Introduce a **fixed-in-code backend registry** (`BackendService`) listing every
  backend the app uses, with an env-specific host per backend and a base URL built
  at the **root** (no `/api`).
- **BREAKING**: remove the `/api` prefix and the host/`baseUrl` logic from
  `AppEnvironment`; `AppEnvironment` becomes environment-only (`label` + `secure`).
- **BREAKING**: replace the single `AppConfig.dio` / `AppConfig.baseUrl` with one
  `Dio` per backend (`AppConfig.dioFor(BackendService)`); `setEnvironment` updates
  every backend's base URL in place.
- Inject each repository's backend `Dio` via DI using typed marker wrappers
  (`CoreDio` / `InboundDio`); migrate the core repositories off `AppConfig.dio`.
- Remove the unused `DioService` singleton (bound to the old single `Dio`).
- Health check pings each registered backend at its root (`/actuator/health/ping`).
- Register `inbound` as a second backend with **placeholder** hosts (its concrete
  repository/controller wiring is a follow-up, out of scope here).
- Keep authentication unchanged: the single Microsoft login token is attached to
  every backend by the existing interceptor (assumes a shared Entra audience).

## Capabilities

### New Capabilities
- `backend-connectivity`: how the app resolves, builds and selects HTTP connections
  to its backends — a fixed registry of backends, one `Dio` per backend, direct
  root-host access (no `/api`), runtime environment switching across all backends,
  shared auth-token injection, and per-backend health checks.

### Modified Capabilities
<!-- None: existing specs (feature/group/permission/user-group) describe RBAC
     behavior, which is unchanged. This change only alters how repositories reach
     the backend, not the access requirements. -->

## Impact

- **New**: `lib/src/config/backend_service.dart`, `lib/src/services/backend_dio.dart`.
- **Modified**: `lib/src/config/app_environment.dart`, `lib/src/config/app_config.dart`,
  `lib/src/di/app_injector.dart`, the core repositories
  (`access_repository.dart`, `access_admin_repository.dart`,
  `backend_user_repository.dart`), `lib/src/services/backend_health_check.dart`,
  `lib/src/features/home/presentation/screens/home_page.dart`.
- **Removed**: `lib/src/services/dio_service.dart` (+ its barrel export).
- **Behavioral**: web calls become **cross-origin** (today they use a same-origin
  relative `/api`) — backends must return CORS headers and be served over HTTPS.
  Tracked together with the backend change `direct-access-drop-api`.
- **Auth**: all backends must accept the same Entra token (shared audience) or have
  the audience check disabled; no per-backend token acquisition is added.
