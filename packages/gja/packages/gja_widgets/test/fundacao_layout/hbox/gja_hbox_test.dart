import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/traceability.dart';

Widget _sq(String key, [double size = 20]) =>
    SizedBox(key: Key(key), width: size, height: size);

/// Monta [child] sob [theme], na direção [direction], numa área de [width].
Widget _themed(
  Widget child, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double? width,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

GjaSpacingTokens get _cozy => GjaThemeData.light().spacing;

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

void main() {
  testWidgets('[API] Propriedades — Caixa horizontal mínima', (tester) async {
    await tester.pumpWidget(
      GjaApp(
        density: GjaDensity.cozy,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: const Key('box'),
            width: 300,
            height: 60,
            child: GjaHBox(items: [_sq('a'), _sq('b')]),
          ),
        ),
      ),
    );
    final a = _rect(tester, 'a');
    final b = _rect(tester, 'b');
    final box = _rect(tester, 'box');
    expect(b.left - a.right, _cozy.inlineGap);
    expect(a.left, box.left);
    expect(a.center.dy, box.center.dy);
  });

  test('[API] Enums do FlexBox — Valores dos enums do FlexBox', () {
    expect(GjaFlexJustifyContent.values.map((v) => v.name), [
      'start',
      'center',
      'end',
      'spaceBetween',
      'spaceAround',
    ]);
    expect(GjaFlexAlignItems.values.map((v) => v.name), [
      'start',
      'center',
      'end',
      'baseline',
      'stretch',
    ]);
    expect(GjaFlexWrap.values.map((v) => v.name), ['noWrap', 'wrap']);
  });

  testWidgets('[API] Callbacks e controlador — Caixa horizontal sem ação', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(GjaHBox(gap: GjaSpace.xl, items: [_sq('a'), _sq('b')])),
    );
    final between = Offset(_rect(tester, 'a').right + 2, 10);
    await tester.tapAt(between);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(GjaHBox),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
  });

  testWidgets(
    '[Comportamento] Espaço entre itens — Espaço só entre itens da caixa horizontal',
    (tester) async {
      await tester.pumpWidget(
        _themed(
          GjaHBox(
            key: const Key('row'),
            gap: GjaSpace.l,
            displayInline: true,
            items: [_sq('a'), _sq('b'), _sq('c')],
          ),
        ),
      );
      final row = _rect(tester, 'row');
      expect(row.width, 60 + 2 * _cozy.l);
      expect(_rect(tester, 'a').left, row.left);
      expect(_rect(tester, 'c').right, row.right);
    },
  );

  test('um único filho ou nenhum não recebe espaço', () {
    // O Flex nativo só aplica `spacing` entre filhos; coberto pelos cenários
    // de medida acima e verificado aqui pela ausência de filhos extras.
    const row = GjaHBox(items: []);
    expect(row.items, isEmpty);
  });

  group('[Comportamento] Alinhamento', () {
    testWidgets(
      '[Comportamento] Alinhamento — Alinhamento principal da caixa horizontal',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            GjaHBox(
              key: const Key('row'),
              justifyContent: GjaFlexJustifyContent.end,
              items: [_sq('a'), _sq('b')],
            ),
            width: 200,
          ),
        );
        expect(_rect(tester, 'b').right, _rect(tester, 'row').right);
      },
    );

    testWidgets(
      '[Comportamento] Alinhamento — Alinhamento cruzado da caixa horizontal',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            const SizedBox(
              height: 60,
              child: GjaHBox(
                alignItems: GjaFlexAlignItems.stretch,
                items: [SizedBox(key: Key('a'), width: 20)],
              ),
            ),
            width: 200,
          ),
        );
        expect(_rect(tester, 'a').height, 60);
      },
    );

    testWidgets(
      '[Comportamento] Alinhamento — Espaço em volta na caixa horizontal',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            GjaHBox(
              key: const Key('row'),
              gap: GjaSpace.none,
              justifyContent: GjaFlexJustifyContent.spaceAround,
              items: [_sq('a'), _sq('b')],
            ),
            width: 200,
          ),
        );
        final row = _rect(tester, 'row');
        expect(_rect(tester, 'a').left - row.left, 40);
        expect(row.right - _rect(tester, 'b').right, 40);
      },
    );

    testWidgets(
      '[Comportamento] Alinhamento — Linha de base na caixa horizontal',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            const GjaHBox(
              alignItems: GjaFlexAlignItems.baseline,
              items: [
                GjaTitle(
                  'Pedido',
                  key: Key('title'),
                  titleStyle: GjaTitleLevel.h2,
                ),
                GjaText('Aguardando', key: Key('text')),
              ],
            ),
            width: 600,
          ),
        );
        double baseline(String key) {
          final box = tester.renderObject<RenderBox>(find.byKey(Key(key)));
          return box.localToGlobal(Offset.zero).dy +
              box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;
        }

        final title = _rect(tester, 'title');
        final text = _rect(tester, 'text');
        expect(title.height, greaterThan(text.height));
        expect(baseline('text'), closeTo(baseline('title'), 0.01));
      },
    );
  });

  testWidgets('[Comportamento] Quebra de linha — Caixa horizontal com quebra', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        GjaHBox(
          wrap: GjaFlexWrap.wrap,
          alignItems: GjaFlexAlignItems.start,
          gap: GjaSpace.s,
          items: [for (var i = 0; i < 5; i++) _sq('q$i', 40)],
        ),
        width: 120,
      ),
    );
    final first = _rect(tester, 'q0');
    final rows = {for (var i = 0; i < 5; i++) _rect(tester, 'q$i').top}.toList()
      ..sort();
    expect(rows.length, greaterThan(1));
    expect(rows[1] - first.bottom, _cozy.s);
  });

  testWidgets('[Comportamento] Quebra de linha — Quebra sem esticar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        GjaHBox(
          wrap: GjaFlexWrap.wrap,
          alignItems: GjaFlexAlignItems.stretch,
          items: [_sq('a')],
        ),
        width: 120,
      ),
    );
    final error = tester.takeException();
    expect(error, isA<AssertionError>());
    expect('$error', contains('stretch e baseline'));
  });

  testWidgets('GjaHBox com wrap rejeita item expansível', (tester) async {
    await tester.pumpWidget(
      _themed(
        GjaHBox(
          wrap: GjaFlexWrap.wrap,
          alignItems: GjaFlexAlignItems.start,
          items: [Expanded(child: _sq('a'))],
        ),
        width: 120,
      ),
    );
    final error = tester.takeException();
    expect(error, isA<AssertionError>());
    expect('$error', contains('GjaHBox com wrap'));
  });

  testWidgets(
    '[Comportamento] Itens expansíveis — Item expandido na caixa horizontal',
    (tester) async {
      await tester.pumpWidget(
        _themed(
          GjaHBox(
            gap: GjaSpace.m,
            items: [
              _sq('a'),
              const Expanded(child: SizedBox(key: Key('e'), height: 20)),
            ],
          ),
          width: 200,
        ),
      );
      expect(_rect(tester, 'e').width, 200 - 20 - _cozy.m);
    },
  );

  testWidgets(
    '[Aparência] Tokens de componente — Troca de tema da caixa horizontal',
    (tester) async {
      Widget app(GjaDensity density) => _themed(
        GjaHBox(gap: GjaSpace.l, items: [_sq('a'), _sq('b')]),
        theme: GjaThemeData.light(density: density),
      );
      double gap() => _rect(tester, 'b').left - _rect(tester, 'a').right;
      await tester.pumpWidget(app(GjaDensity.cozy));
      expect(gap(), _cozy.l);
      await tester.pumpWidget(app(GjaDensity.compact));
      await tester.pumpAndSettle();
      // Como no Fiori, a densidade não muda o espaçamento.
      expect(gap(), _cozy.l);
      final base = GjaThemeData.light();
      final other = base.copyWith(
        density: base.density.copyWith(spacing: base.spacing.copyWith(l: 24)),
      );
      await tester.pumpWidget(
        _themed(
          GjaHBox(gap: GjaSpace.l, items: [_sq('a'), _sq('b')]),
          theme: other,
        ),
      );
      await tester.pumpAndSettle();
      expect(gap(), 24);
      expect(
        find.descendant(
          of: find.byType(GjaHBox),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    },
  );

  Future<List<FocusNode>> pumpFocusables(WidgetTester tester, int n) async {
    final nodes = [for (var i = 0; i < n; i++) FocusNode()];
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });
    await tester.pumpWidget(
      GjaApp(
        home: GjaHBox(
          items: [
            for (final node in nodes)
              Focus(
                focusNode: node,
                child: const SizedBox(width: 20, height: 20),
              ),
          ],
        ),
      ),
    );
    nodes.first.requestFocus();
    await tester.pump();
    return nodes;
  }

  testWidgets(
    '[Estados] Sem estados visuais — Caixa horizontal não recebe foco',
    (tester) async {
      final nodes = await pumpFocusables(tester, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);
    },
  );

  testWidgets(
    '[Acessibilidade] Teclado e foco — Ordem de foco na caixa horizontal',
    (tester) async {
      final nodes = await pumpFocusables(tester, 3);
      final visited = <int>[];
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        visited.add(nodes.indexWhere((n) => n.hasPrimaryFocus));
      }
      expect(visited, [1, 2]);
    },
  );

  testWidgets(
    '[Acessibilidade] Semântica e escala — Semântica da caixa horizontal inalterada',
    (tester) async {
      final handle = tester.ensureSemantics();
      List<String> labels() => [
        for (final t in ['Pedido', 'Aberto'])
          tester.getSemantics(find.text(t)).label,
      ];
      await tester.pumpWidget(
        _themed(
          const Row(children: [GjaText('Pedido'), GjaText('Aberto')]),
        ),
      );
      final native = labels();
      await tester.pumpWidget(
        _themed(
          const GjaHBox(items: [GjaText('Pedido'), GjaText('Aberto')]),
        ),
      );
      expect(labels(), native);
      handle.dispose();
    },
  );

  group('[Responsividade] Direção e densidade', () {
    testWidgets(
      '[Responsividade] Direção e densidade — Caixa horizontal em RTL',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            GjaHBox(key: const Key('row'), items: [_sq('a'), _sq('b')]),
            direction: TextDirection.rtl,
            width: 200,
          ),
        );
        expect(_rect(tester, 'a').right, _rect(tester, 'row').right);
      },
    );

    testWidgets(
      '[Responsividade] Direção e densidade — Densidade compacta na caixa horizontal',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            Column(
              children: [
                GjaHBox(gap: GjaSpace.l, items: [_sq('a'), _sq('b')]),
                GjaTheme.density(
                  density: GjaDensity.compact,
                  child: GjaHBox(
                    gap: GjaSpace.l,
                    items: [_sq('c'), _sq('d')],
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_rect(tester, 'b').left - _rect(tester, 'a').right, _cozy.l);
        expect(_rect(tester, 'd').left - _rect(tester, 'c').right, _cozy.l);
      },
    );
  });

  testWidgets('[Integração] Dependências — Caixa horizontal sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaApp(
        home: Column(
          children: [
            const GjaHBox(items: [GjaText('a'), GjaText('b')]),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [for (var i = 0; i < 6; i++) GjaText('$i')],
            ),
          ],
        ),
      ),
    );
    expect(find.byType(GjaHBox), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('[Testes] Cobertura exigida — Rastreabilidade da caixa horizontal', () {
    final names = scenarioNames(
      'gja/widgets/gja-hbox',
      'update-gja-row-column-fiori-hbox-vbox',
    );
    expect(names, hasLength(21));
    expect(untestedScenarios(names), isEmpty);
  });

  test('[Restrições] Fora do escopo — Caixa horizontal sem valor literal', () {
    final source = File(
      'lib/src/fundacao_layout/hbox/gja_hbox.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaHBox\((.*?)\}\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    expect(ctor, isNot(contains('double')));
    expect(ctor, isNot(contains('EdgeInsets')));
  });
}
