import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/app_update/app_update_config.dart';
import 'package:gjamobile/src/features/app_update/data/app_update_dio.dart';
import 'package:gjamobile/src/features/app_update/domain/entities/app_release.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Permite ao controller cancelar um download em andamento sem conhecer o
/// `CancelToken` do Dio.
class AppDownloadHandle {
  final CancelToken _token = CancelToken();

  bool get isCancelled => _token.isCancelled;

  void cancel() {
    if (!_token.isCancelled) _token.cancel('cancelado pelo usuário');
  }
}

/// Lê o canal de atualização e cuida do arquivo baixado.
///
/// Nenhum método pede `requiresNetwork`: a checagem roda em segundo plano, e o
/// toast global de "sem conexão" do `runTask` é certo para uma ação do usuário e
/// errado para algo que ele não pediu. Sem rede, a chamada falha e pronto.
class AppUpdateRepository {
  AppUpdateRepository({
    required AppUpdateDio dio,
    String channelBaseUrl = AppUpdateConfig.channelBaseUrl,
    Future<Directory> Function() cacheRoot = getTemporaryDirectory,
  })  : _dio = dio.dio,
        _baseUrl = channelBaseUrl.endsWith('/')
            ? channelBaseUrl.substring(0, channelBaseUrl.length - 1)
            : channelBaseUrl,
        _cacheRoot = cacheRoot;

  final Dio _dio;
  final String _baseUrl;

  /// Raiz do cache. No Android o diretório temporário é o `cacheDir` privado do
  /// app, que é onde o FileProvider procura a pasta da atualização.
  final Future<Directory> Function() _cacheRoot;

  String _url(String name) => '$_baseUrl/$name';

  Future<Directory> _cacheDir() async {
    final root = await _cacheRoot();
    return Directory('${root.path}/${AppUpdateConfig.cacheDirName}');
  }

  Future<File> _apkFile(AppRelease release) async {
    final dir = await _cacheDir();
    return File('${dir.path}/${release.apkFileName}');
  }

  /// O build publicado no canal.
  AsyncAppResult<AppRelease> fetchLatest() => runTask(() async {
        final response = await _dio.get<dynamic>(_url('latest.json'));
        final data = response.data;
        // Com `Content-Type: application/json` o Dio já entrega o mapa; sem ele,
        // uma string.
        final Object? decoded = data is String ? jsonDecode(data) : data;
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('latest.json não é um objeto JSON');
        }
        return AppRelease.fromJson(decoded);
      });

  /// Baixa o APK de [release] para o cache e devolve o caminho do arquivo.
  ///
  /// Escreve num `.part` e só renomeia no fim: um arquivo com o nome final é
  /// sempre um download que terminou, então [cachedApkPath] nunca devolve um
  /// pela metade.
  AsyncAppResult<String> download(
    AppRelease release, {
    required void Function(double fraction) onProgress,
    AppDownloadHandle? handle,
  }) =>
      runTask(() async {
        final target = await _apkFile(release);
        final partial = File('${target.path}.part');
        await target.parent.create(recursive: true);

        try {
          await _dio.download(
            _url(release.apkFileName),
            partial.path,
            cancelToken: handle?._token,
            onReceiveProgress: (received, total) {
              // Sem Content-Length o Dio informa total -1; o tamanho publicado
              // serve de denominador.
              final expected = total > 0 ? total : release.sizeBytes;
              onProgress((received / expected).clamp(0.0, 1.0));
            },
          );
        } catch (_) {
          if (await partial.exists()) await partial.delete();
          rethrow;
        }

        if (await target.exists()) await target.delete();
        await partial.rename(target.path);
        return target.path;
      });

  /// Confere o arquivo em [path] contra o `latest.json`: tamanho e SHA-256.
  ///
  /// O tamanho vem primeiro porque é de graça e pega o caso comum (download
  /// truncado, ou o nginx devolvendo o `index.html` do SPA para um APK que não
  /// existe mais). O hash roda em outro isolate: são dezenas de MB, e na thread
  /// da UI o coletor congelaria por alguns segundos.
  ///
  /// A assinatura não é conferida aqui: quem faz isso é o Android, na instalação.
  AsyncAppResult<Unit> verify(String path, AppRelease release) =>
      runTask(() async {
        final length = await File(path).length();
        if (length != release.sizeBytes) {
          throw ValidationFailure(
            'O arquivo baixado tem $length bytes; o publicado tem '
            '${release.sizeBytes}.',
          );
        }

        final digest = await compute(_sha256OfFile, path);
        if (digest != release.sha256) {
          throw const ValidationFailure(
            'O arquivo baixado não confere com o publicado (SHA-256 diferente).',
          );
        }
        return unit;
      });

  /// Caminho do APK de [release] já baixado por completo, ou `null`. Não
  /// confere o conteúdo — isso é do [verify].
  Future<String?> cachedApkPath(AppRelease release) async {
    try {
      final file = await _apkFile(release);
      return await file.exists() ? file.path : null;
    } catch (e) {
      AppLogger.warning('app_update: falha ao consultar o cache: $e');
      return null;
    }
  }

  /// Apaga o arquivo em [path], se existir.
  Future<void> discard(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.warning('app_update: falha ao apagar $path: $e');
    }
  }

  /// Apaga da pasta de download tudo que não seja [keepFileName]: APKs de
  /// versões anteriores e `.part` de downloads interrompidos. Cada um tem ~100 MB
  /// e o coletor não tem espaço sobrando.
  Future<void> cleanStale({String? keepFileName}) async {
    try {
      final dir = await _cacheDir();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        if (entity.uri.pathSegments.last == keepFileName) continue;
        await entity.delete();
      }
    } catch (e) {
      AppLogger.warning('app_update: falha ao limpar o cache: $e');
    }
  }
}

/// SHA-256 (hex minúsculo) do arquivo em [path], lido em fluxo. Top-level para
/// poder rodar em outro isolate via [compute].
Future<String> _sha256OfFile(String path) async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
}
