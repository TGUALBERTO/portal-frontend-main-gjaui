import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/app_update/domain/entities/app_release.dart';

/// O `latest.json` decide o que será instalado no coletor. A leitura é estrita:
/// documento incompleto ou estranho é falha, não "atualização sem conferência".
void main() {
  // Exatamente o que o job build_apk publicou no pipeline #119.
  Map<String, dynamic> published() => <String, dynamic>{
        'versionCode': 119,
        'versionName': '2026.10.02.13.46',
        'apk': 'gjamobile-2026.10.02.13.46.apk',
        'size': 108373219,
        'sha256':
            '6efe0768a7ae2d70efc1f63e157c978922f2ba343a86a745f28b2336f67b42a7',
        'signerSha256':
            'b6c1fd79b07d23b4007bfde02d9369ead41d89c58425306bbe08406ac5c09afa',
        'commit': 'd242ba97',
        'builtAt': '2026-10-02T16:55:00Z',
      };

  group('AppRelease.fromJson', () {
    test('lê o documento publicado pelo pipeline', () {
      final release = AppRelease.fromJson(published());

      expect(release.versionCode, 119);
      expect(release.versionName, '2026.10.02.13.46');
      expect(release.apkFileName, 'gjamobile-2026.10.02.13.46.apk');
      expect(release.sizeBytes, 108373219);
      expect(release.sha256, startsWith('6efe0768'));
      expect(release.signerSha256, startsWith('b6c1fd79'));
      expect(release.commit, 'd242ba97');
      expect(release.builtAt, DateTime.utc(2026, 10, 2, 16, 55));
    });

    test('campos opcionais ausentes não impedem a leitura', () {
      final json = published()
        ..remove('signerSha256')
        ..remove('commit')
        ..remove('builtAt');

      final release = AppRelease.fromJson(json);

      expect(release.signerSha256, isNull);
      expect(release.commit, isNull);
      expect(release.builtAt, isNull);
    });

    test('signerSha256 vazio é tratado como ausente', () {
      final release = AppRelease.fromJson(published()..['signerSha256'] = '');
      expect(release.signerSha256, isNull);
    });

    test('hashes em maiúsculas são normalizados', () {
      final json = published();
      json['sha256'] = (json['sha256'] as String).toUpperCase();
      json['signerSha256'] = (json['signerSha256'] as String).toUpperCase();

      final release = AppRelease.fromJson(json);

      expect(release.sha256, published()['sha256']);
      expect(release.signerSha256, published()['signerSha256']);
    });

    test('versionCode inteiro escrito como double é aceito', () {
      final release = AppRelease.fromJson(published()..['versionCode'] = 119.0);
      expect(release.versionCode, 119);
    });

    for (final field in ['versionCode', 'versionName', 'apk', 'size', 'sha256']) {
      test('sem "$field" é rejeitado', () {
        expect(
          () => AppRelease.fromJson(published()..remove(field)),
          throwsFormatException,
        );
      });
    }

    test('versionCode como texto é rejeitado', () {
      expect(
        () => AppRelease.fromJson(published()..['versionCode'] = '119'),
        throwsFormatException,
      );
    });

    test('versionCode fracionário é rejeitado', () {
      expect(
        () => AppRelease.fromJson(published()..['versionCode'] = 119.5),
        throwsFormatException,
      );
    });

    test('size zero ou negativo é rejeitado', () {
      expect(
        () => AppRelease.fromJson(published()..['size'] = 0),
        throwsFormatException,
      );
    });

    test('sha256 que não é hex de 64 caracteres é rejeitado', () {
      expect(
        () => AppRelease.fromJson(published()..['sha256'] = 'abc123'),
        throwsFormatException,
      );
    });

    // O nome do APK vira caminho no cache e trecho de URL.
    for (final name in [
      '../../etc/passwd.apk',
      'pasta/app.apk',
      r'pasta\app.apk',
      '.oculto.apk',
      'app.exe',
      'app.apk?x=1',
    ]) {
      test('apk "$name" é rejeitado', () {
        expect(
          () => AppRelease.fromJson(published()..['apk'] = name),
          throwsFormatException,
        );
      });
    }
  });

  group('AppRelease.isNewerThan', () {
    final release = AppRelease.fromJson(published());

    test('publicado maior que o instalado é atualização', () {
      expect(release.isNewerThan(118), isTrue);
    });

    test('publicado igual ao instalado não é atualização', () {
      expect(release.isNewerThan(119), isFalse);
    });

    test('publicado menor que o instalado nunca é oferecido (downgrade)', () {
      expect(release.isNewerThan(120), isFalse);
    });
  });

  test('sizeLabel mostra MB com vírgula decimal', () {
    expect(AppRelease.fromJson(published()).sizeLabel, '103,4 MB');
  });
}
