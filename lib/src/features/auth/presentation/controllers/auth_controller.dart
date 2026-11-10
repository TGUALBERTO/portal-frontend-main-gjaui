import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';

/// Controller for the login screen. Exposes a reactive [isLoadingSignal]
/// and a single intent: sign in with Microsoft.
class AuthController {
  AuthController({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  final _isLoading = signal(false);
  ReadonlySignal<bool> get isLoadingSignal => _isLoading;

  Future<void> signInWithMicrosoft({required BuildContext context}) async {
    _isLoading.value = true;
    final result = await _repository.signInWithMicrosoft();
    _isLoading.value = false;

    result.onSuccess((_) {
      if (context.mounted) GoRouter.of(context).go(AppRoutes.home);
    }).onFailure((failure) {
      if (!context.mounted) return;
      showToast(context, message: failure.message, status: 'error');
    });
  }

  void dispose() => _isLoading.dispose();
}
