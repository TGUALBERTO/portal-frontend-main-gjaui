import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/features/kba/presentation/screens/kba_flow_screen.dart';
import 'package:gjamobile/src/features/profile/presentation/screens/me_screen.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:gjamobile/src/routing/router_refresh.dart';
import 'package:gjamobile/src/routing/routes/bi_routes.dart';
import 'package:gjamobile/src/routing/routes/ga_routes.dart';
import 'package:gjamobile/src/routing/routes/helpdesk_routes.dart';
import 'package:gjamobile/src/routing/routes/inbound_routes.dart';
import 'package:gjamobile/src/routing/routes/portaria_routes.dart';
import 'package:gjamobile/src/routing/routes/rhprocesso_routes.dart';
import 'package:gjamobile/src/routing/routes/teamsbot_routes.dart';
import 'package:go_router/go_router.dart';

/// Redirect global do vínculo de matrícula (Dynamic KBA): autenticado e com o
/// /users/me carregado, quem precisa do fluxo fica preso em /vinculo; quem não
/// precisa não acessa /vinculo. UX-layer — o backend reforça em cada endpoint.
String? _kbaRedirect(BuildContext context, GoRouterState state) {
  final session = AppInjector.get<SessionController>();
  if (session.status != SessionStatus.authenticated) return null;

  final access = AppInjector.get<AccessController>();
  if (access.statusSignal.value != AccessStatus.loaded) return null;

  final location = state.uri.path;
  final needsLink = access.needsEmployeeLink;
  if (needsLink &&
      location != AppRoutes.kbaVinculo &&
      location != AppRoutes.login) {
    return AppRoutes.kbaVinculo;
  }
  if (!needsLink && location == AppRoutes.kbaVinculo) {
    return AppRoutes.home;
  }
  return null;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.login,
  redirect: _kbaRedirect,
  refreshListenable: RouterRefresh(),
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.kbaVinculo,
      name: 'kba-vinculo',
      builder: (context, state) => const KbaFlowScreen(),
    ),
    // A Home é a **raiz de navegação** do app: toda tela de feature é filha
    // dela. É isso que faz o Navigator empilhar Home → feature, e portanto o
    // botão voltar do Android desempilhar em vez de fechar o app — com as
    // rotas irmãs no topo (como era antes), `context.go` trocava a pilha
    // inteira e não sobrava nada para desempilhar.
    //
    // As constantes de `AppRoutes` continuam absolutas (é o que `context.go`
    // recebe e o que vai na barra de endereço); quem converte para o path
    // relativo que a filha exige é o `homeChild()` de cada arquivo de rotas.
    //
    // O `/login` fica de fora de propósito: é irmão da Home, não pai dela —
    // voltar da Home nunca pode cair na tela de login.
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
      routes: <RouteBase>[
        GoRoute(
          path: homeChild(AppRoutes.me),
          name: 'me',
          builder: (context, state) => const MeScreen(),
        ),
        ...gaRoutes,
        ...inboundRoutes,
        ...portariaRoutes,
        ...teamsbotRoutes,
        ...helpdeskRoutes,
        ...biRoutes,
        ...rhprocessoRoutes,
      ],
    ),
  ],
);
