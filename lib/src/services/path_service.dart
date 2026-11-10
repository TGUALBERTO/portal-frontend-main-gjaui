import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:result_dart/result_dart.dart';

import '../utils/utils.dart';

/// A service to easily access platform-specific file system locations.
class PathService {
  PathService._();
  static final PathService instance = PathService._();

  AsyncAppResult<Directory> getDocumentsDirectory() =>
      runTask(() => getApplicationDocumentsDirectory());

  AsyncAppResult<Directory> getTempDirectory() =>
      runTask(() => getTemporaryDirectory());

  AsyncAppResult<Directory> getAppSupportDirectory() =>
      runTask(() => getApplicationSupportDirectory());

  AsyncAppResult<Directory> getAppLibraryDirectory() =>
      runTask(() => getLibraryDirectory());

  /// External storage directory (Android only). Returns [CacheFailure]
  /// when unavailable on the current platform.
  AsyncAppResult<Directory> getExternalStorageDirectoryPath() async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        return const Failure(
          CacheFailure('External storage is not available on this platform'),
        );
      }
      return Success(dir);
    } catch (e, st) {
      AppLogger.error('getExternalStorageDirectory failed $e', [e, st]);
      return Failure(CacheFailure(AppErrorHandler.format(e), cause: e));
    }
  }
}
