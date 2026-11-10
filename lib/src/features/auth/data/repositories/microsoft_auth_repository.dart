import 'dart:async';

import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/auth/data/repositories/backend_user_repository.dart';
import 'package:gjamobile/src/features/auth/domain/entities/user.dart';
import 'package:gjamobile/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gjamobile/src/services/microsoft_auth_result.dart';
import 'package:gjamobile/src/services/microsoft_auth_service.dart';
import 'package:gjamobile/src/services/token_storage.dart';
import 'package:gjamobile/src/utils/utils.dart';

class MicrosoftAuthRepository implements AuthRepository {
  MicrosoftAuthRepository({
    MicrosoftAuthService? service,
    TokenStorage? storage,
    BackendUserRepository? backendUserRepository,
  })  : _service = service ?? MicrosoftAuthService.instance,
        _storage = storage ?? TokenStorage.instance,
        // Falls back to the DI-managed instance (wired with its CoreDio) rather
        // than constructing one directly, which would lack the backend client.
        _backendUserRepository =
            backendUserRepository ?? AppInjector.get<BackendUserRepository>();

  final MicrosoftAuthService _service;
  final TokenStorage _storage;
  final BackendUserRepository _backendUserRepository;

  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get onAuthStateChanged => _authStateController.stream;

  @override
  AsyncAppResult<AppUser> signInWithMicrosoft() {
    return runTask(() async {
      final result = await _service.signIn();
      await _storage.save(result);
      final syncResult = await _backendUserRepository.sync();
      await syncResult.fold(
        (_) async => AppLogger.info('Backend user synced'),
        (failure) async {
          AppLogger.warning('Backend user sync failed: ${failure.message}');
          await _storage.clear();
          await _service.signOut();
          throw failure;
        },
      );
      final user = _toUser(result);
      _authStateController.add(user);
      return user;
    }, requiresNetwork: true);
  }

  @override
  AsyncAppResult<Unit> logout() {
    return runTask(() async {
      await _service.signOut();
      await _storage.clear();
      _authStateController.add(null);
      return unit;
    });
  }

  @override
  AsyncAppResult<AppUser> checkAuthState() {
    return runResultTask(() async {
      final saved = await _storage.read();
      if (saved == null) {
        return const AuthFailure('No session').toFailure<AppUser>();
      }
      var session = saved;
      if (saved.isExpired) {
        final refreshToken = saved.refreshToken;
        if (refreshToken == null) {
          await _storage.clear();
          return const AuthFailure('Session expired').toFailure<AppUser>();
        }
        final refreshed = await _service.refresh(refreshToken);
        if (refreshed == null) {
          await _storage.clear();
          return const AuthFailure('Session refresh failed')
              .toFailure<AppUser>();
        }
        await _storage.save(refreshed);
        session = refreshed;
      }
      // Ensure the backend has a user row for this session. The interactive
      // sign-in path syncs after sign-in, but a restored/refreshed session
      // never did — without this, GET /users/me 404s when the backend has no
      // record yet (e.g. fresh/reset DB). Sync is an idempotent upsert by
      // oid/sub. A transient sync failure here is logged but not fatal: we keep
      // the restored session for any non-auth failure (the common case) and let
      // AccessController.load surface a real error.
      final syncResult = await _backendUserRepository.sync();
      return syncResult
          .tap((r) => AppLogger.debug('Backend user sync on restore → $r'))
          .map((_) => _toUser(session))
          .recoverWhen(
            (failure) => failure is! AuthFailure,
            (_) => Success(_toUser(session)),
          );
    });
  }

  AppUser _toUser(MicrosoftAuthResult r) => AppUser(
        id: r.userId,
        email: r.email,
        name: r.name,
      );

  void dispose() => _authStateController.close();
}
