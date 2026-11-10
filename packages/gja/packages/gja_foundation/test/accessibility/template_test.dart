import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Corpo (descrição) do requisito [title] no template de spec de widget.
String _requirement(String template, String title) {
  final start = template.indexOf('### Requirement: $title');
  expect(start, isNot(-1), reason: title);
  final rest = template.substring(start);
  final end = rest.indexOf('#### Scenario:');
  return rest.substring(0, end);
}

void main() {
  test('Semântica dos widgets interativos — Convenção no template de spec', () {
    final template = File(
      '../../docs/specs/widget-spec-template.md',
    ).readAsStringSync();

    final semantics = _requirement(
      template,
      '[Acessibilidade] Semântica e contraste',
    );
    for (final term in ['rótulo', 'papel', 'estado', 'valor', 'decorativos']) {
      expect(semantics, contains(term), reason: term);
    }
    expect(semantics, contains('gja/foundation/accessibility'));

    final tests = _requirement(template, '[Testes] Cobertura exigida');
    for (final term in [
      'textContrastGuideline',
      'labeledTapTargetGuideline',
      'MinimumTapTargetGuideline',
      'textScaler',
      'matchesSemantics',
      'teclado',
    ]) {
      expect(tests, contains(term), reason: term);
    }
  });
}
