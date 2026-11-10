import 'package:app_version_update/data/models/app_version_result.dart';

import '../imports/imports.dart';

/// A service to check for app updates and manage version information using
/// the `app_version_update` package.
class VersionUpdateService {
  VersionUpdateService._();
  static final VersionUpdateService instance = VersionUpdateService._();

  /// Check if a newer version of the app is available in the store.
  AsyncAppResult<AppVersionResult> checkForUpdate({
    String? appleId,
    String? playStoreId,
  }) {
    return runTask(() async {
      return await AppVersionUpdate.checkForUpdates(
        appleId: appleId,
        playStoreId: playStoreId,
      );
    }, requiresNetwork: true);
  }

  /// High-level method to check for updates and show the dialog automatically if available.
  AsyncAppResult<Unit> checkAndShowUpdate({
    String? appleId,
    String? playStoreId,
    bool mandatory = false,
  }) {
    return runTask(() async {
      final result = await AppVersionUpdate.checkForUpdates(
        appleId: appleId,
        playStoreId: playStoreId,
      );

      if (result.canUpdate ?? false) {
        final context = rootContext;
        if (context == null) {
          AppLogger.warning('Cannot show update dialog: rootContext is null');
          return unit;
        }

        if (context.mounted) {
          AppVersionUpdate.showAlertUpdate(
            appVersionResult: result,
            context: context,
            mandatory: mandatory,
          );
        }
      }
      return unit;
    }, requiresNetwork: true);
  }

  /// Display a platform-specific update dialog.
  AsyncAppResult<Unit> showUpdateAlert({
    required AppVersionResult updateResult,
    bool mandatory = false,
    String? title,
    String? content,
    String? cancelText,
    String? updateText,
  }) {
    return runTask(() async {
      final context = rootContext;
      if (context == null) return unit;

      AppVersionUpdate.showAlertUpdate(
        appVersionResult: updateResult,
        context: context,
        mandatory: mandatory,
        title: title ?? 'New version available',
        content: content ?? 'Would you like to update your application?',
        cancelButtonText: cancelText ?? 'UPDATE LATER',
        updateButtonText: updateText ?? 'UPDATE',
      );
      return unit;
    });
  }

  /// Display a platform-specific update bottom sheet.
  AsyncAppResult<Unit> showUpdateBottomSheet({
    required AppVersionResult updateResult,
    bool mandatory = false,
    String? title,
    Widget? content,
  }) {
    return runTask(() async {
      final context = rootContext;
      if (context == null) return unit;

      AppVersionUpdate.showBottomSheetUpdate(
        appVersionResult: updateResult,
        context: context,
        mandatory: mandatory,
        title: title ?? 'New version available',
        content: content,
      );
      return unit;
    });
  }

  /// Display a dedicated update page.
  AsyncAppResult<Unit> showUpdatePage({
    required AppVersionResult updateResult,
    bool mandatory = false,
    Widget? page,
  }) {
    return runTask(() async {
      final context = rootContext;
      if (context == null) return unit;

      AppVersionUpdate.showPageUpdate(
        appVersionResult: updateResult,
        context: context,
        mandatory: mandatory,
        page: page,
      );
      return unit;
    });
  }
}
