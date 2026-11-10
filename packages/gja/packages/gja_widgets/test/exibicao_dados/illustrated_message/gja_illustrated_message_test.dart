import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

Widget _app(Widget home, {double width = 400}) => GjaApp(
  home: Center(
    child: SizedBox(width: width, child: home),
  ),
);

void main() {
  testWidgets('[API] Propriedades — Mensagem mínima', (tester) async {
    await tester.pumpWidget(
      _app(const GjaIllustratedMessage(title: 'Nenhum pedido')),
    );
    final icon = find.byIcon(GjaIcons.document);
    expect(icon, findsOneWidget);
    final title = tester.getRect(find.text('Nenhum pedido'));
    expect(tester.getRect(icon).bottom, lessThanOrEqualTo(title.top));
    expect(tester.getCenter(icon).dx, closeTo(title.center.dx, 0.5));
  });

  test('[API] Callbacks e controlador — Mensagem sem título', () {
    expect(() => GjaIllustratedMessage(title: ''), throwsAssertionError);
  });

  testWidgets('[Comportamento] Ilustração por tipo — Ilustração de busca', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaIllustratedMessage(
              title: 'a',
              illustrationType: GjaIllustrationType.noSearchResults,
            ),
            GjaIllustratedMessage(
              title: 'b',
              illustration: SizedBox(key: Key('own'), width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
    expect(find.byIcon(GjaIcons.search), findsOneWidget);
    expect(find.byKey(const Key('own')), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('[Aparência] Tamanhos e tokens — Tamanhos da mensagem', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final size in GjaIllustrationSize.values)
              GjaIllustratedMessage(title: 't', illustrationSize: size),
          ],
        ),
      ),
    );
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    final x = _light.icons.xLarge;
    expect(icons.map((i) => i.size), [x, 2 * x, 4 * x]);
    expect(icons.first.color, _light.colors.brand);
    final titles = tester.widgetList<GjaTitle>(find.byType(GjaTitle));
    expect(titles.map((t) => t.titleStyle), [
      GjaTitleLevel.h4,
      GjaTitleLevel.h3,
      GjaTitleLevel.h2,
    ]);
  });

  testWidgets('[Estados] Sem estados próprios — Mensagem sem foco', (
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
            const GjaIllustratedMessage(title: 'Vazio'),
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
    testWidgets(
      '[Acessibilidade] Semântica e contraste — Semântica da mensagem',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            const GjaIllustratedMessage(
              title: 'Nenhum pedido',
              description: 'Crie o primeiro pedido.',
            ),
          ),
        );
        expect(
          tester.getSemantics(find.text('Nenhum pedido')),
          containsSemantics(isHeader: true),
        );
        expect(
          find.bySemanticsLabel('Crie o primeiro pedido.'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(ExcludeSemantics),
            matching: find.byType(Icon),
          ),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets(
      '[Acessibilidade] Semântica e contraste — Contraste da mensagem',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
          await tester.pumpWidget(
            GjaApp(
              key: ValueKey(theme.brightness),
              theme: theme,
              darkTheme: theme,
              home: const GjaContainer(
                surface: GjaSurface.background,
                child: Center(
                  child: GjaIllustratedMessage(
                    title: 'Nenhum pedido',
                    description: 'Crie o primeiro pedido.',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        handle.dispose();
      },
    );
  });

  testWidgets('[Responsividade] Largura — Mensagem estreita', (tester) async {
    await tester.pumpWidget(
      _app(
        width: 200,
        GjaIllustratedMessage(
          title: 'Nenhum resultado para os filtros escolhidos',
          description:
              'Ajuste os filtros ou limpe a busca para ver todos os pedidos.',
          additionalContent: [
            GjaButton(text: 'Limpar filtros', onPress: () {}),
            GjaButton(text: 'Ajuda', onPress: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.textContaining('Ajuste')).height,
      greaterThan(_light.typography.base.fontSize! * 2),
    );
  });

  testWidgets('[Integração] Dependências — Mensagem sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: Column(
            children: [
              for (final type in GjaIllustrationType.values)
                GjaIllustratedMessage(
                  title: type.name,
                  illustrationType: type,
                  illustrationSize: GjaIllustrationSize.spot,
                  additionalContent: [GjaButton(text: 'Ok', onPress: () {})],
                ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da mensagem', () {
      final names = scenarioNames(
        'gja/widgets/gja-illustrated-message',
        'add-gja-illustrated-message',
      );
      expect(names, hasLength(13));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da mensagem', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_illustrated_message_$name',
          theme: theme,
          size: const Size(640, 560),
          child: GjaHBox(
            alignItems: GjaFlexAlignItems.start,
            items: [
              const SizedBox(
                width: 180,
                child: GjaIllustratedMessage(
                  title: 'Sem dados',
                  illustrationSize: GjaIllustrationSize.spot,
                ),
              ),
              SizedBox(
                width: 380,
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (_) => GjaIllustratedMessage(
                        title: 'Nenhum resultado',
                        description: 'Tente outros termos de busca.',
                        illustrationType: GjaIllustrationType.noSearchResults,
                        illustrationSize: GjaIllustrationSize.scene,
                        additionalContent: [
                          GjaButton(text: 'Limpar busca', onPress: () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Mensagem sem valor literal', () {
    final source = File(
      'lib/src/exibicao_dados/illustrated_message/gja_illustrated_message.dart',
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
