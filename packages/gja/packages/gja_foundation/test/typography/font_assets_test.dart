import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fonte empacotada e licenciada — Licença distribuída', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = [
      for (final m in RegExp(r'asset:\s*(fonts/inter/\S+)').allMatches(pubspec))
        m.group(1)!,
    ];
    expect(assets, hasLength(4));
    expect(pubspec, contains('family: Inter'));
    for (final weight in ['500', '600', '700']) {
      expect(pubspec, contains('weight: $weight'));
    }
    for (final asset in assets) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
      expect(File(asset).parent.path, endsWith('inter'), reason: asset);
    }
    final license = File('fonts/inter/OFL.txt');
    expect(license.existsSync(), isTrue);
    expect(
      license.readAsStringSync(),
      contains('SIL OPEN FONT LICENSE Version 1.1'),
    );
  });
}
