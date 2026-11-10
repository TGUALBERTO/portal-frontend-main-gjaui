import 'dart:async';

import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/app_update/app_update_config.dart';
import 'package:gjamobile/src/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:gjamobile/src/features/app_update/presentation/widgets/app_update_dialog.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Liga a atualização do app ao ciclo de vida da aplicação. Fica na cadeia de
/// wrappers do `MaterialApp.builder`, ao lado do `SessionListenerWrapper`.
///
/// - Ao abrir: consulta o canal depois do primeiro frame, sem atrasar o início.
/// - Achou atualização: mostra o diálogo **uma vez** por execução do app.
/// - Ao voltar para o primeiro plano: reconsulta em silêncio (o controller
///   respeita o intervalo mínimo). Só atualiza o estado — a entrada "Atualizar
///   app" aparece na Home, mas nenhum diálogo abre. O coletor fica dias sem
///   reiniciar, e um diálogo no meio de uma conferência é a interrupção que
///   esta feature não pode causar.
///
/// Fora do Android, e em build de debug, é só um repasse do [child].
class AppUpdateListener extends StatefulWidget {
  const AppUpdateListener({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends State<AppUpdateListener>
    with WidgetsBindingObserver {
  /// Espera entre a sessão ficar conhecida e o diálogo abrir. Nesse mesmo
  /// instante o `SessionListenerWrapper` faz `appRouter.go(...)` para a Home ou
  /// o login, e o go_router, ao trocar a página, remove as rotas sem página
  /// empilhadas sobre ela — o diálogo abriria e sumiria no frame seguinte.
  static const Duration _promptDelay = Duration(milliseconds: 800);

  AppUpdateController? _controller;
  EffectCleanup? _cleanup;
  Timer? _promptTimer;

  @override
  void initState() {
    super.initState();
    if (!AppUpdateConfig.isSupported) return;

    final controller = AppInjector.get<AppUpdateController>();
    final session = AppInjector.get<SessionController>();
    _controller = controller;

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.checkForUpdate());
    });

    _cleanup = effect(() {
      final shouldPrompt = controller.shouldPromptSignal.value;
      // Enquanto a sessão é desconhecida o splash nativo ainda está na tela.
      final sessionKnown = session.statusSignal.value != SessionStatus.unknown;
      if (shouldPrompt && sessionKnown) _schedulePrompt(controller);
    });
  }

  void _schedulePrompt(AppUpdateController controller) {
    if (_promptTimer != null) return;
    _promptTimer = Timer(_promptDelay, () {
      _promptTimer = null;
      if (!mounted || !controller.shouldPromptSignal.peek()) return;
      // Marca antes de abrir: é isso que garante "uma vez por execução", mesmo
      // que o diálogo seja fechado por uma troca de rota.
      controller.markPromptHandled();
      unawaited(showAppUpdateDialog());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller?.checkForUpdate());
    }
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _cleanup?.call();
    if (_controller != null) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
