import 'package:result_dart/result_dart.dart';

import '../imports/core_imports.dart';

/// Runs an async [action] and maps exceptions to an [AppFailure] inside a
/// `result_dart` [Result]. When [requiresNetwork] is `true` and connectivity
/// is unavailable, returns a [NetworkFailure] without executing [action].
AsyncAppResult<T> runTask<T extends Object>(
  Future<T> Function() action, {
  bool requiresNetwork = false,
}) async {
  if (requiresNetwork) {
    final hasNetwork = await InternetConnectionService().hasConnection();

    if (!hasNetwork) {
      AppLogger.warning('Network unavailable for task');
      showGlobalToast(
        message:
            'No internet connection. Please check your connection and try again.',
        status: 'warning',
      );
      return const Failure(
        NetworkFailure(
          'No internet connection. Please check your connection and try again.',
        ),
      );
    }
  }

  try {
    final result = await action();
    // NOTE: a plain `Success(...)` constructor (not the `.toSuccess()`
    // extension) — `runResultTask` feeds an `AppResult` as `T`, and the
    // extension asserts the receiver is not already a `Result`.
    return Success(result);
  } catch (error, stackTrace) {
    AppLogger.error('Task execution failed', error, stackTrace);
    // mapError preserva a semântica HTTP (ApiFailure com status, NetworkFailure
    // em falhas de conexão) além de extrair a mensagem legível.
    return Failure(AppErrorHandler.mapError(error));
  }
}

/// Like [runTask], but for actions that already return an [AppResult].
///
/// The nested `Result<Result<T>>` produced by wrapping the action is collapsed
/// with `flatten()`, so a [Failure] returned by [action] is preserved as-is and
/// any thrown error is still mapped to a [ServerFailure].
AsyncAppResult<T> runResultTask<T extends Object>(
  Future<AppResult<T>> Function() action, {
  bool requiresNetwork = false,
}) =>
    runTask<AppResult<T>>(action, requiresNetwork: requiresNetwork).flatten();
