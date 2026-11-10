import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/entrada_saida_veiculo_mode.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/presentation/screens/entrada_saida_veiculo_screen.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';

/// Matrícula do usuário logado (vínculo funcional via KBA).
String _loggedUserMatricula() =>
    AppInjector.get<AccessController>().employeeLink?.matricula?.toString() ??
    '';

/// Portaria (entrada/saída de veículos).
final List<RouteBase> portariaRoutes = <RouteBase>[
  GoRoute(
    path: homeChild(AppRoutes.portariaEntradaVeiculo),
    name: 'portaria-entrada-veiculo',
    builder: (context, state) => EntradaSaidaVeiculoScreen(
      mode: EntradaSaidaVeiculoMode.R,
      matricula: _loggedUserMatricula(),
    ),
  ),
  GoRoute(
    path: homeChild(AppRoutes.portariaSaidaVeiculo),
    name: 'portaria-saida-veiculo',
    builder: (context, state) => EntradaSaidaVeiculoScreen(
      mode: EntradaSaidaVeiculoMode.S,
      matricula: _loggedUserMatricula(),
    ),
  ),
];
