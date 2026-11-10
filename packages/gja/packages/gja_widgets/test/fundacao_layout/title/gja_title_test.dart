import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';
import '../../support/traceability.dart';

const _long =
    'Pedidos de compra em aberto aguardando aprovação do centro de custo';

/// Monta [child] sob [theme] em LTR, sem `GjaApp`.
Widget _themed(Widget child, {GjaThemeData? theme}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

/// Monta [child] numa coluna de largura [width], alinhada ao topo.
Widget _column(double width, Widget child, {GjaThemeData? theme}) => _themed(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: child),
  ),
  theme: theme,
);

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

TextStyle _style(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

SemanticsData _semantics(WidgetTester tester, String text) =>
    tester.getSemantics(find.text(text)).getSemanticsData();

/// Estilo da tipografia de cada `titleStyle` (spec, "[Aparência] Estilo e
/// cor").
const _styles = {
  GjaTitleLevel.auto: 'header5',
  GjaTitleLevel.h1: 'header1',
  GjaTitleLevel.h2: 'header2',
  GjaTitleLevel.h3: 'header3',
  GjaTitleLevel.h4: 'header4',
  GjaTitleLevel.h5: 'header5',
  GjaTitleLevel.h6: 'header6',
};

/// Amostra dos goldens: os sete estilos e um título truncado.
Widget _sample() => SizedBox(
  width: 320,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final style in GjaTitleLevel.values)
        GjaTitle('Título ${style.name}', titleStyle: style),
      const GjaTitle(_long, titleStyle: GjaTitleLevel.h3),
    ],
  ),
);

