# backend-connectivity Specification

## Purpose
Define how the app connects to multiple independent backends — a fixed build-time
registry, one HTTP client per backend with direct root-host base URLs, shared auth
token injection, environment switching, repository-to-backend binding, and per-backend
health checks.

## Requirements

### Requirement: Fixed backend registry

The app SHALL define every backend it connects to in a fixed, build-time registry
(`BackendService`). Each backend SHALL declare a stable identifier, a human-readable
label, and an absolute base URL (scheme + `host[:port]`) for each supported
environment. Backends MUST NOT be added or edited at runtime.

#### Scenario: Registry lists all backends
- **WHEN** the app enumerates `BackendService.values`
- **THEN** it returns every backend the app talks to (at minimum `core` and `inbound`)
- **AND** each backend exposes a base URL for every selectable environment

#### Scenario: Adding a backend is a code change
- **WHEN** a new backend must be supported
- **THEN** it is added as a new `BackendService` entry in code and shipped in a build
- **AND** no runtime UI or storage path can introduce a backend

### Requirement: Direct root-host base URLs without `/api`

Each backend's base URL SHALL be the configured absolute URL for the active
environment — scheme + `host[:port]` at the **root** of the host. The scheme is
per backend (an internal backend MAY be plain `http` on an `IP:port` while the
frontend runs over `https`). The base URL MUST NOT contain an `/api` prefix, any
other path prefix, or a trailing slash.

#### Scenario: Backend base URL is the configured absolute URL
- **WHEN** the base URL for a backend is resolved in an environment
- **THEN** it equals that backend's configured absolute URL (scheme + `host[:port]`)
  with no `/api` and no trailing slash

#### Scenario: Local environment base URL
- **WHEN** the base URL for `core` is resolved in the LOCAL environment
- **THEN** it equals `http://localhost:8080` (plain HTTP, root, no `/api`)

#### Scenario: Endpoint paths sit at the root
- **WHEN** a repository requests `/users/me` on the `core` backend
- **THEN** the request targets `<core-base-url>/users/me` (e.g. `https://<core-host>/users/me`)
- **AND** the path never includes `/api`

### Requirement: One HTTP client per backend

The app SHALL maintain a separate `Dio` instance per backend, retrievable by backend
identifier (`AppConfig.dioFor(service)`). All backend `Dio` instances SHALL be created
during initialization and remain stable for the app lifetime so that injected holders
keep valid references.

#### Scenario: Distinct clients per backend
- **WHEN** `AppConfig.dioFor(core)` and `AppConfig.dioFor(inbound)` are requested
- **THEN** they return different `Dio` instances, each with its own backend base URL

#### Scenario: Access before initialization fails fast
- **WHEN** `AppConfig.dioFor(...)` is called before `AppConfig.init()` has run
- **THEN** it raises a clear error rather than returning a null or default client

### Requirement: Environment switch updates every backend

Switching the active environment SHALL update the base URL of every backend's `Dio`
in place (without replacing the instances) and persist the selection so it survives
restarts.

#### Scenario: Switch updates all backends
- **WHEN** the active environment changes from QAS to PRD
- **THEN** every backend `Dio` base URL is updated to that backend's PRD host
- **AND** the same `Dio` instances are reused (not recreated)
- **AND** the chosen environment is persisted

#### Scenario: No-op when already active
- **WHEN** the environment is set to the value already active
- **THEN** no base URLs change and nothing is re-persisted

### Requirement: Shared auth token across backends

A request to any backend SHALL carry the user's Microsoft login token as a Bearer
`Authorization` header, refreshing the token when expired. The same token injection
SHALL apply uniformly to every backend; no per-backend token acquisition is performed.

#### Scenario: Token attached to every backend
- **WHEN** an authenticated request is sent to any registered backend
- **THEN** a valid (refreshed if needed) Bearer token is attached to it

#### Scenario: Unauthenticated request carries no token
- **WHEN** no valid session exists and a request is sent
- **THEN** no `Authorization` header is added

### Requirement: Repositories bound to their backend

Each repository SHALL receive, via dependency injection, the `Dio` for the backend it
belongs to. Core repositories (users, access, auth sync) SHALL be bound to the `core`
backend. The injection SHALL unambiguously distinguish backends so the container never
confuses one backend's client for another's.

#### Scenario: Core repository uses the core backend
- **WHEN** a core repository (e.g. access or backend-user repository) issues a request
- **THEN** it uses the `core` backend's `Dio`

#### Scenario: Backend clients are unambiguous to the container
- **WHEN** the DI container resolves a repository that needs a backend client
- **THEN** it injects the client for that repository's backend and no other

### Requirement: Per-backend health check

On startup the app SHALL probe each registered backend independently and report each
result without one backend's failure masking another's.

#### Scenario: Each backend probed at its root
- **WHEN** the startup health check runs
- **THEN** it pings `<backend-base-url>/actuator/health/ping` for each registered backend

#### Scenario: Failures are isolated and labeled
- **WHEN** one backend's health probe fails
- **THEN** the failure is logged labeled with that backend
- **AND** other backends are still probed and reported
