import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Fonte de ícones empacotada e licenciada — Licença e mapa distribuídos',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: Lucide'));
      expect(pubspec, contains('asset: fonts/lucide/lucide.ttf'));
      for (final path in [
        'fonts/lucide/lucide.ttf',
        'fonts/lucide/codepoints.json',
        'fonts/lucide/LICENSE',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      expect(
        File('fonts/lucide/LICENSE').readAsStringSync(),
        startsWith('ISC License'),
      );
    },
  );
}
