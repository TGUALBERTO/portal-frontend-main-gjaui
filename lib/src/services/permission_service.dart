import 'package:permission_handler/permission_handler.dart';
import 'package:result_dart/result_dart.dart';

import '../utils/utils.dart';

/// A service to handle device permission requests and status checks.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  AsyncAppResult<PermissionStatus> checkStatus(Permission permission) {
    return runTask(() => permission.status);
  }

  AsyncAppResult<PermissionStatus> request(Permission permission) {
    return runTask(() => permission.request());
  }

  AsyncAppResult<Map<Permission, PermissionStatus>> requestMultiple(
    List<Permission> permissions,
  ) {
    return runTask(() => permissions.request());
  }

  /// Opens the OS app-settings page. The boolean payload is always `true` on
  /// success; a `false` result from the platform is surfaced as a [Failure]
  /// via `filter` so callers can react to "could not open settings".
  AsyncAppResult<bool> openSettings() {
    return runTask(() => openAppSettings()).filter(
      (opened) => opened,
      (_) => const UnknownFailure('Could not open app settings'),
    );
  }
}
