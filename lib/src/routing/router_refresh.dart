import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';

/// Ponte signals -> [Listenable] para o `refreshListenable` do GoRouter:
/// reavalia os redirects quando o estado de sessão ou o vínculo de matrícula
/// mudam (ex.: /users/me carregou e o usuário precisa do fluxo KBA).
class RouterRefresh extends ChangeNotifier {
  RouterRefresh() {
    _cleanup = effect(() {
      // Lê os signals para assinar as mudanças.
      AppInjector.get<SessionController>().statusSignal.value;
      final access = AppInjector.get<AccessController>();
      access.statusSignal.value;
      access.needsEmployeeLinkSignal.value;
      notifyListeners();
    });
  }

  EffectCleanup? _cleanup;

  @override
  void dispose() {
    _cleanup?.call();
    super.dispose();
  }
}
