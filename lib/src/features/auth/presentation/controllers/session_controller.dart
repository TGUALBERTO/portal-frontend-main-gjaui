import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/auth/domain/entities/user.dart';
import 'package:gjamobile/src/features/auth/domain/repositories/auth_repository.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

/// Reactive session state powered by Signals. Owns the authenticated
/// [AppUser] and orchestrates [AccessController] loading on auth transitions
/// so callers only have to depend on session state.
class SessionController {
  SessionController({
    required AuthRepository repository,
    required AccessController accessController,
  })  : _repository = repository,
        _access = accessController;

  final AuthRepository _repository;
  final AccessController _access;
  StreamSubscription<AppUser?>? _authSub;

  late final Signal<SessionStatus> _status = signal(SessionStatus.unknown);
  late final Signal<AppUser?> _user = signal(null);
  late final Computed<bool> _isAuthenticated =
      computed(() => _status.value == SessionStatus.authenticated);

  ReadonlySignal<SessionStatus> get statusSignal => _status;
  ReadonlySignal<AppUser?> get userSignal => _user;
  ReadonlySignal<bool> get isAuthenticatedSignal => _isAuthenticated;

  SessionStatus get status => _status.value;
  AppUser? get user => _user.value;
  bool get isAuthenticated => _isAuthenticated.value;

  /// Bootstraps the session: checks current auth state, subscribes to the
  /// auth stream, and triggers an access load when authenticated.
  Future<void> init() async {
    final result = await _repository.checkAuthState();
    await result.fold(
      (u) async {
        _user.value = u;
        _status.value = SessionStatus.authenticated;
        await _access.load();
      },
      (_) async {
        _status.value = SessionStatus.unauthenticated;
      },
    );

    _authSub = _repository.onAuthStateChanged.listen((u) async {
      if (u != null) {
        _user.value = u;
        _status.value = SessionStatus.authenticated;
        await _access.load();
      } else {
        _user.value = null;
        _status.value = SessionStatus.unauthenticated;
        _access.clear();
      }
    });
  }

  Future<void> logout() async {
    await _repository.logout();
    _user.value = null;
    _status.value = SessionStatus.unauthenticated;
    _access.clear();
  }

  void dispose() {
    _authSub?.cancel();
    _status.dispose();
    _user.dispose();
    _isAuthenticated.dispose();
  }
}
