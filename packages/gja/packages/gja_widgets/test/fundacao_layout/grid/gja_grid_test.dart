import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/traceability.dart';

/// Ajusta a janela de teste para [width] × [height].
void _view(WidgetTester tester, double width, [double height = 1200]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Monta [child] numa área de [width], sob [theme] e [direction].
Widget _area(
  double width,
  Widget child, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(key: const Key('area'), width: width, child: child),
    ),
  ),
);

Widget _item(int i) => SizedBox(key: Key('i$i'), height: 20);

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

/// Itens por linha: quantos itens têm o mesmo topo do primeiro.
int _perRow(WidgetTester tester, int count) {
  final top = _rect(tester, 'i0').top;
  return [
    for (var i = 0; i < count; i++) _rect(tester, 'i$i').top,
  ].where((t) => t == top).length;
}

GjaSpacingTokens get _spacing => GjaThemeData.light().spacing;

void main() {
  testWidgets('[API] Propriedades — Grade mínima', (tester) async {
    _view(tester, 1200);
    await tester.pumpWidget(
      GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 1200,
            child: GjaGrid(content: [for (var i = 0; i < 6; i++) _item(i)]),
          ),
        ),
      ),
    );
    expect(_perRow(tester, 6), 4);
    final g = _spacing.l;
    final column = (1200 - 11 * g) / 12;
    expect(_rect(tester, 'i0').width, closeTo(3 * column + 2 * g, 0.01));
    expect(_rect(tester, 'i4').top, greaterThan(_rect(tester, 'i0').top));
    expect(_rect(tester, 'i5').top, _rect(tester, 'i4').top);
  });

  testWidgets('[API] Span válido — Span inválido', (tester) async {
    await tester.pumpWidget(
      _area(
        500,
        GjaGrid(
          defaultSpan: const GjaResponsiveValue(small: 13),
          content: [_item(0)],
        ),
      ),
    );
    final error = tester.takeException();
    expect(error, isA<AssertionError>());
    expect('$error', contains('13'));
  });

  testWidgets('[API] Callbacks e controlador — Grade sem ação', (tester) async {
    await tester.pumpWidget(
      _area(1200, GjaGrid(content: [_item(0), _item(1)])),
    );
    final between = Offset(_rect(tester, 'i0').right + 2, 10);
    await tester.tapAt(between);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(GjaGrid),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
  });

  testWidgets('[Comportamento] Largura das colunas — Larguras de span 4 e 8', (
    tester,
  ) async {
    _view(tester, 1300);
    await tester.pumpWidget(
      _area(
        1200,
        GjaGrid(
          containerQuery: true,
          defaultSpan: const GjaResponsiveValue(small: 4),
          content: [
            _item(0),
            GjaGridData(
              span: const GjaResponsiveValue(small: 8),
              child: _item(1),
            ),
          ],
        ),
      ),
    );
    final a = _rect(tester, 'i0');
    final b = _rect(tester, 'i1');
    expect(b.top, a.top);
    expect(b.left - a.right, closeTo(_spacing.l, 0.01));
    expect(b.right, closeTo(_rect(tester, 'area').right, 0.01));
  });

  testWidgets('[Comportamento] Fluxo em linhas — Quebra quando não cabe', (
    tester,
  ) async {
    _view(tester, 1300);
    Widget cell(int i, int span) => GjaGridData(
      span: GjaResponsiveValue(small: span),
      child: _item(i),
    );
    await tester.pumpWidget(
      _area(1200, GjaGrid(content: [cell(0, 6), cell(1, 4), cell(2, 6)])),
    );
    expect(_rect(tester, 'i1').top, _rect(tester, 'i0').top);
    expect(
      _rect(tester, 'i2').top - _rect(tester, 'i0').bottom,
      closeTo(_spacing.l, 0.01),
    );
    expect(_rect(tester, 'i2').left, _rect(tester, 'i0').left);
  });

  group('[Comportamento] Span por classe e por item', () {
    testWidgets(
      '[Comportamento] Span por classe e por item — Item com span próprio',
      (tester) async {
        _view(tester, 1300);
        await tester.pumpWidget(
          _area(
            1200,
            GjaGrid(
              containerQuery: true,
              content: [
                GjaGridData(
                  span: const GjaResponsiveValue(small: 12, large: 6),
                  child: _item(0),
                ),
                _item(1),
              ],
            ),
          ),
        );
        final g = _spacing.l;
        final column = (1200 - 11 * g) / 12;
        expect(_rect(tester, 'i0').width, closeTo(6 * column + 5 * g, 0.01));
        expect(_rect(tester, 'i1').width, closeTo(3 * column + 2 * g, 0.01));
      },
    );

    testWidgets(
      '[Comportamento] Span por classe e por item — Grade em cada classe',
      (tester) async {
        _view(tester, 2000);
        final perRow = <int>[];
        for (final width in [500.0, 800.0, 1200.0, 1500.0]) {
          await tester.pumpWidget(
            _area(
              width,
              GjaGrid(
                containerQuery: true,
                content: [for (var i = 0; i < 8; i++) _item(i)],
              ),
            ),
          );
          perRow.add(_perRow(tester, 8));
        }
        expect(perRow, [1, 2, 4, 4]);
      },
    );
  });

  testWidgets(
    '[Aparência] Tokens de componente — Espaço da densidade compacta',
    (tester) async {
      _view(tester, 1300);
      await tester.pumpWidget(
        _area(
          1200,
          GjaTheme.density(
            density: GjaDensity.compact,
            child: GjaGrid(content: [_item(0), _item(1)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final compact = GjaThemeData.light(
        density: GjaDensity.compact,
      ).spacing;
      expect(
        _rect(tester, 'i1').left - _rect(tester, 'i0').right,
        closeTo(compact.l, 0.01),
      );
      expect(
        find.descendant(
          of: find.byType(GjaGrid),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('[Aparência] Tokens de componente — Grade sem margem externa', (
    tester,
  ) async {
    _view(tester, 1300);
    await tester.pumpWidget(
      _area(
        1200,
        GjaGrid(
          defaultSpan: const GjaResponsiveValue(small: 6),
          content: [_item(0), _item(1)],
        ),
      ),
    );
    final area = _rect(tester, 'area');
    expect(_rect(tester, 'i0').left, area.left);
    expect(_rect(tester, 'i1').right, closeTo(area.right, 0.01));
    expect(tester.getSize(find.byType(GjaGrid)).height, 20);
  });

  Future<List<FocusNode>> pumpFocusables(WidgetTester tester, int n) async {
    _view(tester, 1300);
    final nodes = [for (var i = 0; i < n; i++) FocusNode()];
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });
    await tester.pumpWidget(
      GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            child: GjaGrid(
              content: [
                for (final node in nodes)
                  Focus(focusNode: node, child: const SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
    nodes.first.requestFocus();
    await tester.pump();
    return nodes;
  }

  testWidgets('[Estados] Sem estados de interação — Grade não recebe foco', (
    tester,
  ) async {
    final nodes = await pumpFocusables(tester, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(nodes[1].hasPrimaryFocus, isTrue);
  });

  testWidgets('[Acessibilidade] Teclado e foco — Ordem de foco na grade', (
    tester,
  ) async {
    final nodes = await pumpFocusables(tester, 4);
    final visited = <int>[];
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      visited.add(nodes.indexWhere((n) => n.hasPrimaryFocus));
    }
    expect(visited, [1, 2, 3]);
  });

  testWidgets(
    '[Acessibilidade] Semântica e escala — Semântica da grade inalterada',
    (tester) async {
      final handle = tester.ensureSemantics();
      const texts = ['Pedido', 'Fornecedor', 'Valor'];
      List<String> labels() => [
        for (final t in texts) tester.getSemantics(find.text(t)).label,
      ];
      await tester.pumpWidget(
        _area(500, Column(children: [for (final t in texts) GjaText(t)])),
      );
      final native = labels();
      await tester.pumpWidget(
        _area(500, GjaGrid(content: [for (final t in texts) GjaText(t)])),
      );
      expect(labels(), native);
      handle.dispose();
    },
  );

  testWidgets('[Responsividade] Base e direção — Classe pela tela', (
    tester,
  ) async {
    _view(tester, 1200);
    final perRow = <int>[];
    for (final containerQuery in [false, true]) {
      await tester.pumpWidget(
        _area(
          500,
          GjaGrid(
            containerQuery: containerQuery,
            content: [for (var i = 0; i < 4; i++) _item(i)],
          ),
        ),
      );
      perRow.add(_perRow(tester, 4));
    }
    expect(perRow, [4, 1]);
  });

  testWidgets('[Responsividade] Base e direção — Grade em RTL', (tester) async {
    _view(tester, 1300);
    await tester.pumpWidget(
      _area(
        1200,
        GjaGrid(
          defaultSpan: const GjaResponsiveValue(small: 6),
          content: [_item(0), _item(1)],
        ),
        direction: TextDirection.rtl,
      ),
    );
    final area = _rect(tester, 'area');
    expect(_rect(tester, 'i0').right, closeTo(area.right, 0.01));
    expect(_rect(tester, 'i0').left, greaterThan(area.center.dx));
  });

  testWidgets('[Integração] Dependências — Grade sem Material', (tester) async {
    await tester.pumpWidget(
      GjaApp(
        home: Column(
          children: [
            GjaGrid(content: [_item(0), _item(1)]),
            GjaGrid(
              containerQuery: true,
              content: [
                GjaGridData(
                  span: const GjaResponsiveValue(small: 6),
                  child: _item(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.byType(GjaGrid), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('[Testes] Cobertura exigida — Rastreabilidade da grade', () {
    final names = scenarioNames('gja/widgets/gja-grid', 'add-gja-grid');
    expect(names, hasLength(18));
    expect(untestedScenarios(names), isEmpty);
  });

  test('[Restrições] Fora do escopo — Grade sem valor literal', () {
    final source = File(
      'lib/src/fundacao_layout/grid/gja_grid.dart',
    ).readAsStringSync();
    final ctors = RegExp(
      r'const GjaGrid(?:Data)?\(\{(.*?)\}\)',
      dotAll: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expect(ctors, hasLength(2));
    for (final ctor in ctors) {
      expect(ctor, isNot(contains('double')));
      expect(ctor, isNot(contains('columns')));
    }
  });
}
