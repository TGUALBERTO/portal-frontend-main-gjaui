## Why

The `portal-backend` already exposes a complete admin RBAC API (groups, features, permissions, user-group membership), and the Flutter frontend has the access feature scaffolded (domain entities, a read-only `/users/me` repository, and `AccessController`) — but there are **no admin screens**. An ADMIN user logging in sees up to four "Gestão de Acesso (GA)" buttons on the home page (`users`, `groups`, `features`, `permissions`), yet tapping any of them only shows an "em breve" snackbar. This change builds the admin UI so administrators can actually manage access from the portal.

## What Changes

- Add an admin data layer `AccessAdminRepository` calling all backend admin endpoints (groups CRUD, group permission replace, group membership add/remove, features CRUD, users list).
- Add domain entities for admin reads not yet modeled: `PortalUser` (`GET /users`), `UserGroupSummary` (`GET /groups/{id}/users`), and a mutable `GroupPermissionDraft` for editing the permission matrix.
- Add Signals controllers: `GroupsController`, `FeaturesController`, `UsersController` (app-scoped), `GroupEditController` (screen-scoped), and extend `AccessController` with an `isAdmin` computed.
- Add responsive screens routed per GA feature code: Groups list + group edit (name/description, permission matrix, members), Features list + form, Users list + assign-to-group, and a Permissions screen (group picker + matrix).
- Add GA routes, a `/ga` admin redirect guard, and wire `home_page._onFeaturePressed` to navigate by feature code instead of showing a snackbar.
- Register the new repository and app-scoped controllers in `app_injector.dart`.
- No backend changes. No breaking changes — purely additive on the frontend.

## Capabilities

### New Capabilities
- `group-management`: Admin list, create, edit, and delete access groups (ADMIN group protected from deletion).
- `permission-management`: Admin edit of a group's CRUD permissions per feature via a responsive permission matrix (full-replace save).
- `feature-management`: Admin list, create, edit, and delete features.
- `user-group-assignment`: Admin list of portal users and assigning/removing users to/from groups (group members view + per-user group picker).

### Modified Capabilities
<!-- None — no existing specs in openspec/specs/; behavior is purely additive. -->

## Impact

- **Frontend code** (`portal-frontend`): new files under `lib/src/features/access/{data,domain,presentation}/`; edits to `lib/src/routing/app_routes.dart`, `lib/src/routing/app_router.dart`, `lib/src/di/app_injector.dart`, `lib/src/features/home/presentation/screens/home_page.dart`, and `lib/src/features/access/presentation/controllers/access_controller.dart`.
- **Backend**: none (existing endpoints consumed; all require ADMIN group + Bearer JWT).
- **Dependencies**: none added — reuses `dio`, `signals_flutter`, `result_dart`, `auto_injector`, `go_router`, shared widgets, and theme already in the project.
- **Auth/security**: screens gated by `isAdmin` (ADMIN group membership) + GoRouter redirect; backend enforces ADMIN regardless.
