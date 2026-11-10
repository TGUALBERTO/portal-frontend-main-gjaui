import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/app_update/data/app_update_dio.dart';
import 'package:gjamobile/src/features/app_update/data/repositories/app_update_repository.dart';
import 'package:gjamobile/src/features/app_update/domain/entities/app_release.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Canal de atualização em memória: responde `latest.json` e o APK como o nginx
/// de produção faria, sem rede.
class _FakeChannel implements HttpClientAdapter {
  _FakeChannel(this.files);

  /// Caminho (sem o host) → corpo. Ausente = 404.
  final Map<String, List<int>> files;
  final List<String> requested = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.path);
    final body = files[options.uri.path];
    if (body == null) {
      return ResponseBody.fromString('nao encontrado', 404);
    }
    final isJson = options.uri.path.endsWith('.json');
    return ResponseBody.fromBytes(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [
          if (isJson) 'application/json' else 'application/octet-stream',
        ],
        Headers.contentLengthHeader: ['${body.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const base = 'https://canal.exemplo/downloads/android';
  const apkName = 'gjamobile-2026.10.03.09.15.apk';

  late Directory cacheRoot;
  late List<int> apkBytes;
  late AppRelease published;

  AppUpdateRepository repositoryWith(Map<String, List<int>> files) {
    final dio = Dio()..httpClientAdapter = _FakeChannel(files);
    return AppUpdateRepository(
      dio: AppUpdateDio(dio),
      channelBaseUrl: base,
      cacheRoot: () async => cacheRoot,
    );
  }

  Map<String, dynamic> latestJson() => <String, dynamic>{
        'versionCode': published.versionCode,
        'versionName': published.versionName,
        'apk': published.apkFileName,
        'size': published.sizeBytes,
        'sha256': published.sha256,
      };

  setUp(() async {
    cacheRoot = await Directory.systemTemp.createTemp('app_update_test_');
    // "APK" de teste: bytes quaisquer, grandes o bastante para o hash em fluxo.
    apkBytes = List<int>.generate(200000, (i) => i % 251);
    published = AppRelease(
      versionCode: 120,
      versionName: '2026.10.03.09.15',
      apkFileName: apkName,
      sizeBytes: apkBytes.length,
      sha256: sha256.convert(apkBytes).toString(),
    );
  });

  tearDown(() async {
    if (await cacheRoot.exists()) await cacheRoot.delete(recursive: true);
  });

  group('fetchLatest', () {
    test('lê o latest.json do canal', () async {
      final repository = repositoryWith({
        '/downloads/android/latest.json': utf8.encode(jsonEncode(latestJson())),
      });

      final result = await repository.fetchLatest();

      expect(result.getOrNull(), published);
    });

    test('canal sem latest.json (404) é falha, não exceção', () async {
      final result = await repositoryWith({}).fetchLatest();

      expect(result.isError(), isTrue);
    });

    test('documento malformado é falha', () async {
      final repository = repositoryWith({
        '/downloads/android/latest.json':
            utf8.encode(jsonEncode(latestJson()..remove('sha256'))),
      });

      final result = await repository.fetchLatest();

      expect(result.isError(), isTrue);
    });

    test('resposta que não é um objeto JSON é falha', () async {
      final repository = repositoryWith({
        '/downloads/android/latest.json': utf8.encode('[1, 2, 3]'),
      });

      expect((await repository.fetchLatest()).isError(), isTrue);
    });
  });

  group('download', () {
    test('grava o APK no cache, com o nome publicado, e informa o progresso',
        () async {
      final repository =
          repositoryWith({'/downloads/android/$apkName': apkBytes});
      final progress = <double>[];

      final result =
          await repository.download(published, onProgress: progress.add);

      final path = result.getOrNull();
      expect(path, isNotNull);
      expect(path, endsWith('app_update/$apkName'));
      expect(await File(path!).readAsBytes(), apkBytes);
      expect(progress.last, 1.0);
      // Nenhum `.part` sobra depois de um download que terminou.
      expect(File('$path.part').existsSync(), isFalse);
    });

    test('falha não deixa arquivo pela metade no cache', () async {
      final repository = repositoryWith({});

      final result = await repository.download(published, onProgress: (_) {});

      expect(result.isError(), isTrue);
      expect(await repository.cachedApkPath(published), isNull);
      final dir = Directory('${cacheRoot.path}/app_update');
      expect(dir.existsSync() ? dir.listSync() : const <Object>[], isEmpty);
    });

    test('download cancelado falha e é reconhecível pelo handle', () async {
      final repository =
          repositoryWith({'/downloads/android/$apkName': apkBytes});
      final handle = AppDownloadHandle()..cancel();

      final result = await repository.download(
        published,
        onProgress: (_) {},
        handle: handle,
      );

      expect(handle.isCancelled, isTrue);
      expect(result.isError(), isTrue);
      expect(await repository.cachedApkPath(published), isNull);
    });
  });

  group('verify', () {
    late AppUpdateRepository repository;
    late String path;

    setUp(() async {
      repository = repositoryWith({});
      final file = File('${cacheRoot.path}/baixado.apk');
      await file.writeAsBytes(apkBytes);
      path = file.path;
    });

    test('arquivo com o tamanho e o SHA-256 publicados é aceito', () async {
      final result = await repository.verify(path, published);

      expect(result.isSuccess(), isTrue);
    });

    test('tamanho diferente é rejeitado', () async {
      await File(path).writeAsBytes(apkBytes.sublist(0, 1000));

      final result = await repository.verify(path, published);

      expect(result.exceptionOrNull(), isA<ValidationFailure>());
      expect(result.exceptionOrNull()?.message, contains('bytes'));
    });

    test('mesmo tamanho com conteúdo diferente é rejeitado pelo SHA-256',
        () async {
      final tampered = List<int>.of(apkBytes)..[100] = (apkBytes[100] + 1) % 256;
      await File(path).writeAsBytes(tampered);

      final result = await repository.verify(path, published);

      expect(result.exceptionOrNull(), isA<ValidationFailure>());
      expect(result.exceptionOrNull()?.message, contains('SHA-256'));
    });

    test('arquivo inexistente é falha, não exceção', () async {
      final result = await repository.verify('${cacheRoot.path}/nada', published);

      expect(result.isError(), isTrue);
    });
  });

  group('cache', () {
    late AppUpdateRepository repository;
    late Directory dir;

    setUp(() async {
      repository = repositoryWith({});
      dir = Directory('${cacheRoot.path}/app_update');
      await dir.create(recursive: true);
    });

    test('cachedApkPath devolve o arquivo já baixado', () async {
      await File('${dir.path}/$apkName').writeAsBytes(apkBytes);

      expect(await repository.cachedApkPath(published), endsWith(apkName));
    });

    test('cachedApkPath ignora download pela metade (.part)', () async {
      await File('${dir.path}/$apkName.part').writeAsBytes(apkBytes);

      expect(await repository.cachedApkPath(published), isNull);
    });

    test('cleanStale apaga APKs antigos e .part, e mantém o publicado',
        () async {
      await File('${dir.path}/$apkName').writeAsBytes(apkBytes);
      await File('${dir.path}/gjamobile-antigo.apk').writeAsBytes([1, 2, 3]);
      await File('${dir.path}/gjamobile-outro.apk.part').writeAsBytes([1]);

      await repository.cleanStale(keepFileName: apkName);

      final names =
          dir.listSync().map((e) => e.uri.pathSegments.last).toList();
      expect(names, [apkName]);
    });

    test('cleanStale sem a pasta de cache não falha', () async {
      await dir.delete(recursive: true);

      await repository.cleanStale(keepFileName: apkName);
    });

    test('discard apaga o arquivo', () async {
      final file = File('${dir.path}/$apkName');
      await file.writeAsBytes(apkBytes);

      await repository.discard(file.path);

      expect(file.existsSync(), isFalse);
    });
  });
}
