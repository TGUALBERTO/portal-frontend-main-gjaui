import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

const _columns = [
  GjaColumn(header: 'Produto', flex: 2),
  GjaColumn(header: 'Quantidade', hAlign: GjaColumnHAlign.end),
];

List<GjaColumnListItem<String>> _items({
  GjaListType type = GjaListType.inactive,
}) => [
  GjaColumnListItem(
    key: 'teclado',
    type: type,
    cells: const [GjaText('Teclado'), GjaText('12')],
  ),
  GjaColumnListItem(
    key: 'mouse',
    type: type,
    cells: const [GjaText('Mouse'), GjaText('30')],
  ),
  GjaColumnListItem(
    key: 'monitor',
    type: type,
    cells: const [GjaText('Monitor'), GjaText('4')],
  ),
];

Widget _app(
  Widget home, {
  double width = 600,
  TextDirection direction = TextDirection.ltr,
}) => GjaApp(
  locale: const Locale('pt', 'BR'),
  builder: (context, child) =>
      Directionality(textDirection: direction, child: child!),
  home: Align(
    alignment: Alignment.topCenter,
    child: SizedBox(width: width, child: home),
  ),
);

/// Tabela que guarda a própria seleção e registra cada evento.
Widget _stateful({
  required GjaListMode mode,
  List<Set<String>>? selections,
  List<String>? presses,
  List<GjaListItemBase<String>>? items,
  Set<String> initial = const {},
}) {
  var keys = initial;
  return StatefulBuilder(
    builder: (context, setState) => GjaTable<String>(
      columns: _columns,
      items: items ?? _items(),
      mode: mode,
      selectedKeys: keys,
      onItemPress: presses?.add,
      onSelectionChange: (value) {
        selections?.add(value);
        setState(() => keys = value);
      },
    ),
  );
}

Finder _rowOf(String text) => find
    .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
    .first;

