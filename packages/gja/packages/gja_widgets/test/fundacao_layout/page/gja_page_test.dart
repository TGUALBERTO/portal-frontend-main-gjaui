import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

/// Ajusta a janela de teste para [width] × [height].
void _view(WidgetTester tester, [double width = 800, double height = 600]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Monta [child] sob [theme] e [direction], sem `GjaApp`.
Widget _host(
  Widget child, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(textDirection: direction, child: child),
);

/// Barras da página, na ordem da árvore: a página monta a coluna de baixo
/// para cima, então o rodapé vem antes e o cabeçalho por último.
Finder get _bars => find.descendant(
  of: find.byType(GjaPage),
  matching: find.byType(GjaBar),
);

Finder get _header => _bars.last;

Finder get _footer => _bars.first;

Finder get _back => find.descendant(
  of: find.byType(GjaPage),
  matching: find.byType(GjaInteractable),
);

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

Widget _box(String key) => SizedBox(key: Key(key), width: 20, height: 20);

BoxDecoration _decoration(WidgetTester tester, Finder of) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(of: of, matching: find.byType(DecoratedBox))
                  .first,
            )
            .decoration
        as BoxDecoration;

/// Fundo pintado pela própria página.
Color? _background(WidgetTester tester) =>
    _decoration(tester, find.byType(GjaPage)).color;

final _light = GjaThemeData.light();

