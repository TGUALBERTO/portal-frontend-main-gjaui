## Context

The Flutter frontend (`portal-frontend`) consumes a Spring Boot backend (`portal-backend`) that already implements full admin RBAC: users, access groups, features, group→feature CRUD permissions, and user↔group membership. The frontend's `access` feature is scaffolded — domain entities (`AccessGroup`, `Feature`, `Permission`, `UserAccess`), a read-only `AccessRepository` hitting `/users/me`, an `AccessController`, and `feature_icon` utils — but has no screens.

The backend seeds four GA-module features (`users`, `groups`, `features`, `permissions`) and auto-grants the `ADMIN` group full CRUD on all of them (`AccessSeeder.java`). The home page already renders one button per readable feature grouped by module; tapping a GA button currently only shows a snackbar (`home_page.dart:96`). All admin endpoints require ADMIN-group membership and a Bearer JWT (auto-attached by the Dio interceptor in `AppConfig`).

Established conventions: clean per-feature architecture; `signals_flutter` for state; `runTask(() async {...}, requiresNetwork: true)` → `AsyncAppResult<T>` (`result_dart`) for data access; `auto_injector` DI; `go_router`; shared widgets (`AppPageScaffold`, `AppTopBar`, `AppCard`, `AppTextField`, `AppButton`, `AppEmptyState`, `AppErrorWidget`, `AppLoading`); helpers `show_toast.dart` / `show_app_sheet.dart`; responsive via `context.responsive<T>(...)`.

## Goals / Non-Goals

**Goals:**
- Build admin screens for groups (CRUD + permission matrix + members), features (CRUD), users (list + assignment), and a dedicated permissions screen.
- Reuse existing entities, patterns, widgets, and DI without adding dependencies.
- Gate the screens to ADMIN users (UX layer; backend already enforces).
- Keep the UI responsive and mobile-first, with a desktop-friendly permission matrix.

**Non-Goals:**
- No backend changes (no new endpoints, including a desirable `GET /users/{id}/groups`).
- No new state-management, HTTP, or DI libraries.
- No offline caching or pagination beyond what endpoints return.
- No editing of raw JWT claims or Microsoft Entra data.

## Decisions

**One repository for all admin endpoints (`AccessAdminRepository`).** Keeps the existing read-only `AccessRepository` (`/users/me`) untouched and groups all admin CRUD in one place mirroring `runTask`. Alternative — one repo per entity — adds files without benefit since they share the same Dio/runTask shape.

**One Signals controller per entity, plus a screen-scoped edit controller.** `GroupsController`, `FeaturesController`, `UsersController` are app-scoped lazy singletons so list data survives back-navigation. `GroupEditController` is parameterized by the group being edited, so it is built and disposed inside `GroupEditScreen` (not DI). Mirrors the granularity of the existing `AccessController`. Alternative — one mega-controller — was rejected for poor cohesion and harder disposal.

**Reuse `AccessGroup` for `GET /groups`.** Its `name` is non-nullable and `permissions` parse from the same `PermissionResponse` shape returned by both `/users/me` and `/groups`. New entities are added only where there is no model: `PortalUser` (`/users`), `UserGroupSummary` (`/groups/{id}/users`), and a mutable `GroupPermissionDraft` (matrix editing — `Permission` is immutable).

**Admin detection from existing data.** `AccessController` already holds the user's groups from `/users/me`; add `isAdmin = computed(() => groups.any((g) => g.name.toUpperCase() == 'ADMIN'))`. No extra network call. Guarding is two-layer: `home_page._onFeaturePressed` blocks with a toast, and a `go_router` `redirect` on the `/ga` subtree sends non-admins home.

**Navigate by feature code, not a hub.** Since the four GA features are separate buttons on the home page, `_onFeaturePressed` switches on `featureCode` (`users`/`groups`/`features`/`permissions`) and pushes the matching route. No separate hub screen is introduced.

**Permission matrix: one model, two presentations.** A single `List<GroupPermissionDraft>` backs both a mobile card layout (four C/R/U/D `FilterChip`s per feature, grouped by module, no horizontal scroll) and a wide `DataTable` (CRUD checkbox columns), chosen via `context.responsive`. Save uses `PUT /groups/{id}/permissions` (full replace), sending only features with at least one flag enabled.

**Group create then permissions.** Because permission and membership endpoints require a group id, `GroupEditController.save()` creates/updates the group first, then calls `replacePermissions`; the members section is hidden until the group exists.

## Risks / Trade-offs

- **No `GET /users/{id}/groups`** → To show a user's current memberships in the assignment picker, aggregate `GET /groups/{id}/users` across all groups into a `Map<userId, Set<groupId>>` on Users-screen load. This is N calls; acceptable at current scale. Mitigation/follow-up: request a backend endpoint.
- **Full-replace permission semantics** → Omitting a feature removes the group's permission on it. Mitigation: send every feature that has ≥1 flag enabled and treat omission as removal; verify against backend before shipping the matrix save.
- **ADMIN group protection (409 on delete, likely rename/permission limits)** → Disable destructive actions on the ADMIN row and surface backend 409 messages via toast.
- **Error message surfacing** → `runTask` collapses errors to `ServerFailure(message)`; verify `lib/src/utils/task_runner.dart` extracts the Dio response body so 409/400 (duplicate code, ADMIN delete) show meaningful text, else add status-aware handling.
- **Optimistic membership toggles** → On failure, revert the local switch and toast; avoids stale UI.
- **Void (204) endpoints** → Return `Unit`/`unit` from `result_dart` so `runTask<T extends Object>` is satisfied.

## Open Questions

- Exact `iconName` vocabulary for the feature form's icon dropdown — derive from `feature_icon.dart`'s known keys, or allow free text?
- Should the standalone `permissions` screen and the group-edit matrix share one route/widget, or remain separate entry points (current decision: separate screens, shared matrix widget)?
- Confirm backend treats an omitted feature in `PUT /permissions` as removal (assumed yes).