void main() {
  setUpAll(loadGjaFonts);

  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Uso mínimo', (tester) async {
      final handle = tester.ensureSemantics();
      final theme = GjaThemeData.light();
      await tester.pumpWidget(
        GjaApp(
          themeMode: GjaThemeMode.light,
          home: const Center(child: GjaTitle('Pedidos em aberto')),
        ),
      );
      final style = _style(tester, 'Pedidos em aberto');
      expect(style.fontSize, theme.typography.header5.fontSize);
      expect(style.color, theme.colors.text);
      expect(tester.widget<Text>(find.text('Pedidos em aberto')).maxLines, 1);
      final data = _semantics(tester, 'Pedidos em aberto');
      expect(data.hasFlag(SemanticsFlag.isHeader), isTrue);
      expect(data.headingLevel, 2);
      handle.dispose();
    });

    test('[API] Propriedades — Níveis do título', () {
      expect(GjaTitleLevel.values.map((l) => l.name), [
        'auto',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
      ]);
    });
  });

  testWidgets('[API] Callbacks e controlador — Título sem ação', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_themed(const Center(child: GjaTitle('Total'))));
    await tester.tap(find.text('Total'));
    await tester.pump();
    expect(_semantics(tester, 'Total').hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  group('[Comportamento] Nível separado do estilo', () {
    testWidgets(
      '[Comportamento] Nível separado do estilo — Nível sem efeito no estilo',
      (tester) async {
        final handle = tester.ensureSemantics();
        final theme = GjaThemeData.light();
        await tester.pumpWidget(
          _themed(const GjaTitle('Pedidos', level: GjaTitleLevel.h1)),
        );
        expect(
          _style(tester, 'Pedidos').fontSize,
          theme.typography.header5.fontSize,
        );
        final data = _semantics(tester, 'Pedidos');
        expect(data.hasFlag(SemanticsFlag.isHeader), isTrue);
        expect(data.headingLevel, 1);
        handle.dispose();
      },
    );

    testWidgets(
      '[Comportamento] Nível separado do estilo — Nível automático pelo estilo',
      (tester) async {
        final handle = tester.ensureSemantics();
        final theme = GjaThemeData.light();
        await tester.pumpWidget(
          _themed(const GjaTitle('Pedidos', titleStyle: GjaTitleLevel.h4)),
        );
        expect(
          _style(tester, 'Pedidos').fontSize,
          theme.typography.header4.fontSize,
        );
        final data = _semantics(tester, 'Pedidos');
        expect(data.hasFlag(SemanticsFlag.isHeader), isTrue);
        expect(data.headingLevel, 4);
        handle.dispose();
      },
    );
  });

  group('[Comportamento] Quebra de linhas', () {
    testWidgets('[Comportamento] Quebra de linhas — Título truncado', (
      tester,
    ) async {
      await tester.pumpWidget(_column(200, const GjaTitle('x')));
      final line = _paragraph(tester, 'x').size.height;
      await tester.pumpWidget(_column(200, const GjaTitle(_long)));
      final cut = _paragraph(tester, _long);
      expect(cut.didExceedMaxLines, isTrue);
      expect(cut.size.height, closeTo(line, 0.5));
      expect(
        tester.widget<Text>(find.text(_long)).overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('[Comportamento] Quebra de linhas — Título com quebra', (
      tester,
    ) async {
      await tester.pumpWidget(_column(200, const GjaTitle('x')));
      final line = _paragraph(tester, 'x').size.height;
      await tester.pumpWidget(
        _column(200, const GjaTitle(_long, wrapping: true)),
      );
      final paragraph = _paragraph(tester, _long);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.height, greaterThanOrEqualTo(line * 2 - 0.5));
    });
  });

  group('[Aparência] Estilo e cor', () {
    testWidgets('[Aparência] Estilo e cor — Estilos do título', (tester) async {
      final theme = GjaThemeData.light();
      for (final MapEntry(key: level, value: name) in _styles.entries) {
        final text = 'Título ${level.name}';
        await tester.pumpWidget(_themed(GjaTitle(text, titleStyle: level)));
        final expected = theme.typography.styles[name]!;
        final style = _style(tester, text);
        expect(style.fontSize, expected.fontSize, reason: text);
        expect(style.height, expected.height, reason: text);
        expect(style.fontWeight, expected.fontWeight, reason: text);
        expect(style.color, theme.colors.text, reason: text);
      }
    });

    testWidgets('[Aparência] Estilo e cor — Troca de tema do título', (
      tester,
    ) async {
      final light = GjaThemeData.light();
      final dark = GjaThemeData.dark();
      Widget app(GjaThemeData theme) =>
          _themed(const Center(child: GjaTitle('Pedidos')), theme: theme);
      await tester.pumpWidget(app(light));
      expect(_style(tester, 'Pedidos').color, light.colors.text);
      await tester.pumpWidget(app(dark));
      await tester.pumpAndSettle();
      expect(_style(tester, 'Pedidos').color, dark.colors.text);
    });
  });

  testWidgets('[Estados] Sem estados de interação — Título não recebe foco', (
    tester,
  ) async {
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
            const GjaTitle('Entre os dois'),
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
  });

  testWidgets(
    '[Acessibilidade] Teclado e foco — Teclas ignoradas pelo título',
    (tester) async {
      await tester.pumpWidget(
        const GjaApp(home: Center(child: GjaTitle('Somente leitura'))),
      );
      for (final key in [
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      expect(find.text('Somente leitura'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets(
      '[Acessibilidade] Semântica e contraste — Leitor de tela no título',
      (tester) async {
        final handle = tester.ensureSemantics();
        const text = 'Pedidos em aberto';
        await tester.pumpWidget(
          _column(60, const GjaTitle(text, level: GjaTitleLevel.h2)),
        );
        expect(_paragraph(tester, text).didExceedMaxLines, isTrue);
        final data = _semantics(tester, text);
        expect(data.label, text);
        expect(data.hasFlag(SemanticsFlag.isHeader), isTrue);
        expect(data.headingLevel, 2);
        handle.dispose();
      },
    );

    // "Contraste do título" fica em gja_title_contrast_test.dart, sem a
    // fonte real: a diretriz de contraste mede pixels e precisa dos glifos
    // sólidos da fonte de teste padrão.

    testWidgets(
      '[Acessibilidade] Semântica e contraste — Título com escala de texto 2,0',
      (tester) async {
        final theme = GjaThemeData.light();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: _column(320, const GjaTitle(_long, wrapping: true)),
          ),
        );
        expect(tester.takeException(), isNull);
        final size = theme.typography.header5.fontSize!;
        expect(_paragraph(tester, _long).textScaler.scale(size), size * 2);
      },
    );
  });

  testWidgets(
    '[Responsividade] Tamanhos de tela e densidade — Título na densidade compacta',
    (tester) async {
      await tester.pumpWidget(
        _themed(
          const Row(
            children: [
              GjaTitle('confortável'),
              GjaTheme.density(
                density: GjaDensity.compact,
                child: GjaTitle('compacta'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_style(tester, 'compacta'), _style(tester, 'confortável'));
    },
  );

  testWidgets('[Integração] Dependências — Título sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaApp(
        home: ListView(
          children: [
            for (final style in GjaTitleLevel.values)
              GjaTitle(style.name, titleStyle: style),
          ],
        ),
      ),
    );
    expect(find.byType(GjaTitle), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    testWidgets('[Testes] Cobertura exigida — Goldens dos estilos', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_title_$name',
          theme: theme,
          child: _sample(),
        );
      }
    }, tags: ['golden']);

    test('[Testes] Cobertura exigida — Rastreabilidade do título', () {
      final names = scenarioNames(
        'gja/widgets/gja-title',
        'update-gja-text-fiori-title-text-label',
      );
      expect(names, hasLength(20));
      expect(untestedScenarios(names), isEmpty);
    });
  });

  test('[Restrições] Fora do escopo — Título sem cor arbitrária', () {
    final source = File(
      'lib/src/fundacao_layout/title/gja_title.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaTitle\((.*?)\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    for (final name in ['Color', 'TextStyle', 'maxLines', 'child']) {
      expect(ctor, isNot(contains(name)), reason: name);
    }
    final fields = RegExp(
      r'^  final (\w+\??) ',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!.replaceAll('?', ''));
    for (final type in ['Color', 'TextStyle', 'Widget', 'int']) {
      expect(fields, isNot(contains(type)), reason: type);
    }
  });
}
