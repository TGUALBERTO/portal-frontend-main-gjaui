## 1. Backend registry

- [x] 1.1 Create `lib/src/config/backend_service.dart` with enum `BackendService { core, inbound }`, a const `Map<AppEnvironment, String>` host table per backend, `hostFor(env)`, and `baseUrlFor(env)` that builds the root URL (`https`/`http` from `env.secure`, no `/api`, no trailing slash)
- [x] 1.2 Seed `core` hosts (LOCAL `localhost:8080`, QAS `portal-qas.rebic.com.br`, PRD `portal.rebic.com.br`) and `inbound` placeholder hosts (mark with TODO to confirm real hosts/ports)

## 2. Environment becomes environment-only

- [x] 2.1 In `lib/src/config/app_environment.dart` remove `_host` and the entire `baseUrl` getter (drops `/api` and the web `servedByEdge` relative-path branch)
- [x] 2.2 Change the constructor to `const AppEnvironment(this.label, {this.secure = true})`; keep `label`, `secure`, `isDesktopOnly`, `available`, `fallback`, `fromName`; update the doc comments that describe `/api` edge routing

## 3. Multi-Dio AppConfig

- [x] 3.1 In `lib/src/config/app_config.dart` replace `static late final Dio dio` with `static final Map<BackendService, Dio> _dios` and add `static Dio dioFor(BackendService s)` that throws if accessed before `init()`
- [x] 3.2 Extract the auth interceptor (refresh + Bearer) and the Talker logger into private helpers
- [x] 3.3 In `init()` build one `Dio` per `BackendService.values`, each with `baseUrlFor(environment.value)`, the shared auth interceptor, and the logger (same enable condition as today)
- [x] 3.4 Change `setEnvironment(env)` to mutate every backend `Dio.options.baseUrl` in place (do not recreate instances) and persist the env; keep the early-return no-op
- [x] 3.5 Remove `static String get baseUrl`; optionally add a temporary `Dio get dio => dioFor(BackendService.core)` shim to migrate incrementally, removed at the end

## 4. DI wiring with marker wrappers

- [x] 4.1 Create `lib/src/services/backend_dio.dart` with `CoreDio` and `InboundDio` wrappers (`final Dio dio;`)
- [x] 4.2 In `lib/src/di/app_injector.dart` register `CoreDio(AppConfig.dioFor(BackendService.core))` and `InboundDio(AppConfig.dioFor(BackendService.inbound))` as instances

## 5. Migrate core repositories

- [x] 5.1 `lib/src/features/access/data/repositories/access_repository.dart`: inject `CoreDio`, replace `AppConfig.dio.*` with the injected client
- [x] 5.2 `lib/src/features/access/data/repositories/access_admin_repository.dart`: inject `CoreDio`, replace all (~24) `AppConfig.dio.*` calls
- [x] 5.3 `lib/src/features/auth/data/repositories/backend_user_repository.dart`: inject `CoreDio`, replace `AppConfig.dio.*` (`/users/sync`, `/users/me`)

## 6. Remove DioService

- [x] 6.1 Delete `lib/src/services/dio_service.dart` and remove its export from `lib/src/services/services.dart` (verify nothing references it)

## 7. Health check per backend

- [x] 7.1 In `lib/src/services/backend_health_check.dart` loop over `BackendService.values`, build a probe `Dio` from `service.baseUrlFor(env)`, ping `/actuator/health/ping` at the root, with isolated try/catch and a per-backend labeled log

## 8. Env-switcher UI

- [x] 8.1 In `lib/src/features/home/presentation/screens/home_page.dart` replace the removed `env.baseUrl` subtitle with per-backend URLs (`BackendService.core.baseUrlFor(env)` + `inbound`) or `env.label`

## 9. Tests

- [x] 9.1 Add a unit test for `BackendService.baseUrlFor` asserting root URL, no `/api`, and correct scheme (http for LOCAL, https for QAS/PRD)
- [x] 9.2 Add a DI smoke test asserting core repositories resolve with `CoreDio`

## 10. Verify

- [x] 10.1 `flutter analyze` is clean and `flutter test` passes
- [ ] 10.2 Run `flutter run -d chrome` against QAS and confirm in the Network tab that requests hit the absolute backend host at the root (e.g. `/users/me`, no `/api`) with the Bearer token attached, the env switcher updates all backends, and the health check pings each backend
