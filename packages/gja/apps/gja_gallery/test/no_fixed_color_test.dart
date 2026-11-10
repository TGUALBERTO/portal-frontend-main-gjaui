import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Testes e documentação das cores — Galeria sem cor fixa', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, isNot(contains('Color(0x')));
    // A cor da aplicação vem do tema, aplicado pelo GjaApp.
    expect(source, contains('return GjaApp('));
    expect(source, isNot(contains('WidgetsApp(')));
  });
}
