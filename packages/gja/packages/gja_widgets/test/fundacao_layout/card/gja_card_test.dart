import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

/// Monta [child] numa área de [width], sob [direction] e escala de texto, sem
/// `GjaApp`.
Widget _host(
  Widget child, {
  double width = 360,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  GjaThemeData? theme,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

Widget _box(String key, [double height = 24]) =>
    SizedBox(key: Key(key), height: height);

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

/// Linha entre o cabeçalho e o conteúdo.
Finder get _line => find.descendant(
  of: find.byType(GjaCard),
  matching: find.byType(GjaSeparator),
);

const _header = GjaCardHeader(
  key: Key('header'),
  iconInitials: 'MB',
  title: 'Pedidos pendentes',
  subtitle: 'Compras',
  statusText: '3 de 5',
);

final _light = GjaThemeData.light();

void main() {
  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Cartão com cabeçalho', (tester) async {
      await tester.pumpWidget(
        _host(GjaCard(header: _header, content: _box('content'))),
      );
      final header = _rect(tester, 'header');
      final line = tester.getRect(_line);
      final content = _rect(tester, 'content');
      expect(header.bottom, lessThanOrEqualTo(line.top));
      expect(line.bottom, lessThanOrEqualTo(content.top));
      expect(line.height, const BorderSide().width);
    });

    testWidgets('[API] Propriedades — Cartão sem cabeçalho', (tester) async {
      await tester.pumpWidget(_host(GjaCard(content: _box('content'))));
      final card = tester.getRect(find.byType(GjaCard));
      final content = _rect(tester, 'content');
      expect(_line, findsNothing);
      // Só a borda separa o conteúdo do topo do cartão.
      expect(content.top - card.top, lessThanOrEqualTo(1));
      expect(content.left - card.left, lessThanOrEqualTo(1));
    });
  });

  testWidgets('[API] Callbacks e controlador — Cabeçalho acionável', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        GjaCard(
          header: GjaCardHeader(title: 'Pedidos', onPress: () => calls++),
          content: _box('content', 60),
        ),
      ),
    );
    await tester.tap(find.text('Pedidos'));
    await tester.tap(find.byKey(const Key('content')));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets(
    '[Comportamento] Largura e texto — Cartão na largura disponível',
    (tester) async {
      const long =
          'Pedidos pendentes de aprovação do gestor do centro de custo da '
          'unidade de compras corporativas e das filiais regionais do grupo';
      await tester.pumpWidget(
        _host(
          width: 300,
          GjaCard(
            header: const GjaCardHeader(title: long),
            content: _box('content'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(GjaCard)).width, 300);
      expect(tester.widget<Text>(find.text(long)).maxLines, 3);
    },
  );

  testWidgets('[Comportamento] Posição do cabeçalho — Cabeçalho embaixo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        GjaCard(
          header: _header,
          headerPosition: GjaCardHeaderPosition.bottom,
          content: _box('content'),
        ),
      ),
    );
    final content = _rect(tester, 'content');
    final line = tester.getRect(_line);
    final header = _rect(tester, 'header');
    expect(content.bottom, lessThanOrEqualTo(line.top));
    expect(line.bottom, lessThanOrEqualTo(header.top));
  });

  group('[Aparência] Superfície e cabeçalho', () {
    testWidgets('[Aparência] Superfície e cabeçalho — Superfície do cartão', (
      tester,
    ) async {
      for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
        await tester.pumpWidget(
          _host(
            theme: theme,
            GjaCard(
              key: ValueKey(theme.brightness),
              header: _header,
              content: _box('content'),
            ),
          ),
        );
        final container = tester.widget<GjaContainer>(
          find
              .descendant(
                of: find.byType(GjaCard),
                matching: find.byType(GjaContainer),
              )
              .first,
        );
        expect(container.surface, GjaSurface.base);
        expect(container.border, isTrue);
        expect(container.radius, GjaRadius.tile);
        expect(container.shadow, GjaShadow.card);
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(GjaCard),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.color, theme.colors.base);
        expect(
          (decoration.border! as Border).top.color,
          theme.colors.separator,
        );
        expect(
          decoration.borderRadius,
          BorderRadius.circular(theme.radius.tile),
        );
        expect(decoration.boxShadow, isNotEmpty);
      }
    });

    testWidgets('[Aparência] Superfície e cabeçalho — Conteúdo sem margem', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(GjaCard(header: _header, content: _box('content'))),
      );
      final card = tester.getRect(find.byType(GjaCard));
      final content = _rect(tester, 'content');
      expect(content.left - card.left, lessThanOrEqualTo(1));
      expect(card.right - content.right, lessThanOrEqualTo(1));
      expect(content.top, tester.getRect(_line).bottom);
    });
  });

  group('[Estados] Interação do cabeçalho', () {
    testWidgets('[Estados] Interação do cabeçalho — Cabeçalho em hover', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          GjaCard(
            header: GjaCardHeader(title: 'Pedidos', onPress: () {}),
            content: _box('content'),
          ),
        ),
      );
      final list = GjaControlColors.of(
        GjaControlFamily.list,
        _light.colors,
      );
      Color? header() => tester
          .widget<ColoredBox>(
            find
                .descendant(
                  of: find.byType(GjaInteractable),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(500, 500));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Pedidos')));
      await tester.pump();
      expect(header(), list.hover.background);
      await mouse.moveTo(const Offset(500, 500));
      await tester.pump();
      expect(header(), list.normal.background);
    });

    testWidgets(
      '[Estados] Interação do cabeçalho — Cartão sem ação não recebe foco',
      (tester) async {
        final first = FocusNode();
        final second = FocusNode();
        addTearDown(first.dispose);
        addTearDown(second.dispose);
        await tester.pumpWidget(
          GjaApp(
            home: Column(
              children: [
                Focus(
                  focusNode: first,
                  child: const SizedBox(width: 20, height: 20),
                ),
                const GjaCard(header: _header),
                Focus(
                  focusNode: second,
                  child: const SizedBox(width: 20, height: 20),
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
      },
    );
  });

  testWidgets('[Acessibilidade] Teclado — Cabeçalho pelo teclado', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            child: GjaCard(
              header: GjaCardHeader(title: 'Pedidos', onPress: () => calls++),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('[Acessibilidade] Semântica — Semântica do cartão', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        GjaCard(
          header: GjaCardHeader(
            title: 'Pedidos',
            subtitle: 'Compras',
            onPress: () {},
          ),
          content: const GjaText('3 pedidos aguardando aprovação'),
        ),
      ),
    );
    final header = tester
        .getSemantics(find.byType(GjaInteractable))
        .getSemanticsData();
    expect(header.label, 'Pedidos, Compras');
    expect(header.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(header.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(header.headingLevel, 3);
    expect(
      find.semantics.byLabel('3 pedidos aguardando aprovação'),
      findsOneWidget,
    );
    handle.dispose();
  });

  // "Contraste e alvo do cartão" fica em gja_card_a11y_test.dart, sem a
  // fonte real: a diretriz de contraste mede pixels e precisa dos glifos
  // sólidos da fonte de teste padrão.

  group('[Responsividade] Direção e escala', () {
    testWidgets('[Responsividade] Direção e escala — Cartão em RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(direction: TextDirection.rtl, const GjaCard(header: _header)),
      );
      final card = tester.getRect(find.byType(GjaCard));
      final icon = tester.getRect(find.byType(GjaAvatar));
      final status = tester.getRect(find.text('3 de 5'));
      expect(card.right - icon.right, lessThan(card.width / 4));
      expect(status.left - card.left, lessThan(card.width / 4));
    });

    testWidgets(
      '[Responsividade] Direção e escala — Cartão com escala de texto 2,0',
      (tester) async {
        await tester.pumpWidget(
          _host(
            width: 300,
            textScale: 2,
            const GjaCard(
              header: _header,
              content: GjaText('3 pedidos aguardando aprovação'),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('[Integração] Dependências — Cartões numa grade sem Material', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      GjaApp(
        home: GjaGrid(
          content: [
            GjaCard(
              header: GjaCardHeader(title: 'Pedidos', onPress: () => calls++),
              content: _box('a'),
            ),
            GjaCard(header: _header, content: _box('b')),
            GjaCard(content: _box('c')),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Pedidos'));
    await tester.pump();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do cartão', () {
      final names = scenarioNames('gja/widgets/gja-card', 'add-gja-card');
      expect(names, hasLength(19));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do cartão', (
      tester,
    ) async {
      Widget body(String text) =>
          GjaSpacing.padding(all: GjaSpace.l, child: GjaText(text));
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_card_$name',
          theme: theme,
          size: const Size(440, 640),
          surface: GjaSurface.background,
          child: SizedBox(
            width: 400,
            child: Column(
              spacing: 16,
              children: [
                GjaCard(
                  header: GjaCardHeader(
                    iconInitials: 'MB',
                    title: 'Pedidos pendentes',
                    subtitle: 'Compras',
                    statusText: '3 de 5',
                    onPress: () {},
                  ),
                  content: body('3 pedidos aguardando aprovação.'),
                ),
                GjaCard(
                  header: const GjaCardHeader(
                    title: 'Entregas',
                    dataTimestamp: 'Há 5 min',
                  ),
                  headerPosition: GjaCardHeaderPosition.bottom,
                  content: body('2 entregas previstas para hoje.'),
                ),
                GjaCard(content: body('Cartão sem cabeçalho.')),
              ],
            ),
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Cartão sem valor literal', () {
    final file = File(
      'lib/src/fundacao_layout/card/gja_card.dart',
    ).readAsStringSync();
    final source = file.substring(file.indexOf('class GjaCard '));
    for (final field in RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source)) {
      expect(
        field.group(1),
        isNot(anyOf('double', 'double?', 'Color', 'Color?')),
      );
      expect(
        field.group(2),
        isNot(anyOf('title', 'padded', 'onHeaderPressed')),
      );
    }
  });
}
