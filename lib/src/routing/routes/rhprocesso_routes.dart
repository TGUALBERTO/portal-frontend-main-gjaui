import 'package:flutter/widgets.dart';
import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/rhprocesso_features.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/screens/caracteristicas_screen.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/screens/estrutura_screen.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/screens/parametros_screen.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/screens/volume_screen.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';

/// Guard por feature: sem leitura na [feature], volta para a Home. UX apenas —
/// a `rhprocesso-api` reforça a permissão em todo endpoint.
///
/// Enquanto o `/users/me` não chegou (deep-link, refresh na web) a rota fica:
/// o `RouterRefresh` reavalia o redirect quando o acesso carrega, e só então
/// quem não tem a feature é mandado para a Home.
///
/// [access] só nos testes; por padrão vem do DI.
GoRouterRedirect exigeFeatureRh(
  String feature, {
  AccessController Function()? access,
}) {
  return (BuildContext context, GoRouterState state) {
    final controle = (access ?? AppInjector.get<AccessController>)();
    final status = controle.statusSignal.value;
    if (status == AccessStatus.idle || status == AccessStatus.loading) {
      return null;
    }
    return controle.can(feature, PermissionAction.read) ? null : AppRoutes.home;
  };
}

/// RH Processo — uma tela por feature do RBAC.
final List<RouteBase> rhprocessoRoutes = <RouteBase>[
  GoRoute(
    path: homeChild(AppRoutes.rhVolume),
    name: 'rh-volume',
    redirect: exigeFeatureRh(RhprocessoFeatures.volume),
    builder: (context, state) => const VolumeScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.rhEstrutura),
    name: 'rh-estrutura',
    redirect: exigeFeatureRh(RhprocessoFeatures.estrutura),
    builder: (context, state) => const EstruturaScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.rhCaracteristicas),
    name: 'rh-caracteristicas',
    redirect: exigeFeatureRh(RhprocessoFeatures.caracteristicas),
    builder: (context, state) => const CaracteristicasScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.rhParametros),
    name: 'rh-parametros',
    redirect: exigeFeatureRh(RhprocessoFeatures.parametros),
    builder: (context, state) => const ParametrosScreen(),
  ),
];