void main() {
  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Página mínima', (tester) async {
      _view(tester);
      await tester.pumpWidget(
        _host(
          const GjaPage(
            title: 'Pedidos',
            content: [SizedBox(key: Key('body'), height: 50)],
          ),
        ),
      );
      expect(find.text('Pedidos'), findsOneWidget);
      expect(_bars, findsOneWidget);
      expect(_rect(tester, 'body').top, tester.getRect(_bars).bottom);
      expect(find.byType(GjaButton), findsNothing);
    });

    testWidgets('[API] Propriedades — Página completa', (tester) async {
      _view(tester);
      await tester.pumpWidget(
        _host(
          GjaPage(
            title: 'Pedidos',
            showNavButton: true,
            onNavButtonPress: () {},
            headerContent: [_box('a1'), _box('a2')],
            subHeader: const SizedBox(key: Key('sub'), height: 40),
            footer: GjaBar(
              key: const Key('footer'),
              contentRight: [_box('f1')],
            ),
            content: const [SizedBox(key: Key('body'), height: 50)],
          ),
        ),
      );
      final back = tester.getRect(_back);
      final title = tester.getRect(find.text('Pedidos'));
      final a1 = _rect(tester, 'a1');
      final a2 = _rect(tester, 'a2');
      expect(back.right, lessThanOrEqualTo(title.left));
      expect(title.right, lessThanOrEqualTo(a1.left));
      expect(a1.right, lessThanOrEqualTo(a2.left));
      expect(_rect(tester, 'sub').top, tester.getRect(_header).bottom);
      expect(_rect(tester, 'footer').bottom, 600);
    });
  });

  testWidgets('[API] Propriedades do cabeçalho — Cabeçalho próprio', (
    tester,
  ) async {
    _view(tester);
    await tester.pumpWidget(
      _host(
        const GjaPage(
          title: 'Pedidos',
          customHeader: SizedBox(key: Key('custom'), height: 40),
        ),
      ),
    );
    expect(find.byKey(const Key('custom')), findsOneWidget);
    expect(find.text('Pedidos'), findsNothing);
  });

  group('[API] Áreas condicionais', () {
    testWidgets('[API] Áreas condicionais — Página sem cabeçalho', (
      tester,
    ) async {
      _view(tester);
      await tester.pumpWidget(
        _host(
          const GjaPage(
            title: 'Pedidos',
            showHeader: false,
            content: [SizedBox(key: Key('body'), height: 50)],
          ),
        ),
      );
      expect(_bars, findsNothing);
      expect(_rect(tester, 'body').top, 0);
    });

    testWidgets('[API] Áreas condicionais — Página sem rodapé', (tester) async {
      _view(tester);
      await tester.pumpWidget(
        _host(
          GjaPage(
            title: 'Pedidos',
            showFooter: false,
            footer: GjaBar(contentRight: [_box('f1')]),
            enableScrolling: false,
            content: const [SizedBox.expand(key: Key('body'))],
          ),
        ),
      );
      expect(find.byKey(const Key('f1')), findsNothing);
      expect(_rect(tester, 'body').bottom, 600);
    });
  });

  testWidgets('[API] Callbacks e controlador — Voltar', (tester) async {
    _view(tester);
    var calls = 0;
    await tester.pumpWidget(
      _host(
        GjaPage(
          title: 'Pedidos',
          showNavButton: true,
          onNavButtonPress: () => calls++,
        ),
      ),
    );
    await tester.tap(_back);
    await tester.pump();
    expect(calls, 1);
  });

  group('[Comportamento] Rolagem do conteúdo', () {
    testWidgets('[Comportamento] Rolagem do conteúdo — Conteúdo longo rola', (
      tester,
    ) async {
      _view(tester, 800, 800);
      await tester.pumpWidget(
        _host(
          GjaPage(
            title: 'Pedidos',
            footer: GjaBar(contentRight: [_box('f1')]),
            content: const [SizedBox(key: Key('body'), height: 3000)],
          ),
        ),
      );
      final header = tester.getRect(_header);
      final footer = tester.getRect(_footer);
      final top = _rect(tester, 'body').top;
      // Passa a tolerância de arraste, arrasta 500 e solta parado, sem
      // lançamento.
      final gesture = await tester.startGesture(const Offset(400, 400));
      await gesture.moveBy(const Offset(0, -kDragSlopDefault));
      await gesture.moveBy(const Offset(0, -500));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(top - _rect(tester, 'body').top, closeTo(500, kDragSlopDefault));
      expect(tester.getRect(_header), header);
      expect(tester.getRect(_footer), footer);
    });

    testWidgets(
      '[Comportamento] Rolagem do conteúdo — Conteúdo com rolagem própria',
      (tester) async {
        _view(tester);
        double? maxHeight;
        await tester.pumpWidget(
          _host(
            GjaPage(
              title: 'Pedidos',
              enableScrolling: false,
              footer: GjaBar(contentRight: [_box('f1')]),
              content: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    maxHeight = constraints.maxHeight;
                    return const SizedBox.expand(key: Key('body'));
                  },
                ),
              ],
            ),
          ),
        );
        final header = tester.getRect(_header);
        final footer = tester.getRect(_footer);
        expect(maxHeight!.isFinite, isTrue);
        expect(maxHeight, closeTo(footer.top - header.bottom, 0.01));
        expect(_rect(tester, 'body').height, closeTo(maxHeight!, 0.01));
      },
    );
  });

  group('[Comportamento] Espaçamento do conteúdo', () {
    testWidgets(
      '[Comportamento] Espaçamento do conteúdo — Conteúdo sem espaçamento',
      (tester) async {
        _view(tester, 1200);
        await tester.pumpWidget(
          _host(
            const GjaPage(
              title: 'Pedidos',
              content: [SizedBox(key: Key('body'), height: 50)],
            ),
          ),
        );
        final body = _rect(tester, 'body');
        expect(body.left, 0);
        expect(body.top, tester.getRect(_bars).bottom);
      },
    );

    testWidgets(
      '[Comportamento] Espaçamento do conteúdo — Espaçamento responsivo pela tela',
      (tester) async {
        for (final (width, side, top) in [
          (400.0, 0.0, 0.0),
          (800.0, 16.0, 16.0),
          (1200.0, 32.0, 16.0),
        ]) {
          _view(tester, width);
          await tester.pumpWidget(
            _host(
              GjaPage(
                key: ValueKey(width),
                title: 'Pedidos',
                contentPadding: GjaContentPadding.responsive,
                content: const [SizedBox(key: Key('body'), height: 50)],
              ),
            ),
          );
          final body = _rect(tester, 'body');
          expect(body.left, side, reason: '$width');
          expect(
            body.top - tester.getRect(_bars).bottom,
            top,
            reason: '$width',
          );
        }
      },
    );
  });

  testWidgets(
    '[Comportamento] Rodapé flutuante — Conteúdo sob o rodapé flutuante',
    (tester) async {
      _view(tester);
      await tester.pumpWidget(
        _host(
          GjaPage(
            title: 'Pedidos',
            floatingFooter: true,
            footer: GjaBar(
              key: const Key('footer'),
              contentRight: [_box('f1')],
            ),
            content: const [
              SizedBox(height: 2000),
              SizedBox(key: Key('end'), height: 20),
            ],
          ),
        ),
      );
      final s = _light.spacing.s;
      final footer = tester.getRect(find.byKey(const Key('footer')));
      expect(footer.bottom, 600 - s);
      expect(footer.left, s);
      expect(footer.right, 800 - s);
      expect(
        _decoration(tester, find.byKey(const Key('footer'))).borderRadius,
        BorderRadius.circular(_light.radius.s),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();
      expect(
        _rect(tester, 'end').bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(const Key('footer'))).top),
      );
    },
  );

  group('[Aparência] Fundo e cabeçalho', () {
    testWidgets('[Aparência] Fundo e cabeçalho — Fundo por backgroundDesign', (
      tester,
    ) async {
      _view(tester);
      for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
        for (final (design, expected) in [
          (GjaPageBackgroundDesign.standard, theme.colors.background),
          (GjaPageBackgroundDesign.solid, theme.colors.background),
          (GjaPageBackgroundDesign.list, theme.colors.base),
          (GjaPageBackgroundDesign.transparent, null),
        ]) {
          await tester.pumpWidget(
            _host(
              theme: theme,
              GjaPage(
                key: ValueKey((theme.brightness, design)),
                title: 'Pedidos',
                backgroundDesign: design,
              ),
            ),
          );
          expect(
            _background(tester),
            expected,
            reason: '${theme.brightness} ${design.name}',
          );
        }
      }
    });

    testWidgets('[Aparência] Fundo e cabeçalho — Título do cabeçalho', (
      tester,
    ) async {
      _view(tester);
      await tester.pumpWidget(
        _host(
          GjaPage(
            title: 'Pedidos',
            showNavButton: true,
            onNavButtonPress: () {},
          ),
        ),
      );
      final header = tester.widget<GjaBar>(_bars);
      expect(header.design, GjaBarDesign.header);
      expect(header.contentMiddle.single, isA<GjaTitle>());
      expect(
        tester.widget<Text>(find.text('Pedidos')).style!.fontSize,
        _light.typography.header5.fontSize,
      );
      expect(
        tester.getRect(find.text('Pedidos')).left,
        tester.getRect(_back).right + _light.spacing.xs,
      );
    });
  });

  testWidgets('[Estados] Botão de voltar — Botão de voltar em hover', (
    tester,
  ) async {
    _view(tester);
    await tester.pumpWidget(
      _host(
        GjaPage(
          title: 'Pedidos',
          showNavButton: true,
          onNavButtonPress: () {},
        ),
      ),
    );
    final transparent = GjaControlColors.of(
      GjaControlFamily.transparent,
      _light.colors,
    );
    expect(_decoration(tester, _back).color, transparent.normal.background);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_back));
    await tester.pump();
    expect(_decoration(tester, _back).color, transparent.hover.background);
  });

  group('[Acessibilidade] Teclado e foco', () {
    testWidgets('[Acessibilidade] Teclado e foco — Ordem de foco na página', (
      tester,
    ) async {
      _view(tester);
      final action = FocusNode();
      final item = FocusNode();
      final footer = FocusNode();
      addTearDown(() {
        action.dispose();
        item.dispose();
        footer.dispose();
      });
      Widget focusable(FocusNode node) =>
          Focus(focusNode: node, child: const SizedBox(width: 20, height: 20));
      await tester.pumpWidget(
        GjaApp(
          home: GjaPage(
            title: 'Pedidos',
            showNavButton: true,
            onNavButtonPress: () {},
            headerContent: [focusable(action)],
            footer: GjaBar(contentRight: [focusable(footer)]),
            content: [
              Align(alignment: Alignment.topLeft, child: focusable(item)),
            ],
          ),
        ),
      );
      final visited = <String>[];
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        visited.add(switch (focus) {
          _ when focus == action => 'cabeçalho',
          _ when focus == item => 'conteúdo',
          _ when focus == footer => 'rodapé',
          _
              when focus?.context
                      ?.findAncestorWidgetOfExactType<GjaInteractable>() !=
                  null =>
            'voltar',
          _ => '?',
        });
      }
      expect(visited, ['voltar', 'cabeçalho', 'conteúdo', 'rodapé']);
    });

    testWidgets('[Acessibilidade] Teclado e foco — Foco revela o conteúdo', (
      tester,
    ) async {
      _view(tester);
      final item = FocusNode();
      addTearDown(item.dispose);
      await tester.pumpWidget(
        GjaApp(
          home: GjaPage(
            title: 'Pedidos',
            content: [
              const SizedBox(height: 2000),
              Align(
                alignment: Alignment.topLeft,
                child: Focus(
                  focusNode: item,
                  child: const SizedBox(
                    key: Key('item'),
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(item.hasPrimaryFocus, isTrue);
      final rect = _rect(tester, 'item');
      expect(rect.top, greaterThanOrEqualTo(tester.getRect(_bars).bottom));
      expect(rect.bottom, lessThanOrEqualTo(600));
    });
  });

  testWidgets('[Responsividade] Largura e direção — Página em RTL', (
    tester,
  ) async {
    _view(tester);
    await tester.pumpWidget(
      _host(
        direction: TextDirection.rtl,
        GjaPage(
          title: 'Pedidos',
          showNavButton: true,
          onNavButtonPress: () {},
          headerContent: [_box('action')],
        ),
      ),
    );
    final edge = _light.spacing.s;
    expect(tester.getRect(_back).right, closeTo(800 - edge, 0.01));
    expect(_rect(tester, 'action').left, closeTo(edge, 0.01));
    expect(GjaIcons.navBack.matchTextDirection, isTrue);
  });

  testWidgets(
    '[Integração] Dependências de widgets e hospedeiro — Página na página de ferramentas',
    (tester) async {
      _view(tester, 1200, 800);
      await tester.pumpWidget(
        GjaApp(
          home: GjaToolPage(
            header: const GjaShellBar(title: 'Compras'),
            mainContents: [
              GjaPage(
                title: 'Pedidos',
                footer: GjaBar(contentRight: [_box('f1')]),
                content: const [GjaText('Pedidos em aberto')],
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final shell = tester.getRect(find.byType(GjaShellBar));
      expect(tester.getRect(_header).top, closeTo(shell.bottom, 0.01));
      expect(tester.getRect(_footer).bottom, 800);
    },
  );

  testWidgets(
    '[Integração] Dependências de núcleo e fundamentos — Página pelo tema da subárvore',
    (tester) async {
      _view(tester);
      final dark = GjaThemeData.dark();
      await tester.pumpWidget(
        GjaApp(
          home: GjaTheme(
            data: dark,
            child: const GjaPage(title: 'Pedidos'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester, _bars).color, dark.colors.base);
    },
  );

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da página', () {
      final names = scenarioNames('gja/widgets/gja-page', 'add-gja-page');
      expect(names, hasLength(25));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da página', (
      tester,
    ) async {
      for (final floating in [false, true]) {
        for (final (name, theme) in goldenThemes) {
          await expectGolden(
            tester,
            name: floating ? 'gja_page_floating_$name' : 'gja_page_$name',
            theme: theme,
            size: const Size(800, 600),
            surface: GjaSurface.none,
            child: GjaPage(
              title: 'Pedido 4711',
              showNavButton: true,
              onNavButtonPress: () {},
              headerContent: [
                GjaButton(
                  icon: GjaIcons.edit,
                  tooltip: 'Editar',
                  onPress: () {},
                  type: GjaButtonType.transparent,
                ),
              ],
              subHeader: const GjaBar(
                contentMiddle: [GjaLabel('Aguardando aprovação')],
              ),
              contentPadding: GjaContentPadding.responsive,
              floatingFooter: floating,
              footer: GjaBar(
                contentRight: [
                  GjaButton(
                    text: 'Salvar',
                    type: GjaButtonType.emphasized,
                    onPress: () {},
                  ),
                ],
              ),
              content: const [
                GjaTitle('Itens', titleStyle: GjaTitleLevel.h3),
                GjaText('3 itens, total de R\$ 1.250,00.'),
              ],
            ),
          );
        }
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Página sem valor literal', () {
    final file = File(
      'lib/src/fundacao_layout/page/gja_page.dart',
    ).readAsStringSync();
    final source = file.substring(file.indexOf('class GjaPage '));
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).toList();
    expect(fields, isNotEmpty);
    for (final field in fields) {
      expect(
        field.group(1),
        isNot(anyOf('double', 'double?', 'Color', 'Color?')),
      );
      expect(
        field.group(2),
        isNot(anyOf('subtitle', 'onBack', 'footerActions')),
      );
    }
  });
}
