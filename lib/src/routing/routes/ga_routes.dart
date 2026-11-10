import 'package:flutter/widgets.dart';
import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/feature.dart';
import 'package:gjamobile/src/features/access/domain/entities/module.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/access/presentation/screens/feature_edit_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/features_list_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/group_edit_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/groups_list_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/module_edit_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/modules_list_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/permissions_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/user_detail_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/user_groups_screen.dart';
import 'package:gjamobile/src/features/access/presentation/screens/users_list_screen.dart';
import 'package:gjamobile/src/features/integracoes/presentation/screens/integracoes_screen.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';

/// Guards the access-management subtree: non-admins are redirected home.
/// The backend enforces ADMIN on every endpoint; this is a UX-layer guard.
String? _gaAdminGuard(BuildContext context, GoRouterState state) {
  final isAdmin = AppInjector.get<AccessController>().isAdmin;
  return isAdmin ? null : AppRoutes.home;
}

/// Access management (GA) — admin only.
final List<RouteBase> gaRoutes = <RouteBase>[
  GoRoute(
    path: homeChild(AppRoutes.gaGroups),
    name: 'ga-groups',
    redirect: _gaAdminGuard,
    builder: (context, state) => const GroupsListScreen(),
  ),
  GoRoute(
    // Declared before ':id' so '/new' is not captured as an id.
    path: homeChild(AppRoutes.gaGroupNew),
    name: 'ga-group-new',
    redirect: _gaAdminGuard,
    builder: (context, state) => const GroupEditScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaGroupEdit),
    name: 'ga-group-edit',
    redirect: _gaAdminGuard,
    builder: (context, state) => GroupEditScreen(
      group: state.extra as AccessGroup?,
      groupId: state.pathParameters['id'],
    ),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaFeatures),
    name: 'ga-features',
    redirect: _gaAdminGuard,
    builder: (context, state) => const FeaturesListScreen(),
  ),
  GoRoute(
    // Declared before ':id' so '/new' is not captured as an id.
    path: homeChild(AppRoutes.gaFeatureNew),
    name: 'ga-feature-new',
    redirect: _gaAdminGuard,
    builder: (context, state) => const FeatureEditScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaFeatureEdit),
    name: 'ga-feature-edit',
    redirect: _gaAdminGuard,
    builder: (context, state) => FeatureEditScreen(
      feature: state.extra as Feature?,
      featureId: state.pathParameters['id'],
    ),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaModules),
    name: 'ga-modules',
    redirect: _gaAdminGuard,
    builder: (context, state) => const ModulesListScreen(),
  ),
  GoRoute(
    // Declared before ':id' so '/new' is not captured as an id.
    path: homeChild(AppRoutes.gaModuleNew),
    name: 'ga-module-new',
    redirect: _gaAdminGuard,
    builder: (context, state) => const ModuleEditScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaModuleEdit),
    name: 'ga-module-edit',
    redirect: _gaAdminGuard,
    builder: (context, state) => ModuleEditScreen(
      module: state.extra as Module?,
      moduleId: state.pathParameters['id'],
    ),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaUsers),
    name: 'ga-users',
    redirect: _gaAdminGuard,
    builder: (context, state) => const UsersListScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaUserDetail),
    name: 'ga-user-detail',
    redirect: _gaAdminGuard,
    builder: (context, state) => UserDetailScreen(
      user: state.extra as PortalUser?,
      userId: state.pathParameters['id'],
    ),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaUserGroups),
    name: 'ga-user-groups',
    redirect: _gaAdminGuard,
    builder: (context, state) => UserGroupsScreen(
      user: state.extra as PortalUser?,
      userId: state.pathParameters['id'],
    ),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaPermissions),
    name: 'ga-permissions',
    redirect: _gaAdminGuard,
    builder: (context, state) => const PermissionsScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gaIntegracoes),
    name: 'ga-integracoes',
    redirect: _gaAdminGuard,
    builder: (context, state) => const IntegracoesScreen(),
  ),
];
