import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gjamobile/src/imports/packages_imports.dart';

class SessionListenerWrapper extends StatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  State<SessionListenerWrapper> createState() => _SessionListenerWrapperState();
}

class _SessionListenerWrapperState extends State<SessionListenerWrapper> {
  EffectCleanup? _cleanup;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cleanup != null) return;

    final session = AppInjector.get<SessionController>();
    _cleanup = effect(() {
      final status = session.statusSignal.value;
      if (status == SessionStatus.unknown) return;

      FlutterNativeSplash.remove();
      if (!mounted) return;

      if (status == SessionStatus.authenticated) {
        appRouter.go(AppRoutes.home);
      } else {
        appRouter.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _cleanup?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
