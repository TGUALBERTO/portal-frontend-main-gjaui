import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/auth/domain/entities/user.dart';
import 'package:gjamobile/src/utils/utils.dart';

abstract class AuthRepository {
  /// Stream of auth state changes. Emits [AppUser] when authenticated,
  /// `null` when not.
  Stream<AppUser?> get onAuthStateChanged;

  /// Starts the interactive Microsoft OAuth2 sign-in flow.
  AsyncAppResult<AppUser> signInWithMicrosoft();

  /// Sign out the current user (clears stored tokens).
  AsyncAppResult<Unit> logout();

  /// Restores the session from storage (refresh token flow). Returns
  /// [AuthFailure] when no valid session exists.
  AsyncAppResult<AppUser> checkAuthState();
}
