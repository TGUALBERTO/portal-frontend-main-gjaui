## 1. Domain & Data

- [x] 1.1 Add `domain/entities/portal_user.dart` (`PortalUser` from `GET /users`: id, email, name?, givenName?, familyName?, preferredUsername?, createdAt?, lastLoginAt?) with `Equatable` + `fromJson`
- [x] 1.2 Add `domain/entities/user_group_summary.dart` (`UserGroupSummary{userId, email, name?}`) with `fromJson`
- [x] 1.3 Add `domain/entities/group_permission_draft.dart` (mutable: `Feature feature`, bool canCreate/Read/Update/Delete, `toRequest()` → `{featureId, canCreate, canRead, canUpdate, canDelete}`)
- [x] 1.4 Add `data/repositories/access_admin_repository.dart` group methods: `fetchGroups`, `createGroup`, `updateGroup`, `deleteGroup`(→Unit), `replacePermissions` — each via `runTask(..., requiresNetwork: true)`
- [x] 1.5 Add membership methods: `fetchGroupUsers`, `addUserToGroup`(→Unit), `removeUserFromGroup`(→Unit)
- [x] 1.6 Add feature methods: `fetchFeatures`, `createFeature`, `updateFeature`, `deleteFeature`(→Unit)
- [x] 1.7 Add user method: `fetchUsers`
- [x] 1.8 Register `AccessAdminRepository` as lazy singleton in `lib/src/di/app_injector.dart`
- [x] 1.9 Verify `lib/src/utils/task_runner.dart` surfaces Dio response-body messages for 409/400; add status-aware handling if missing (fixed `AppErrorHandler.format` to extract DioException body)

## 2. Controllers

- [x] 2.1 Extend `access_controller.dart`: add `isAdminSignal` computed (any group name == 'ADMIN', case-insensitive) + `isAdmin` getter + dispose it
- [x] 2.2 Add `groups_controller.dart` (app): `groups`/status/error signals; `load`, `delete`, `upsertLocal`
- [x] 2.3 Add `features_controller.dart` (app): `features`/status/error; `load`, `save`, `delete`
- [x] 2.4 Add `users_controller.dart` (app): `users`, `query`, `filtered` computed, status/error; `load`; build membership map `Map<userId, Set<groupId>>` from `fetchGroupUsers` over groups
- [x] 2.5 Add `group_edit_controller.dart` (screen-scoped, ctor `(repository, AccessGroup? initial)`): name/desc `TextEditingController` + form key; `matrix`, `members`, `saving`, status/error; `init`, `toggle(featureId, action)`, `save` (create/update → `replacePermissions`), `addMember`, `removeMember`; `dispose`
- [x] 2.6 Register `GroupsController`, `FeaturesController`, `UsersController` as lazy singletons in DI

## 3. Routing & Guard

- [x] 3.1 Add GA route constants to `lib/src/routing/app_routes.dart` (`gaGroups`, `gaGroupNew`, `gaGroupEdit`, `gaFeatures`, `gaUsers`, `gaPermissions`)
- [x] 3.2 Add `GoRoute`s in `lib/src/routing/app_router.dart` (declare `/ga/groups/new` before `/ga/groups/:id`; pass `AccessGroup` via `state.extra`) — deep-link to `/ga/groups/:id` without extra falls back to create-mode (no get-by-id endpoint; app always navigates with extra)
- [x] 3.3 Add `redirect` on each `/ga` route → home when `!AccessController.isAdmin`
- [x] 3.4 Wire `home_page._onFeaturePressed`: map `users`/`groups`/`features`/`permissions` to `context.push`; block non-admin with warning toast; keep snackbar default

## 4. Groups + Permission Matrix

- [x] 4.1 Build `groups_list_screen.dart` + `group_list_tile.dart` (list, "Novo grupo", edit/delete; disable destructive actions on ADMIN row)
- [x] 4.2 Wire delete with confirm dialog → toast (surface 409 for ADMIN)
- [x] 4.3 Build `group_edit_screen.dart` (StatefulWidget builds/dispose `GroupEditController`) with `group_form_section.dart` (name max120 required, description max500)
- [x] 4.4 Build `permission_matrix.dart` + `permission_matrix_row.dart` + `crud_chip.dart`: mobile cards (C/R/U/D chips, grouped by module, "Tudo"/"Limpar", feature search) and desktop `DataTable`, switched via `context.isMobile`
- [x] 4.5 Build `group_members_section.dart` + `add_member_sheet.dart` (edit-only; uses `fetchGroupUsers`, add/remove)
- [x] 4.6 Wire `save()` sequencing (group then permissions) + toast + `pop` + `GroupsController.upsertLocal`

## 5. Features

- [x] 5.1 Build `features_list_screen.dart` + `feature_list_tile.dart` (icon via `iconForFeature`, label/code/module; edit/delete)
- [x] 5.2 Build `feature_form_sheet.dart` via `show_app_sheet` (code required max80, label required max120, iconName dropdown max80, module dropdown + custom, required max80; surface 400/409 duplicate-code)
- [x] 5.3 Wire create/update/delete through `FeaturesController` with confirm + toast

## 6. Users & Assignment

- [x] 6.1 Build `users_list_screen.dart` + `user_list_tile.dart` with search bound to `UsersController.query`/`filtered`
- [x] 6.2 Build `user_groups_sheet.dart` (switch per group; initial checked-state from membership map; optimistic add/remove with rollback + toast on failure)

## 7. Permissions Screen

- [x] 7.1 Build `permissions_screen.dart`: group picker, then reuse `permission_matrix` for the selected group, save via `replacePermissions` + toast

## 8. Polish & QA

- [x] 8.1 Ensure every screen has loading (`AppLoading`), error (`AppErrorWidget` + retry), and empty (`AppEmptyState`) states
- [x] 8.2 Verify responsive behavior (matrix card↔table switch via `context.isMobile`, list layouts)
- [x] 8.3 Confirm 409/400 messages render meaningfully (`AppErrorHandler` now extracts Dio response body; ADMIN delete, duplicate code)
- [x] 8.4 Run `flutter analyze` and resolve issues (clean — "No issues found")
- [ ] 8.5 Manual smoke test as seeded admin (`igoroobbmm@gmail.com`): 4 GA buttons appear; exercise each CRUD path against backend on `:8080` — requires running app + backend (user-run)
