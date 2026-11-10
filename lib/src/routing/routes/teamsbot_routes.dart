import 'package:gjamobile/src/features/teamsbot/atas/presentation/screens/ata_detalhe_screen.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/screens/ata_editor_screen.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/screens/atas_list_screen.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/presentation/screens/consulta_historico_screen.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/presentation/screens/consulta_screen.dart';
import 'package:gjamobile/src/features/teamsbot/custos/presentation/screens/custos_screen.dart';
import 'package:gjamobile/src/features/teamsbot/fila/presentation/screens/fila_screen.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/screens/reuniao_detalhe_screen.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/screens/reunioes_list_screen.dart';
import 'package:gjamobile/src/features/teamsbot/shell/responsive_shell.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';

int _teamsbotId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

/// TeamsBot (ATAs / RAG / custos / reuniões / fila).
final List<RouteBase> teamsbotRoutes = <RouteBase>[
  // Casca com navegação interna (ATAs / Consultar / Custos / Reuniões / Fila).
  ShellRoute(
    builder: (context, state, child) =>
        ResponsiveShell(location: state.uri.path, child: child),
    routes: [
      GoRoute(
        path: homeChild(AppRoutes.teamsbotAtas),
        name: 'teamsbot-atas',
        builder: (context, state) => const AtasListScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.teamsbotConsultar),
        name: 'teamsbot-consultar',
        builder: (context, state) => const ConsultaScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.teamsbotCustos),
        name: 'teamsbot-custos',
        builder: (context, state) => const CustosScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.teamsbotReunioes),
        name: 'teamsbot-reunioes',
        builder: (context, state) => const ReunioesListScreen(),
      ),
      GoRoute(
        path: homeChild(AppRoutes.teamsbotFila),
        name: 'teamsbot-fila',
        builder: (context, state) => const FilaScreen(),
      ),
    ],
  ),
  // Telas full-screen do TeamsBot (fora da casca).
  GoRoute(
    path: homeChild(AppRoutes.teamsbotConsultaHistorico),
    name: 'teamsbot-consulta-historico',
    builder: (context, state) => const ConsultaHistoricoScreen(),
  ),
  GoRoute(
    path: homeChild(AppRoutes.teamsbotAtaEditor),
    name: 'teamsbot-ata-editor',
    builder: (context, state) => AtaEditorScreen(id: _teamsbotId(state)),
  ),
  GoRoute(
    path: homeChild(AppRoutes.teamsbotAtaDetalhe),
    name: 'teamsbot-ata-detalhe',
    builder: (context, state) => AtaDetalheScreen(id: _teamsbotId(state)),
  ),
  GoRoute(
    path: homeChild(AppRoutes.teamsbotReuniaoDetalhe),
    name: 'teamsbot-reuniao-detalhe',
    builder: (context, state) => ReuniaoDetalheScreen(id: _teamsbotId(state)),
  ),
];
