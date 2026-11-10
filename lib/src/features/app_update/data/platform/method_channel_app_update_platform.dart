import 'package:flutter/services.dart';

import 'package:gjamobile/src/features/app_update/app_update_config.dart';
import 'package:gjamobile/src/features/app_update/domain/services/app_update_platform.dart';

/// [AppUpdatePlatform] sobre o canal `com.gja.gjamobile/app_update`, implementado
/// em `android/app/src/main/kotlin/com/gja/gjamobile/MainActivity.kt`.
class MethodChannelAppUpdatePlatform implements AppUpdatePlatform {
  const MethodChannelAppUpdatePlatform();

  static const MethodChannel _channel =
      MethodChannel(AppUpdateConfig.methodChannel);

  @override
  Future<String> signerSha256() async {
    final digest = await _channel.invokeMethod<String>('signerSha256');
    if (digest == null || digest.isEmpty) {
      throw PlatformException(
        code: 'app_update_failed',
        message: 'signerSha256 voltou vazio',
      );
    }
    return digest.toLowerCase();
  }

  @override
  Future<void> installApk(String path) =>
      _channel.invokeMethod<void>('installApk', <String, Object?>{'path': path});
}
