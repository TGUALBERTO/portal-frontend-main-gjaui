import 'package:gja_checks/gja_checks.dart';
import 'package:test/test.dart';

import 'support.dart';

const _button = 'openspec/specs/gja/widgets/gja-button/spec.md';
const _typography = 'openspec/specs/gja/foundation/typography/spec.md';

void main() {
  group('estrutura das specs de widget', () {
    test('spec completa é aceita', () {
      final repo = fixtureRepo({
        _typography: componentSpec(),
        _button: widgetSpec(dependencies: ['gja/foundation/typography']),
      });
      expect(checkSpecs(repo), isEmpty);
    });

    test('etiqueta ausente é indicada', () {
      final repo = fixtureRepo({_button: widgetSpec(omit: {'Acessibilidade'})});
      final violations = checkSpecs(repo);
      expect(violations.single.path, _button);
      expect(violations.single.message, 'falta requisito com a etiqueta [Acessibilidade]');
    });

    test('Purpose ausente é indicado', () {
      final repo = fixtureRepo({_button: widgetSpec(purpose: false)});
      expect(messages(checkSpecs(repo)), [contains('## Purpose')]);
    });

    test('delta de widget existente não precisa repetir a estrutura', () {
      final repo = fixtureRepo({
        _button: widgetSpec(),
        'openspec/changes/update-gja-button-loading/specs/gja/widgets/gja-button/spec.md': '''
## MODIFIED Requirements

### Requirement: [Estados] Requisito
O widget SHALL exibir estado carregando.

#### Scenario: Carregando
- **WHEN** loading é verdadeiro
- **THEN** o indicador aparece
''',
      });
      expect(checkSpecs(repo), isEmpty);
    });

    test('nova spec de widget em change também é verificada', () {
      final repo = fixtureRepo({
        'openspec/changes/add-gja-badge/specs/gja/widgets/gja-badge/spec.md': widgetSpec(omit: {'Testes'}),
      });
      expect(messages(checkSpecs(repo)), [contains('[Testes]')]);
    });
  });

  group('referências', () {
    test('referência inexistente é rejeitada', () {
      final repo = fixtureRepo({_button: widgetSpec(dependencies: ['gja/widgets/gja-icon'])});
      final violations = checkSpecs(repo);
      expect(violations.single.message, contains('"gja/widgets/gja-icon"'));
      expect(violations.single.line, isNotNull);
    });

    test('referência a spec da mesma change é aceita', () {
      const change = 'openspec/changes/add-gja-form/specs/gja/widgets';
      final repo = fixtureRepo({
        '$change/gja-form/spec.md': widgetSpec(dependencies: ['gja/widgets/gja-form-field']),
        '$change/gja-form-field/spec.md': widgetSpec(),
      });
      expect(checkSpecs(repo), isEmpty);
    });

    test('referência a spec de outra change ainda não arquivada é rejeitada', () {
      final repo = fixtureRepo({
        'openspec/changes/add-gja-dropdown/specs/gja/widgets/gja-dropdown/spec.md': widgetSpec(),
        'openspec/changes/add-gja-select/specs/gja/widgets/gja-select/spec.md':
            widgetSpec(dependencies: ['gja/widgets/gja-dropdown']),
      });
      expect(messages(checkSpecs(repo)), [contains('gja/widgets/gja-dropdown')]);
    });

    test('changes arquivadas são ignoradas', () {
      final repo = fixtureRepo({
        'openspec/changes/archive/2026-01-01-add-x/specs/gja/widgets/gja-x/spec.md':
            widgetSpec(omit: {'API'}),
      });
      expect(checkSpecs(repo), isEmpty);
    });
  });

  test('ciclo entre specs é rejeitado', () {
    final repo = fixtureRepo({
      'openspec/specs/gja/widgets/gja-menu/spec.md': widgetSpec(dependencies: ['gja/widgets/gja-dropdown']),
      'openspec/specs/gja/widgets/gja-dropdown/spec.md': widgetSpec(dependencies: ['gja/widgets/gja-menu']),
    });
    expect(messages(checkSpecs(repo)),
        [contains('gja/widgets/gja-dropdown -> gja/widgets/gja-menu -> gja/widgets/gja-dropdown')]);
  });

  test('menções fora de [Integração] não criam dependência', () {
    final repo = fixtureRepo({
      'openspec/specs/gja/widgets/gja-menu/spec.md': widgetSpec(dependencies: ['gja/widgets/gja-dropdown']),
      'openspec/specs/gja/widgets/gja-dropdown/spec.md':
          '${widgetSpec()}\n### Requirement: [Restrições] Extra\nNão substitui `gja/widgets/gja-menu`.\n\n'
          '#### Scenario: X\n- **WHEN** a\n- **THEN** b\n',
    });
    expect(checkSpecs(repo), isEmpty);
  });
}
