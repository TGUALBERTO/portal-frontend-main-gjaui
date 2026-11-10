import 'dart:async';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/app.dart';
import 'src/di/app_injector.dart';
import 'src/features/auth/presentation/controllers/session_controller.dart';
import 'src/imports/core_imports.dart';
import 'src/services/backend_health_check.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Web: usa path no lugar do hash (dominio/ga/groups em vez de
  // dominio/#/ga/groups). No-op em mobile/desktop.
  usePathUrlStrategy();

  // Web: o menu de contexto do browser abriria por cima dos menus do app (o
  // botão direito nos apontamentos do Timesheet, por exemplo).
  if (kIsWeb) BrowserContextMenu.disableContextMenu();

  // Formatação de datas em pt_BR (intl)
  await initializeDateFormatting('pt_BR');

  // O Hive precisa estar pronto antes de AppConfig.init: ele lê o ambiente de
  // backend persistido para construir o Dio com a URL base correta.
  await HiveService.instance.init();
  await AppConfig.init();

  unawaited(runBackendHealthPing());

  AppInjector.setup();

  // Eagerly resolve the session controller and kick off its bootstrap so the
  // auth state check starts before the first frame. The splash is removed
  // reactively from SessionListenerWrapper once the status is known.
  unawaited(AppInjector.get<SessionController>().init());

  runApp(
    const StateWrapper(
      child: App(),
    ),
  );
}
