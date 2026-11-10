import 'package:gja_checks/gja_checks.dart';
import 'package:test/test.dart';

import 'support.dart';

String _item(String id, String kind, String priority, int phase,
        {String status = 'planned', List<String> deps = const [], String category = 'acoes'}) =>
    '''
  - id: $id
    name: X
    kind: $kind
    category: $category
    priority: $priority
    phase: $phase
    status: $status
    depends_on: [${deps.join(', ')}]
''';

String _catalog(List<String> items) => items.isEmpty ? 'items: []\n' : 'items:\n${items.join()}';

void main() {
  test('catálogo coerente é aceito', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([
        _item('gja/foundation/typography', 'foundation', 'P0', 1, status: 'specified'),
        _item('gja/widgets/gja-button', 'widget', 'P1', 2, deps: ['gja/foundation/typography']),
      ]),
      'openspec/specs/gja/foundation/typography/spec.md': componentSpec(),
    });
    expect(checkCatalog(repo), isEmpty);
  });

  test('catálogo ausente é indicado', () {
    expect(messages(checkCatalog(fixtureRepo({}))), [contains('catálogo não encontrado')]);
  });

  test('item especificado sem spec é rejeitado', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([_item('gja/widgets/gja-button', 'widget', 'P1', 2, status: 'specified')]),
    });
    expect(messages(checkCatalog(repo)), [contains('exige spec')]);
  });

  test('item especificado com spec em change ativa é aceito', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([_item('gja/widgets/gja-button', 'widget', 'P1', 2, status: 'specified')]),
      'openspec/changes/add-gja-button/specs/gja/widgets/gja-button/spec.md': widgetSpec(),
    });
    expect(checkCatalog(repo), isEmpty);
  });

  test('spec existente fora do catálogo é rejeitada', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([]),
      'openspec/specs/gja/foundation/color/spec.md': componentSpec(),
    });
    expect(messages(checkCatalog(repo)), [contains('não está no catálogo')]);
  });

  test('spec principal retirada por change ativa pode sair do catálogo', () {
    const removed = '## REMOVED Requirements\n\n### Requirement: Algo\n'
        '**Reason**: renomeado.\n**Migration**: use a spec nova.\n';
    Map<String, String> files({required bool retire}) => {
          catalogFile: _catalog([]),
          'openspec/specs/gja/foundation/elevation/spec.md': componentSpec(),
          'openspec/changes/update-x/.openspec.yaml': 'schema: spec-driven\n${retire ? 'retire_capabilities: true\n' : ''}',
          'openspec/changes/update-x/specs/gja/foundation/elevation/spec.md': removed,
        };
    expect(checkCatalog(fixtureRepo(files(retire: true))), isEmpty);
    expect(messages(checkCatalog(fixtureRepo(files(retire: false)))), [contains('não está no catálogo')]);
  });

  test('prioridade mais urgente que a dependência é rejeitada', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([
        _item('gja/widgets/gja-dropdown', 'widget', 'P2', 2),
        _item('gja/widgets/gja-select', 'widget', 'P1', 2, deps: ['gja/widgets/gja-dropdown']),
      ]),
    });
    expect(messages(checkCatalog(repo)), [contains('prioridade P1 mais urgente que a dependência')]);
  });

  test('fase anterior à da dependência é rejeitada', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([
        _item('gja/widgets/gja-dropdown', 'widget', 'P1', 3),
        _item('gja/widgets/gja-select', 'widget', 'P1', 2, deps: ['gja/widgets/gja-dropdown']),
      ]),
    });
    expect(messages(checkCatalog(repo)), [contains('fase 2 anterior')]);
  });

  test('dependência desconhecida e ciclo são rejeitados', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([
        _item('gja/widgets/gja-a', 'widget', 'P1', 2, deps: ['gja/widgets/gja-b', 'gja/widgets/gja-z']),
        _item('gja/widgets/gja-b', 'widget', 'P1', 2, deps: ['gja/widgets/gja-a']),
      ]),
    });
    expect(messages(checkCatalog(repo)), [
      contains('"gja/widgets/gja-z" não está no catálogo'),
      contains('ciclo de dependências no catálogo'),
    ]);
  });

  test('widget implementado exige a pasta do widget', () {
    final catalog = _catalog([
      _item('gja/widgets/gja-icon-button', 'widget', 'P1', 2, status: 'implemented', category: 'acoes-navegacao'),
    ]);
    const spec = 'openspec/specs/gja/widgets/gja-icon-button/spec.md';
    final missing = fixtureRepo({catalogFile: catalog, spec: widgetSpec()});
    expect(messages(checkCatalog(missing)),
        [contains('packages/gja_widgets/lib/src/acoes_navegacao/icon_button')]);

    final present = fixtureRepo({
      catalogFile: catalog,
      spec: widgetSpec(),
      'packages/gja_widgets/lib/src/acoes_navegacao/icon_button/icon_button.dart': '',
    });
    expect(checkCatalog(present), isEmpty);
  });

  test('dependência do catálogo ausente da spec é rejeitada', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([
        _item('gja/foundation/color', 'foundation', 'P0', 1),
        _item('gja/widgets/gja-badge', 'widget', 'P1', 2, status: 'specified', deps: ['gja/foundation/color']),
      ]),
      'openspec/specs/gja/widgets/gja-badge/spec.md': widgetSpec(),
    });
    expect(messages(checkCatalog(repo)), [contains('não aparece na spec')]);
  });

  test('dependência declarada em change ativa sobre a spec principal é aceita', () {
    final repo = fixtureRepo({
      catalogFile: _catalog([
        _item('gja/foundation/color', 'foundation', 'P0', 1),
        _item('gja/widgets/gja-badge', 'widget', 'P1', 2, status: 'specified', deps: ['gja/foundation/color']),
      ]),
      'openspec/specs/gja/widgets/gja-badge/spec.md': widgetSpec(),
      'openspec/changes/update-gja-badge/specs/gja/widgets/gja-badge/spec.md':
          widgetSpec(dependencies: ['gja/foundation/color']),
    });
    expect(checkCatalog(repo), isEmpty);
  });

  test('kind incompatível com o id é rejeitado', () {
    final repo = fixtureRepo({catalogFile: _catalog([_item('gja/widgets/gja-a', 'foundation', 'P1', 2)])});
    expect(messages(checkCatalog(repo)), [contains('não corresponde ao caminho')]);
  });
}
