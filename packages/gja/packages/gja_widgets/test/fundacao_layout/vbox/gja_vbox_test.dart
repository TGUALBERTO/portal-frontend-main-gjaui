import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/traceability.dart';

Widget _sq(String key) => SizedBox(key: Key(key), width: 20, height: 20);

/// Monta [child] sob [theme], na direção [direction], numa área fixa.
Widget _themed(
  Widget child, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double? width,
  double? height,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, height: height, child: child),
    ),
  ),
);

GjaSpacingTokens get _cozy => GjaThemeData.light().spacing;

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

void main() {
  testWidgets('[API] Propriedades — Caixa vertical mínima', (tester) async {
    await tester.pumpWidget(
      GjaApp(
        density: GjaDensity.cozy,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: const Key('box'),
            width: 200,
            height: 200,
            child: GjaVBox(items: [_sq('a'), _sq('b')]),
          ),
        ),
      ),
    );
    final a = _rect(tester, 'a');
    final box = _rect(tester, 'box');
    expect(_rect(tester, 'b').top - a.bottom, _cozy.stackGap);
    expect(a.topLeft, box.topLeft);
  });

  testWidgets('[API] Callbacks e controlador — Caixa vertical sem ação', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(GjaVBox(gap: GjaSpace.xl, items: [_sq('a'), _sq('b')])),
    );
    await tester.tapAt(Offset(10, _rect(tester, 'a').bottom + 2));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(GjaVBox),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
  });

  testWidgets(
    '[Comportamento] Espaço entre itens — Espaço só entre itens da caixa vertical',
    (tester) async {
      await tester.pumpWidget(
        _themed(
          GjaVBox(
            key: const Key('col'),
            gap: GjaSpace.l,
            displayInline: true,
            items: [_sq('a'), _sq('b'), _sq('c')],
          ),
        ),
      );
      final col = _rect(tester, 'col');
      expect(col.height, 60 + 2 * _cozy.l);
      expect(_rect(tester, 'a').top, col.top);
      expect(_rect(tester, 'c').bottom, col.bottom);
    },
  );

  group('[Comportamento] Alinhamento', () {
    testWidgets(
      '[Comportamento] Alinhamento — Alinhamento principal da caixa vertical',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            GjaVBox(
              key: const Key('col'),
              justifyContent: GjaFlexJustifyContent.spaceBetween,
              items: [_sq('a'), _sq('b')],
            ),
            height: 200,
          ),
        );
        final col = _rect(tester, 'col');
        expect(_rect(tester, 'a').top, col.top);
        expect(_rect(tester, 'b').bottom, col.bottom);
      },
    );

    testWidgets(
      '[Comportamento] Alinhamento — Alinhamento cruzado da caixa vertical',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            const GjaVBox(
              alignItems: GjaFlexAlignItems.stretch,
              items: [SizedBox(key: Key('a'), height: 20)],
            ),
            width: 200,
            height: 100,
          ),
        );
        expect(_rect(tester, 'a').width, 200);
      },
    );

    testWidgets(
      '[Comportamento] Alinhamento — Linha de base na caixa vertical',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            const GjaVBox(
              key: Key('column'),
              alignItems: GjaFlexAlignItems.baseline,
              items: [SizedBox(key: Key('a'), width: 20, height: 20)],
            ),
            width: 200,
            height: 100,
          ),
        );
        expect(_rect(tester, 'a').left, _rect(tester, 'column').left);
      },
    );
  });

  testWidgets(
    '[Comportamento] Itens expansíveis — Item expandido na caixa vertical',
    (tester) async {
      await tester.pumpWidget(
        _themed(
          GjaVBox(
            gap: GjaSpace.m,
            items: [
              _sq('a'),
              const Expanded(child: SizedBox(key: Key('e'), width: 20)),
            ],
          ),
          height: 200,
        ),
      );
      expect(_rect(tester, 'e').height, 200 - 20 - _cozy.m);
    },
  );

  testWidgets(
    '[Aparência] Tokens de componente — Troca de tema da caixa vertical',
    (tester) async {
      Widget app(GjaDensity density) => _themed(
        GjaVBox(gap: GjaSpace.l, items: [_sq('a'), _sq('b')]),
        theme: GjaThemeData.light(density: density),
      );
      double gap() => _rect(tester, 'b').top - _rect(tester, 'a').bottom;
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
          GjaVBox(gap: GjaSpace.l, items: [_sq('a'), _sq('b')]),
          theme: other,
        ),
      );
      await tester.pumpAndSettle();
      expect(gap(), 24);
      expect(
        find.descendant(
          of: find.byType(GjaVBox),
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
        home: GjaVBox(
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
    '[Estados] Sem estados visuais — Caixa vertical não recebe foco',
    (tester) async {
      final nodes = await pumpFocusables(tester, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);
    },
  );

  testWidgets(
    '[Acessibilidade] Teclado e foco — Ordem de foco na caixa vertical',
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
    '[Acessibilidade] Semântica e escala — Semântica da caixa vertical inalterada',
    (tester) async {
      final handle = tester.ensureSemantics();
      List<String> labels() => [
        for (final t in ['Pedido', 'Aberto'])
          tester.getSemantics(find.text(t)).label,
      ];
      await tester.pumpWidget(
        _themed(
          const Column(children: [GjaText('Pedido'), GjaText('Aberto')]),
        ),
      );
      final native = labels();
      await tester.pumpWidget(
        _themed(
          const GjaVBox(items: [GjaText('Pedido'), GjaText('Aberto')]),
        ),
      );
      expect(labels(), native);
      handle.dispose();
    },
  );

  group('[Responsividade] Direção e densidade', () {
    testWidgets(
      '[Responsividade] Direção e densidade — Caixa vertical em RTL',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            GjaVBox(key: const Key('col'), items: [_sq('a')]),
            direction: TextDirection.rtl,
            width: 200,
            height: 100,
          ),
        );
        expect(_rect(tester, 'a').right, _rect(tester, 'col').right);
      },
    );

    testWidgets(
      '[Responsividade] Direção e densidade — Densidade compacta na caixa vertical',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GjaVBox(
                  gap: GjaSpace.l,
                  displayInline: true,
                  items: [_sq('a'), _sq('b')],
                ),
                GjaTheme.density(
                  density: GjaDensity.compact,
                  child: GjaVBox(
                    gap: GjaSpace.l,
                    displayInline: true,
                    items: [_sq('c'), _sq('d')],
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_rect(tester, 'b').top - _rect(tester, 'a').bottom, _cozy.l);
        expect(_rect(tester, 'd').top - _rect(tester, 'c').bottom, _cozy.l);
      },
    );
  });

  testWidgets('[Integração] Dependências — Caixa vertical sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GjaApp(home: GjaVBox(items: [GjaText('a'), GjaText('b')])),
    );
    expect(find.byType(GjaVBox), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('[Testes] Cobertura exigida — Rastreabilidade da caixa vertical', () {
    final names = scenarioNames(
      'gja/widgets/gja-vbox',
      'update-gja-row-column-fiori-hbox-vbox',
    );
    expect(names, hasLength(17));
    expect(untestedScenarios(names), isEmpty);
  });

  test('[Restrições] Fora do escopo — Caixa vertical sem valor literal', () {
    final source = File(
      'lib/src/fundacao_layout/vbox/gja_vbox.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaVBox\((.*?)\}\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    expect(ctor, isNot(contains('double')));
    expect(ctor, isNot(contains('EdgeInsets')));
  });
}
