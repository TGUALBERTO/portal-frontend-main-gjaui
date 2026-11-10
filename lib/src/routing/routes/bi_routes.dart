import 'package:gjamobile/src/features/bi/capacity/presentation/screens/capacity_screen.dart';
import 'package:gjamobile/src/features/bi/company/presentation/screens/company_screen.dart';
import 'package:gjamobile/src/features/bi/executive/presentation/screens/executive_screen.dart';
import 'package:gjamobile/src/features/bi/quality/presentation/screens/quality_screen.dart';
import 'package:gjamobile/src/features/bi/sap/presentation/screens/sap_screen.dart';
import 'package:gjamobile/src/features/bi/shell/bi_em_breve_screen.dart';
import 'package:gjamobile/src/features/bi/shell/bi_shell.dart';
import 'package:gjamobile/src/features/bi/sla_backlog/presentation/screens/sla_backlog_screen.dart';
import 'package:gjamobile/src/features/bi/team/presentation/screens/team_screen.dart';
import 'package:gjamobile/src/features/bi/tipo_chamado/presentation/screens/tipo_chamado_screen.dart';
import 'package:gjamobile/src/features/bi/user/presentation/screens/user_screen.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

// ── BI (Business Intelligence) ────────────────────────────────────────────
// Casca com a barra lateral dos dashboards. Executive já implementado; os
// demais itens abrem um placeholder "Em breve" até a tela existir (§17.2).
final List<RouteBase> biRoutes = <RouteBase>[
  ShellRoute(
    builder: (context, state, child) =>
        BiShell(location: state.uri.path, child: child),
    routes: [
      GoRoute(
        path: homeChild(AppRoutes.biExecutive),
        name: 'bi-executive',
        builder: (context, state) => const ExecutiveScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biCompany),
        name: 'bi-company',
        builder: (context, state) => const CompanyScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biIncidents),
        name: 'bi-incidents',
        builder: (context, state) => const TipoChamadoScreen(
          path: '/dashboards/incidents',
          titulo: 'Incidentes',
          subtitulo: 'Volume, tendência e SLA de incidentes',
          icon: GjaIcons.warning,
        ),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biRequests),
        name: 'bi-requests',
        builder: (context, state) => const TipoChamadoScreen(
          path: '/dashboards/requests',
          titulo: 'Requisições',
          subtitulo: 'Volume, tendência e SLA de requisições',
          icon: GjaIcons.task,
        ),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biImprovements),
        name: 'bi-improvements',
        builder: (context, state) =>
            const BiEmBreveScreen(titulo: 'Melhorias e Projetos'),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biSla),
        name: 'bi-sla',
        builder: (context, state) => const SlaBacklogScreen(),
      ),
      // "Backlog e Aging" foi unificado em "SLA e Backlog" (Grafico3.png). A
      // rota antiga continua válida (feature `bi_backlog`) e redireciona para a
      // tela única.
      GoRoute(
        path: homeChild(AppRoutes.biBacklog),
        name: 'bi-backlog',
        redirect: (context, state) => AppRoutes.biSla,
      ),
      GoRoute(
        path: homeChild(AppRoutes.biCapacity),
        name: 'bi-capacity',
        builder: (context, state) => const CapacityScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biSap),
        name: 'bi-sap',
        builder: (context, state) => const SapScreen(),
      ),
      // "Multiplataforma" foi unificado em "SAP e Multiplataforma" (Grafico4.png).
      // A rota antiga continua válida (feature `bi_multiplataforma`) e redireciona
      // para a tela única.
      GoRoute(
        path: homeChild(AppRoutes.biMultiplataforma),
        name: 'bi-multiplataforma',
        redirect: (context, state) => AppRoutes.biSap,
      ),
      GoRoute(
        path: homeChild(AppRoutes.biChange),
        name: 'bi-change',
        builder: (context, state) => const TipoChamadoScreen(
          path: '/dashboards/change',
          titulo: 'Mudanças/GMUD',
          subtitulo: 'Volume, tendência e SLA de mudanças',
          icon: GjaIcons.journeyChange,
        ),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biQuality),
        name: 'bi-quality',
        builder: (context, state) => const QualityScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biTeam),
        name: 'bi-team',
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biUser),
        name: 'bi-user',
        builder: (context, state) => const UserScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biUserDetail),
        name: 'bi-user-detail',
        builder: (context, state) => UserScreen(
          userId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biDesenvolvimento),
        name: 'bi-desenvolvimento',
        builder: (context, state) =>
            const BiEmBreveScreen(titulo: 'Desenvolvimento'),
      ),
      GoRoute(
        path: homeChild(AppRoutes.biRiscos),
        name: 'bi-riscos',
        builder: (context, state) =>
            const BiEmBreveScreen(titulo: 'Riscos e Recomendações'),
      ),
    ],
  )
];
