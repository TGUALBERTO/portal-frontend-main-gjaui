import 'dart:io';

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
  double width = 400,
}) => GjaApp(
  builder: (context, child) =>
      Directionality(textDirection: direction, child: child!),
  home: Center(
    child: SizedBox(width: width, child: home),
  ),
);

Finder _box([int index = 0]) => find
    .descendant(
      of: find.byType(GjaMessageStrip).at(index),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(_box(index)).decoration as BoxDecoration;

void main() {
  testWidgets('[API] Propriedades — Faixa mínima', (tester) async {
    await tester.pumpWidget(
      _app(const GjaMessageStrip(text: 'Pedido salvo')),
    );
    expect(tester.getSize(_box()).width, 400);
    final info = _light.colors.stateColors(GjaValueState.information);
    expect(_decoration(tester).color, info.background);
    expect(
      tester.widget<Text>(find.text('Pedido salvo')).style?.fontSize,
      _light.typography.base.fontSize,
    );
  });

  test('[API] Texto válido — Faixa sem texto', () {
    expect(() => GjaMessageStrip(text: ''), throwsAssertionError);
  });

  testWidgets('[API] Callbacks e controlador — Fechar a faixa', (tester) async {
    var calls = 0;
    var visible = true;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => visible
              ? GjaMessageStrip(
                  text: 'Atenção',
                  showCloseButton: true,
                  onClose: () {
                    calls++;
                    setState(() => visible = false);
                  },
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
    await tester.tap(find.byType(GjaButton));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(GjaMessageStrip), findsNothing);
  });

  testWidgets('[Comportamento] Ícone e link — Faixa com ícone e link', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        GjaMessageStrip(
          text: 'Falha ao salvar',
          type: GjaValueState.error,
          showIcon: true,
          link: GjaLink(text: 'Detalhes', onPress: () {}),
        ),
      ),
    );
    final icon = find.byIcon(GjaIcons.error);
    expect(icon, findsOneWidget);
    final text = tester.getRect(find.text('Falha ao salvar'));
    expect(tester.getRect(icon).right, lessThanOrEqualTo(text.left));
    expect(tester.getRect(find.text('Detalhes')).left, greaterThan(text.left));
  });

  testWidgets('[Aparência] Tokens de componente — Cores por tipo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in GjaValueState.values)
              GjaMessageStrip(text: type.name, type: type),
          ],
        ),
      ),
    );
    for (final (i, type) in GjaValueState.values.indexed) {
      final c = _light.colors.stateColors(type);
      expect(_decoration(tester, i).color, c.background, reason: type.name);
      expect(
        (_decoration(tester, i).border! as Border).top.color,
        c.border,
        reason: type.name,
      );
    }
  });

  testWidgets('[Estados] Sem estados próprios — Faixa sem foco próprio', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(focusNode: first, child: const SizedBox.square(dimension: 8)),
            const GjaMessageStrip(text: 'Aviso'),
            Focus(
              focusNode: second,
              child: const SizedBox.square(dimension: 8),
            ),
          ],
        ),
      ),
    );
    first.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets('[Acessibilidade] Semântica e contraste — Semântica da faixa', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const GjaMessageStrip(text: 'Pedido salvo', showIcon: true)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pedido salvo')),
        containsSemantics(label: 'Pedido salvo', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('[Acessibilidade] Semântica e contraste — Contraste da faixa', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final (_, theme) in goldenThemes) {
        await tester.pumpWidget(
          GjaApp(
            key: ValueKey(theme),
            theme: theme,
            darkTheme: theme,
            density: theme.density.density,
            home: Center(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final type in GjaValueState.values)
                      GjaMessageStrip(
                        text: type.name,
                        type: type,
                        showCloseButton: true,
                        onClose: () {},
                      ),
                  ],
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
      handle.dispose();
    });
  });

  group('[Responsividade] Quebra e direção', () {
    testWidgets('[Responsividade] Quebra e direção — Faixa estreita', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          width: 200,
          const GjaMessageStrip(
            text: 'O pedido foi salvo, mas ainda precisa de aprovação.',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final lineHeight = _light.typography.base.fontSize! * 2;
      expect(
        tester.getSize(find.textContaining('O pedido')).height,
        greaterThan(lineHeight),
      );
    });

    testWidgets('[Responsividade] Quebra e direção — Faixa em RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          direction: TextDirection.rtl,
          GjaMessageStrip(
            text: 'Aviso',
            showIcon: true,
            showCloseButton: true,
            onClose: () {},
          ),
        ),
      );
      final text = tester.getRect(find.text('Aviso'));
      expect(
        tester.getRect(find.byIcon(GjaIcons.information)).left,
        greaterThanOrEqualTo(text.right),
      );
      expect(
        tester.getCenter(find.byType(GjaButton)).dx,
        lessThan(tester.getCenter(_box()).dx),
      );
    });
  });

  testWidgets('[Integração] Dependências — Faixa sem Material', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in GjaValueState.values)
              GjaMessageStrip(
                text: type.name,
                type: type,
                showIcon: true,
                showCloseButton: true,
                onClose: () {},
                link: GjaLink(text: 'Link', onPress: () {}),
              ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(GjaButton).first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da faixa', () {
      final names = scenarioNames(
        'gja/widgets/gja-message-strip',
        'add-gja-message-strip',
      );
      expect(names, hasLength(15));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da faixa', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_message_strip_$name',
          theme: theme,
          size: const Size(480, 420),
          child: SizedBox(
            width: 420,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => GjaVBox(
                    gap: GjaSpace.s,
                    alignItems: GjaFlexAlignItems.stretch,
                    items: [
                      for (final type in GjaValueState.values)
                        GjaMessageStrip(
                          text: 'Mensagem ${type.name}',
                          type: type,
                          showIcon: true,
                        ),
                      GjaMessageStrip(
                        text: 'Com link e fechar',
                        type: GjaValueState.warning,
                        showCloseButton: true,
                        onClose: () {},
                        link: GjaLink(text: 'Ver detalhes', onPress: () {}),
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

  test('[Restrições] Fora do escopo — Faixa sem valor literal', () {
    final source = File(
      'lib/src/feedback_sobreposicoes/message_strip/gja_message_strip.dart',
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