Color? _color(WidgetTester tester, Finder box) =>
    (tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color;

void main() {
  testWidgets('[API] Propriedades — Tabela mínima', (tester) async {
    await tester.pumpWidget(
      _app(GjaTable<String>(columns: _columns, items: _items())),
    );
    final header = tester.getRect(find.text('Produto'));
    final cell = tester.getRect(find.text('Teclado'));
    expect(cell.top, greaterThan(header.bottom));
    expect(cell.left, closeTo(header.left, 1));
    expect(
      tester.getRect(find.text('12')).right,
      closeTo(tester.getRect(find.text('Quantidade')).right, 1),
    );
  });

  testWidgets('[API] Colunas e linhas válidas — Linha com células a menos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const GjaTable<String>(
          columns: _columns,
          items: [
            GjaColumnListItem(key: 'a', cells: [GjaText('A')]),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Acionar uma linha', (
      tester,
    ) async {
      final presses = <String>[];
      await tester.pumpWidget(
        _app(
          GjaTable<String>(
            columns: _columns,
            items: _items(type: GjaListType.navigation),
            onItemPress: presses.add,
          ),
        ),
      );
      await tester.tap(find.text('Teclado'));
      await tester.pump();
      expect(presses, ['teclado']);
      expect(find.byIcon(GjaIcons.slimArrowRight), findsNWidgets(3));
    });

    testWidgets('[API] Callbacks e controlador — Seleção única', (
      tester,
    ) async {
      final selections = <Set<String>>[];
      await tester.pumpWidget(
        _app(
          _stateful(
            mode: GjaListMode.singleSelectMaster,
            selections: selections,
            initial: {'teclado'},
          ),
        ),
      );
      await tester.tap(find.text('Mouse'));
      await tester.pump();
      expect(selections, [
        {'mouse'},
      ]);
      expect(
        _color(
          tester,
          find
              .ancestor(
                of: find.text('Mouse'),
                matching: find.byType(DecoratedBox),
              )
              .last,
        ),
        _light.colors.selectionBackground,
      );
    });
  });

  group('[Comportamento] Seleção múltipla e tabela vazia', () {
    testWidgets(
      '[Comportamento] Seleção múltipla e tabela vazia — Seleção múltipla',
      (tester) async {
        final selections = <Set<String>>[];
        await tester.pumpWidget(
          _app(
            _stateful(mode: GjaListMode.multiSelect, selections: selections),
          ),
        );
        final boxes = find.byType(GjaCheckBox);
        expect(boxes, findsNWidgets(4));
        await tester.tap(boxes.at(2));
        await tester.pump();
        expect(selections.last, {'mouse'});
        expect(
          tester.widget<GjaCheckBox>(boxes.first).partiallySelected,
          isTrue,
        );
        await tester.tap(boxes.first);
        await tester.pump();
        expect(selections.last, {'teclado', 'mouse', 'monitor'});
      },
    );

    testWidgets(
      '[Comportamento] Seleção múltipla e tabela vazia — Tabela vazia',
      (tester) async {
        await tester.pumpWidget(
          _app(const GjaTable<String>(columns: _columns, items: [])),
        );
        expect(
          tester.getTopLeft(find.text('Sem dados')).dy,
          greaterThan(tester.getBottomLeft(find.text('Produto')).dy),
        );
      },
    );
  });

  testWidgets('[Comportamento] Teclado — Setas na tabela', (tester) async {
    final presses = <String>[];
    await tester.pumpWidget(
      _app(
        GjaTable<String>(
          columns: _columns,
          items: _items(type: GjaListType.active).sublist(0, 2),
          onItemPress: presses.add,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(presses, ['mouse']);
  });

  testWidgets('[Aparência] Tokens de componente — Linha da tabela', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(GjaTable<String>(columns: _columns, items: _items())),
    );
    expect(
      tester.getSize(_rowOf('Teclado')).height,
      _light.density.listItemHeight,
    );
    expect(
      tester.widget<Text>(find.text('Produto')).style?.color,
      _light.colors.label,
    );
    expect(_color(tester, _rowOf('Teclado')), _light.colors.base);
  });

  testWidgets('[Estados] Interação — Linha em hover', (tester) async {
    await tester.pumpWidget(
      _app(
        GjaTable<String>(
          columns: _columns,
          items: [
            const GjaColumnListItem(
              key: 'a',
              type: GjaListType.active,
              cells: [GjaText('Ativa'), GjaText('1')],
            ),
            const GjaColumnListItem(
              key: 'b',
              cells: [GjaText('Inativa'), GjaText('2')],
            ),
          ],
          onItemPress: (_) {},
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Ativa')));
    await tester.pump();
    expect(_color(tester, _rowOf('Ativa')), _light.colors.hoverBackground);
    await mouse.moveTo(tester.getCenter(find.text('Inativa')));
    await tester.pump();
    expect(_color(tester, _rowOf('Ativa')), isNull);
    expect(_color(tester, _rowOf('Inativa')), _light.colors.base);
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets(
      '[Acessibilidade] Semântica e contraste — Semântica da tabela',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            _stateful(
              mode: GjaListMode.singleSelectMaster,
              initial: {'teclado'},
            ),
          ),
        );
        expect(
          tester.getSemantics(find.text('Teclado')),
          containsSemantics(
            isButton: true,
            isSelected: true,
            label: 'Teclado\n12',
          ),
        );
        handle.dispose();
      },
    );

    testWidgets(
      '[Acessibilidade] Semântica e contraste — Contraste e alvo da tabela',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final (_, theme) in goldenThemes) {
          for (final mode in [
            GjaListMode.multiSelect,
            GjaListMode.singleSelectMaster,
          ]) {
            await tester.pumpWidget(
              GjaApp(
                key: ValueKey((theme, mode)),
                theme: theme,
                darkTheme: theme,
                density: theme.density.density,
                home: GjaContainer(
                  surface: GjaSurface.background,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 600,
                      child: _stateful(mode: mode, initial: {'mouse'}),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            await expectLater(
              tester,
              meetsGuideline(
                MinimumTapTargetGuideline(
                  size: Size.square(
                    GjaAccessibility.minTargetSize(theme.density),
                  ),
                  link: GjaAccessibility.targetSizeLink,
                ),
              ),
            );
          }
        }
        handle.dispose();
      },
    );
  });

  group('[Responsividade] Popin e direção', () {
    testWidgets('[Responsividade] Popin e direção — Colunas em popin', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          width: 400,
          const GjaTable<String>(
            columns: [
              GjaColumn(header: 'Produto'),
              GjaColumn(
                header: 'Preço',
                minScreenWidth: GjaSizeClass.medium,
                demandPopin: true,
              ),
              GjaColumn(
                header: 'Estoque',
                minScreenWidth: GjaSizeClass.medium,
              ),
            ],
            items: [
              GjaColumnListItem(
                key: 'a',
                cells: [
                  GjaText('Teclado'),
                  GjaText('R\$ 120,00'),
                  GjaText('12'),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.text('Preço'), findsNothing);
      expect(find.text('Estoque'), findsNothing);
      expect(find.text('12'), findsNothing);
      final label = tester.getRect(find.text('Preço:'));
      expect(
        label.top,
        greaterThan(tester.getRect(find.text('Teclado')).bottom),
      );
      expect(
        tester.getRect(find.text('R\$ 120,00')).left,
        greaterThan(label.right),
      );
    });

    testWidgets('[Responsividade] Popin e direção — Tabela em RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          direction: TextDirection.rtl,
          GjaTable<String>(columns: _columns, items: _items()),
        ),
      );
      expect(
        tester.getCenter(find.text('Produto')).dx,
        greaterThan(tester.getCenter(find.text('Quantidade')).dx),
      );
    });
  });

  testWidgets('[Integração] Dependências — Tabela sem Material', (
    tester,
  ) async {
    final presses = <String>[];
    await tester.pumpWidget(
      _app(
        _stateful(
          mode: GjaListMode.multiSelect,
          presses: presses,
          items: _items(type: GjaListType.navigation),
        ),
      ),
    );
    await tester.tap(find.text('Mouse'));
    await tester.tap(find.byType(GjaCheckBox).at(1));
    await tester.pumpAndSettle();
    expect(presses, ['mouse']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('[Comportamento] Mais linhas — Mais linhas', (tester) async {
    await tester.pumpWidget(
      _app(
        GjaTable<int>(
          columns: const [GjaColumn(header: 'Produto')],
          growing: true,
          growingThreshold: 2,
          items: [
            for (var i = 1; i <= 5; i++)
              GjaColumnListItem(key: i, cells: [GjaText('Item $i')]),
          ],
        ),
      ),
    );
    int rows() => find.textContaining(RegExp(r'^Item \d$')).evaluate().length;
    expect(rows(), 2);
    expect(find.text('[2 / 5]'), findsOneWidget);
    await tester.tap(find.text('Mais'));
    await tester.pump();
    expect(rows(), 4);
    expect(find.text('[4 / 5]'), findsOneWidget);
    await tester.tap(find.text('Mais'));
    await tester.pump();
    expect(rows(), 5);
    expect(find.text('Mais'), findsNothing);
  });

  testWidgets('[Comportamento] Títulos de grupo — Títulos de grupo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final selections = <Set<String>>[];
    await tester.pumpWidget(
      _app(
        _stateful(
          mode: GjaListMode.multiSelect,
          selections: selections,
          items: [
            const GjaGroupHeaderListItem(title: 'Periféricos', count: '2'),
            ..._items().sublist(0, 2),
            const GjaGroupHeaderListItem(title: 'Vídeo'),
            _items()[2],
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Periféricos (2)')).dy,
      lessThan(tester.getTopLeft(find.text('Teclado')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Vídeo')).dy,
      allOf(
        greaterThan(tester.getTopLeft(find.text('Mouse')).dy),
        lessThan(tester.getTopLeft(find.text('Monitor')).dy),
      ),
    );
    expect(
      tester.getSemantics(find.text('Vídeo')),
      containsSemantics(isHeader: true),
    );
    await tester.tap(find.byType(GjaCheckBox).first);
    await tester.pump();
    expect(selections.last, {'teclado', 'mouse', 'monitor'});
    handle.dispose();
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da tabela', () {
      final names = scenarioNames(
        'gja/widgets/gja-table',
        'add-gja-table',
      );
      expect(names, hasLength(20));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da tabela', (
      tester,
    ) async {
      const columns = [
        GjaColumn(header: 'Produto', flex: 2),
        GjaColumn(
          header: 'Preço',
          hAlign: GjaColumnHAlign.end,
          minScreenWidth: GjaSizeClass.medium,
          demandPopin: true,
        ),
        GjaColumn(header: 'Estoque', hAlign: GjaColumnHAlign.end),
      ];
      final items = [
        for (final (key, name, price, stock) in [
          ('a', 'Teclado', 'R\$ 120,00', '12'),
          ('b', 'Mouse', 'R\$ 45,00', '30'),
        ])
          GjaColumnListItem(
            key: key,
            type: GjaListType.navigation,
            cells: [GjaText(name), GjaText(price), GjaText(stock)],
          ),
      ];
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_table_$name',
          theme: theme,
          size: const Size(1040, 640),
          child: SizedBox(
            width: 1000,
            child: GjaHBox(
              gap: GjaSpace.l,
              alignItems: GjaFlexAlignItems.start,
              items: [
                SizedBox(
                  width: 620,
                  child: GjaVBox(
                    gap: GjaSpace.l,
                    alignItems: GjaFlexAlignItems.stretch,
                    items: [
                      GjaTable<String>(
                        headerText: 'Produtos',
                        columns: columns,
                        items: items,
                        mode: GjaListMode.multiSelect,
                        selectedKeys: const {'b'},
                        onSelectionChange: (_) {},
                        onItemPress: (_) {},
                      ),
                      const GjaTable<String>(columns: columns, items: []),
                      GjaTable<String>(
                        columns: columns,
                        growing: true,
                        growingThreshold: 2,
                        items: [
                          const GjaGroupHeaderListItem(
                            title: 'Periféricos',
                            count: '3',
                          ),
                          ...items,
                          GjaColumnListItem(
                            key: 'c',
                            cells: const [
                              GjaText('Webcam'),
                              GjaText('R\$ 210,00'),
                              GjaText('7'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 340,
                  child: GjaTable<String>(
                    columns: columns,
                    items: items,
                    onItemPress: (_) {},
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Tabela sem valor literal', () {
    final source = File(
      'lib/src/exibicao_dados/table/gja_table.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expect(fields, isNotEmpty);
    for (final type in fields) {
      expect(type, isNot(anyOf('double', 'double?', 'Color', 'Color?')));
    }
  });
}
