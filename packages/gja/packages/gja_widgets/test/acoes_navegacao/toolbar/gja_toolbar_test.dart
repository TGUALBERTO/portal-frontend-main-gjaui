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

Widget _app(
  Widget home, {
  TextDirection direction = TextDirection.ltr,
  double width = 600,
}) => GjaApp(
  builder: (context, child) =>
      Directionality(textDirection: direction, child: child!),
  home: Center(
    child: SizedBox(width: width, child: home),
  ),
);

Finder _box([int index = 0]) => find
    .descendant(
      of: find.byType(GjaToolbar).at(index),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(_box(index)).decoration as BoxDecoration;

void main() {
  testWidgets('[API] Propriedades — Barra mínima', (tester) async {
    await tester.pumpWidget(
      _app(
        GjaToolbar(
          content: [
            const GjaText('Pedidos'),
            const Spacer(),
            GjaButton(text: 'Novo', onPress: () {}),
          ],
        ),
      ),
    );
    final bar = tester.getRect(find.byType(GjaToolbar));
    expect(bar.height, _light.density.barHeight);
    expect(
      tester.getRect(find.text('Pedidos')).left,
      closeTo(bar.left + _light.spacing.s, 0.5),
    );
    expect(
      tester.getRect(find.byType(GjaButton)).right,
      closeTo(bar.right - _light.spacing.s, 0.5),
    );
  });

  testWidgets('[API] Callbacks e controlador — Barra acionável', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(
        GjaToolbar(
          design: GjaToolbarDesign.info,
          semanticLabel: '2 filtros ativos',
          onPress: () => calls++,
          content: const [GjaText('2 filtros ativos')],
        ),
      ),
    );
    await tester.tap(find.byType(GjaToolbar));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('[Comportamento] Disposição dos itens — Barra estreita', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        width: 200,
        GjaToolbar(
          content: [
            for (var i = 0; i < 5; i++)
              GjaButton(text: 'Ação $i', onPress: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final bar = tester.getRect(find.byType(GjaToolbar));
    expect(tester.getRect(find.text('Ação 4')).left, greaterThan(bar.right));
  });

  testWidgets('[Aparência] Desenhos e estilos — Desenhos da barra', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaToolbar(content: [GjaText('a')]),
            GjaToolbar(
              design: GjaToolbarDesign.solid,
              content: [GjaText('b')],
            ),
            GjaToolbar(
              design: GjaToolbarDesign.info,
              content: [GjaText('c')],
            ),
            GjaToolbar(
              style: GjaToolbarStyle.clear,
              content: [GjaText('d')],
            ),
          ],
        ),
      ),
    );
    expect(_decoration(tester).color, isNull);
    expect(_decoration(tester, 1).color, _light.colors.base);
    expect(
      _decoration(tester, 2).color,
      _light.colors.stateColors(GjaValueState.information).background,
    );
    for (final i in [0, 1, 2]) {
      expect(
        (_decoration(tester, i).border! as Border).bottom.color,
        _light.colors.separator,
      );
    }
    expect(_decoration(tester, 3).border, isNull);
  });

  testWidgets(
    '[Estados] Interação da barra acionável — Hover na barra acionável',
    (tester) async {
      await tester.pumpWidget(
        _app(
          GjaToolbar(
            onPress: () {},
            semanticLabel: 'h',
            content: const [GjaText('Filtros')],
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(GjaToolbar)));
      await tester.pump();
      expect(_decoration(tester).color, _light.colors.hoverBackground);
    },
  );

  group('[Acessibilidade] Semântica e teclado', () {
    testWidgets(
      '[Acessibilidade] Semântica e teclado — Ordem de foco na barra',
      (tester) async {
        final start = FocusNode();
        addTearDown(start.dispose);
        await tester.pumpWidget(
          _app(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Focus(
                  focusNode: start,
                  child: const SizedBox.square(dimension: 8),
                ),
                GjaToolbar(
                  content: [
                    for (final t in ['a', 'b', 'c'])
                      GjaButton(text: t, onPress: () {}),
                  ],
                ),
              ],
            ),
          ),
        );
        start.requestFocus();
        await tester.pump();
        final seen = <String?>[];
        for (var i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          seen.add(
            FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<GjaButton>()
                ?.text,
          );
        }
        expect(seen, ['a', 'b', 'c']);
      },
    );

    testWidgets(
      '[Acessibilidade] Semântica e teclado — Semântica da barra acionável',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            GjaToolbar(
              design: GjaToolbarDesign.info,
              semanticLabel: '2 filtros ativos',
              onPress: () {},
              content: const [GjaText('2 filtros ativos')],
            ),
          ),
        );
        expect(
          tester.getSemantics(find.byType(GjaToolbar)),
          containsSemantics(
            isButton: true,
            label: '2 filtros ativos\n2 filtros ativos',
            hasTapAction: true,
          ),
        );
        handle.dispose();
      },
    );
  });

  testWidgets('[Responsividade] Direção e densidade — Barra em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        direction: TextDirection.rtl,
        GjaToolbar(
          content: [
            const GjaText('Pedidos'),
            const Spacer(),
            GjaButton(text: 'Novo', onPress: () {}),
          ],
        ),
      ),
    );
    expect(
      tester.getCenter(find.text('Pedidos')).dx,
      greaterThan(tester.getCenter(find.byType(GjaButton)).dx),
    );
  });

  testWidgets('[Integração] Dependências — Barra sem Material', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final design in GjaToolbarDesign.values)
              GjaToolbar(
                design: design,
                content: [
                  const GjaText('Título'),
                  const Spacer(),
                  GjaButton(text: 'a', onPress: () {}),
                  const GjaSeparator.vertical(),
                  GjaButton(text: 'b', onPress: () {}),
                ],
              ),
            GjaToolbar(
              onPress: () {},
              semanticLabel: 'x',
              content: const [GjaText('Acionável')],
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Acionável'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da barra', () {
      final names = scenarioNames(
        'gja/widgets/gja-toolbar',
        'add-gja-toolbar',
      );
      expect(names, hasLength(13));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da barra', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_toolbar_$name',
          theme: theme,
          size: const Size(520, 340),
          child: SizedBox(
            width: 480,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => GjaVBox(
                    gap: GjaSpace.s,
                    alignItems: GjaFlexAlignItems.stretch,
                    items: [
                      for (final design in GjaToolbarDesign.values)
                        GjaToolbar(
                          design: design,
                          content: [
                            GjaTitle(
                              design.name,
                              titleStyle: GjaTitleLevel.h5,
                            ),
                            const Spacer(),
                            GjaButton(
                              icon: GjaIcons.add,
                              tooltip: 'Novo',
                              type: GjaButtonType.transparent,
                              onPress: () {},
                            ),
                            const GjaSeparator.vertical(),
                            GjaButton(
                              icon: GjaIcons.filter,
                              tooltip: 'Filtrar',
                              type: GjaButtonType.transparent,
                              onPress: () {},
                            ),
                          ],
                        ),
                      const GjaToolbar(
                        style: GjaToolbarStyle.clear,
                        content: [GjaText('clear')],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Barra sem valor literal', () {
    final source = File(
      'lib/src/acoes_navegacao/toolbar/gja_toolbar.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaToolbar\(\{(.*?)\}\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    expect(ctor, isNot(contains('double')));
    expect(ctor, isNot(contains('Color')));
  });
}
