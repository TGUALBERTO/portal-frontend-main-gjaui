import 'dart:async';

import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/app_update/data/repositories/app_update_repository.dart';
import 'package:gjamobile/src/features/app_update/domain/entities/app_release.dart';
import 'package:gjamobile/src/features/app_update/domain/services/app_update_platform.dart';
import 'package:gjamobile/src/utils/utils.dart';

const String sha256A =
    '1d83b022381fd262ad9fcdca221dfeee2466682e1174fb531a02abceb757f1c0';
const String signerPipeline =
    'b6c1fd79b07d23b4007bfde02d9369ead41d89c58425306bbe08406ac5c09afa';
const String signerDebug =
    '378c32034fc4ff951080cf2aae48c7a7443c03bebbcccd2a00baaf0cfc863ef4';

/// Um build publicado, no formato do `latest.json` do pipeline.
AppRelease release({
  int versionCode = 120,
  String versionName = '2026.10.03.09.15',
  String? signerSha256 = signerPipeline,
}) =>
    AppRelease(
      versionCode: versionCode,
      versionName: versionName,
      apkFileName: 'gjamobile-$versionName.apk',
      sizeBytes: 84000000,
      sha256: sha256A,
      signerSha256: signerSha256,
    );

/// Repositório em memória. Cada resposta é um campo que o teste ajusta.
class FakeAppUpdateRepository implements AppUpdateRepository {
  AppResult<AppRelease> latest = Success(release());
  int fetchCount = 0;

  /// Caminho de um APK "já baixado", ou `null`.
  String? cachedPath;

  AppResult<String> downloadResult =
      const Success('/cache/app_update/gjamobile.apk');
  int downloadCount = 0;

  /// Quando definido, o download fica parado em 50% até o teste completar.
  Completer<void>? downloadGate;

  /// Resultados do `verify`, consumidos em ordem; o último se repete.
  List<AppResult<Unit>> verifyResults = [const Success(unit)];
  int verifyCount = 0;

  final List<String> discarded = [];
  final List<String?> cleaned = [];

  @override
  AsyncAppResult<AppRelease> fetchLatest() async {
    fetchCount++;
    return latest;
  }

  @override
  Future<String?> cachedApkPath(AppRelease release) async => cachedPath;

  @override
  AsyncAppResult<String> download(
    AppRelease release, {
    required void Function(double fraction) onProgress,
    AppDownloadHandle? handle,
  }) async {
    downloadCount++;
    onProgress(0.5);
    final gate = downloadGate;
    if (gate != null) await gate.future;
    if (handle?.isCancelled ?? false) {
      return const Failure(ServerFailure('cancelado'));
    }
    if (downloadResult.isSuccess()) onProgress(1);
    return downloadResult;
  }

  @override
  AsyncAppResult<Unit> verify(String path, AppRelease release) async {
    final index = verifyCount < verifyResults.length
        ? verifyCount
        : verifyResults.length - 1;
    verifyCount++;
    return verifyResults[index];
  }

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
    if (cachedPath == path) cachedPath = null;
  }

  @override
  Future<void> cleanStale({String? keepFileName}) async {
    cleaned.add(keepFileName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeAppUpdatePlatform implements AppUpdatePlatform {
  String signer = signerPipeline;
  Object? signerError;
  int signerCalls = 0;

  final List<String> installed = [];
  Object? installError;

  @override
  Future<String> signerSha256() async {
    signerCalls++;
    final error = signerError;
    if (error != null) throw error;
    return signer;
  }

  @override
  Future<void> installApk(String path) async {
    final error = installError;
    if (error != null) throw error;
    installed.add(path);
  }
}
