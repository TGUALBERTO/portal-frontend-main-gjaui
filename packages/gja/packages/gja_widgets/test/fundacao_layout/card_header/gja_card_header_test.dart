import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

const _long =
    'Pedidos de compra pendentes de aprovação do gestor do centro de custo da '
    'unidade de compras corporativas e das filiais regionais';

/// Monta [child] numa área de [width], sob [direction] e escala de texto, sem
/// `GjaApp`.
Widget _host(
  Widget child, {
  double width = 360,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  GjaThemeData? theme,
}) => GjaTheme(
  data: theme ?? _light,
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

/// Cabeçalho completo, com [onPress] opcional.
GjaCardHeader _full({VoidCallback? onPress, Widget? toolbar}) =>
    GjaCardHeader(
      iconInitials: 'MB',
      title: 'Pedidos',
      statusText: '3 de 5',
      subtitle: 'Compras',
      dataTimestamp: 'Há 5 min',
      toolbar: toolbar,
      onPress: onPress,
    );

TextStyle _style(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

Color? _background(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(GjaInteractable),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

void main() {
  setUpAll(loadGjaFonts);

  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Cabeçalho completo', (tester) async {
      await tester.pumpWidget(
        _host(
          _full(
            toolbar: const SizedBox(key: Key('toolbar'), width: 24, height: 24),
          ),
        ),
      );
      final icon = tester.getRect(find.byType(GjaAvatar));
      final title = tester.getRect(find.text('Pedidos'));
      final status = tester.getRect(find.text('3 de 5'));
      final subtitle = tester.getRect(find.text('Compras'));
      final date = tester.getRect(find.text('Há 5 min'));
      final toolbar = tester.getRect(find.byKey(const Key('toolbar')));
      expect(icon.left, _light.spacing.l);
      expect(icon.right, lessThanOrEqualTo(title.left));
      expect(title.top, lessThan(subtitle.top));
      expect(status.right, lessThanOrEqualTo(toolbar.left));
      expect(status.top, lessThan(subtitle.top));
      expect(date.top, greaterThan(status.bottom));
      expect(date.right, closeTo(status.right, 0.01));
      expect(toolbar.right, 360 - _light.spacing.l);
    });

    test('[API] Propriedades — Linhas inválidas no cabeçalho', () {
      expect(
        () => GjaCardHeader(titleMaxLines: int.parse('0')),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('"titleMaxLines"'),
          ),
        ),
      );
    });
  });

  testWidgets('[API] Ícone do cabeçalho — Ícone por iniciais', (tester) async {
    await tester.pumpWidget(
      _host(
        const GjaCardHeader(
          title: 'Pedidos',
          iconInitials: 'MB',
          iconDisplayShape: GjaAvatarShape.square,
        ),
      ),
    );
    final avatar = tester.widget<GjaAvatar>(find.byType(GjaAvatar));
    expect(avatar.initials, 'MB');
    expect(avatar.shape, GjaAvatarShape.square);
    expect(avatar.size, GjaAvatarSize.s);
    await tester.pumpWidget(
      _host(
        const GjaCardHeader(
          title: 'Pedidos',
          iconInitials: 'MB',
          iconVisible: false,
        ),
      ),
    );
    expect(find.byType(GjaAvatar), findsNothing);
  });

  testWidgets('[API] Callbacks e controlador — Cabeçalho acionado', (
    tester,
  ) async {
    var calls = 0;
    var toolbarCalls = 0;
    await tester.pumpWidget(
      _host(
        _full(
          onPress: () => calls++,
          toolbar: GjaButton(
            icon: GjaIcons.overflow,
            tooltip: 'Mais',
            onPress: () => toolbarCalls++,
            type: GjaButtonType.transparent,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pedidos'));
    await tester.tap(find.byType(GjaButton));
    await tester.pump();
    expect(calls, 1);
    expect(toolbarCalls, 1);
  });

  group('[Comportamento] Linhas dos textos', () {
    testWidgets(
      '[Comportamento] Linhas dos textos — Título longo no cabeçalho',
      (tester) async {
        await tester.pumpWidget(
          _host(width: 280, const GjaCardHeader(title: _long)),
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(_long),
        );
        expect(tester.widget<Text>(find.text(_long)).maxLines, 3);
        expect(paragraph.didExceedMaxLines, isTrue);
      },
    );

    testWidgets('[Comportamento] Linhas dos textos — Status oculto', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const GjaCardHeader(
            title: 'Pedidos',
            statusText: '3 de 5',
            statusVisible: false,
          ),
        ),
      );
      expect(find.text('3 de 5'), findsNothing);
    });
  });

  testWidgets('[Aparência] Tokens de componente — Estilos do cabeçalho', (
    tester,
  ) async {
    for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
      await tester.pumpWidget(
        _host(
          theme: theme,
          KeyedSubtree(key: ValueKey(theme), child: _full()),
        ),
      );
      final t = theme.typography;
      final c = theme.colors;
      final title = _style(tester, 'Pedidos');
      expect(title.fontSize, t.header5.fontSize);
      expect(title.fontWeight, t.header5.fontWeight);
      expect(title.color, c.text);
      expect(_style(tester, 'Compras').fontSize, t.base.fontSize);
      expect(_style(tester, 'Compras').color, c.label);
      for (final small in ['3 de 5', 'Há 5 min']) {
        expect(_style(tester, small).fontSize, t.small.fontSize, reason: small);
        expect(_style(tester, small).color, c.label, reason: small);
      }
    }
  });

  group('[Estados] Cabeçalho acionável', () {
    testWidgets(
      '[Estados] Cabeçalho acionável — Cabeçalho do cartão em hover',
      (tester) async {
        await tester.pumpWidget(_host(_full(onPress: () {})));
        final list = GjaControlColors.of(
          GjaControlFamily.list,
          _light.colors,
        );
        expect(_background(tester), list.normal.background);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Pedidos')));
        await tester.pump();
        expect(_background(tester), list.hover.background);
      },
    );

    testWidgets(
      '[Estados] Cabeçalho acionável — Cabeçalho sem ação não recebe foco',
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
                const GjaCardHeader(title: 'Pedidos'),
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

  testWidgets('[Acessibilidade] Teclado — Cabeçalho do cartão pelo teclado', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 360, child: _full(onPress: () => calls++)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('[Acessibilidade] Semântica — Semântica do cabeçalho', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        GjaCard(
          headingLevel: GjaTitleLevel.h2,
          header: GjaCardHeader(
            title: 'Pedidos',
            subtitle: 'Compras',
            onPress: () {},
          ),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.byType(GjaInteractable))
        .getSemanticsData();
    expect(data.label, 'Pedidos, Compras');
    expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(data.headingLevel, 2);
    handle.dispose();
  });

  // "Contraste e alvo do cabeçalho" fica em gja_card_header_a11y_test.dart,
  // sem a fonte real: a diretriz de contraste mede pixels e precisa dos
  // glifos sólidos da fonte de teste padrão.

  group('[Responsividade] Direção e escala', () {
    testWidgets('[Responsividade] Direção e escala — Cabeçalho em RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          direction: TextDirection.rtl,
          const GjaCardHeader(
            title: 'Pedidos',
            iconInitials: 'MB',
            statusText: '3 de 5',
          ),
        ),
      );
      final l = _light.spacing.l;
      expect(tester.getRect(find.byType(GjaAvatar)).right, 360 - l);
      expect(tester.getRect(find.text('3 de 5')).left, l);
    });

    testWidgets(
      '[Responsividade] Direção e escala — Cabeçalho com escala de texto 2,0',
      (tester) async {
        await tester.pumpWidget(_host(width: 300, textScale: 2, _full()));
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('[Integração] Dependências — Cabeçalho sem Material', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 360, child: _full(onPress: () => calls++)),
        ),
      ),
    );
    await tester.tap(find.text('Pedidos'));
    await tester.pump();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test(
      '[Testes] Cobertura exigida — Rastreabilidade do cabeçalho de cartão',
      () {
        final names = scenarioNames(
          'gja/widgets/gja-card-header',
          'update-gja-card-fiori-card-header',
        );
        expect(names, hasLength(19));
        expect(untestedScenarios(names), isEmpty);
      },
    );

    testWidgets(
      '[Testes] Cobertura exigida — Goldens do cabeçalho de cartão',
      (tester) async {
        for (final (name, theme) in goldenThemes) {
          await expectGolden(
            tester,
            name: 'gja_card_header_$name',
            theme: theme,
            size: const Size(440, 320),
            child: SizedBox(
              width: 400,
              child: Column(
                spacing: 16,
                children: [
                  _full(),
                  _full(onPress: () {}),
                ],
              ),
            ),
          );
          // Hover no cabeçalho acionável.
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(
            location: tester.getCenter(find.byType(GjaInteractable)),
          );
          await tester.pump();
          await expectLater(
            find.byKey(const Key('golden')),
            matchesGoldenFile('goldens/gja_card_header_hover_$name.png'),
          );
          await mouse.removePointer();
        }
      },
      tags: ['golden'],
    );
  });

  test('[Restrições] Fora do escopo — Cabeçalho sem valor literal', () {
    final file = File(
      'lib/src/fundacao_layout/card_header/gja_card_header.dart',
    ).readAsStringSync();
    final source = file.substring(
      file.indexOf('class GjaCardHeader '),
      file.indexOf('class GjaCardHeadingScope'),
    );
    for (final field in RegExp(
      r'^  final (\S+) \w+;$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!)) {
      expect(field, isNot(anyOf('double', 'double?', 'Color', 'Color?')));
    }
  });
}
