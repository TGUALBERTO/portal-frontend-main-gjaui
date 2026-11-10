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
    'O pedido de compra 4711 aguarda aprovação do centro de custo antes de ser '
    'enviado ao fornecedor, e a entrega prevista depende da confirmação do '
    'estoque no depósito central.';

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

/// Altura de uma linha de `base` e número de linhas de [text].
Future<(double, int)> _lines(WidgetTester tester, String text) async {
  final height = _paragraph(tester, text).size.height;
  await tester.pumpWidget(_column(240, const GjaText('x')));
  final line = _paragraph(tester, 'x').size.height;
  return (line, (height / line).round());
}

/// Amostra dos goldens: texto livre, truncado em duas linhas e sem quebra.
Widget _sample() => const SizedBox(
  width: 320,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      GjaText(_long),
      GjaText(_long, maxLines: 2),
      GjaText(_long, wrapping: false),
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
          home: const Center(child: GjaText('Pedido 4711')),
        ),
      );
      final style = _style(tester, 'Pedido 4711');
      expect(style.fontSize, theme.typography.base.fontSize);
      expect(style.color, theme.colors.text);
      final text = tester.widget<Text>(find.text('Pedido 4711'));
      expect(text.maxLines, isNull);
      expect(text.softWrap, isTrue);
      expect(
        tester.getSemantics(find.text('Pedido 4711')),
        isNot(matchesSemantics(isHeader: true)),
      );
      handle.dispose();
    });

    test('[API] Propriedades — Linhas inválidas', () {
      expect(
        () => GjaText('x', maxLines: int.parse('0')),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('"maxLines"'),
          ),
        ),
      );
    });
  });

  testWidgets('[API] Callbacks e controlador — Sem ação', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_themed(const Center(child: GjaText('Total'))));
    await tester.tap(find.text('Total'));
    await tester.pump();
    final data = tester.getSemantics(find.text('Total')).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  group('[Comportamento] Limite de linhas', () {
    testWidgets('[Comportamento] Limite de linhas — Texto truncado', (
      tester,
    ) async {
      await tester.pumpWidget(_column(240, const GjaText(_long)));
      final (lineHeight, lines) = await _lines(tester, _long);
      expect(lines, greaterThanOrEqualTo(4));

      await tester.pumpWidget(
        _column(240, const GjaText(_long, maxLines: 2)),
      );
      final cut = _paragraph(tester, _long);
      expect(cut.didExceedMaxLines, isTrue);
      expect(cut.size.height, closeTo(lineHeight * 2, 0.5));
      expect(
        tester.widget<Text>(find.text(_long)).overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('[Comportamento] Limite de linhas — Texto livre', (
      tester,
    ) async {
      await tester.pumpWidget(_column(240, const GjaText(_long)));
      expect(_paragraph(tester, _long).didExceedMaxLines, isFalse);
      final (_, lines) = await _lines(tester, _long);
      expect(lines, greaterThanOrEqualTo(4));
    });

    testWidgets('[Comportamento] Limite de linhas — Texto sem quebra', (
      tester,
    ) async {
      await tester.pumpWidget(
        _column(240, const GjaText(_long, wrapping: false, maxLines: 3)),
      );
      final cut = _paragraph(tester, _long);
      final height = cut.size.height;
      expect(cut.didExceedMaxLines, isTrue);
      expect(
        tester.widget<Text>(find.text(_long)).overflow,
        TextOverflow.ellipsis,
      );
      final (lineHeight, _) = await _lines(tester, _long);
      expect(height, closeTo(lineHeight, 0.5));
    });
  });

  group('[Aparência] Estilo e cor do texto', () {
    testWidgets('[Aparência] Estilo e cor do texto — Troca de tema do texto', (
      tester,
    ) async {
      final light = GjaThemeData.light();
      final dark = GjaThemeData.dark();
      Widget app(GjaThemeData theme) =>
          _themed(const Center(child: GjaText('Total')), theme: theme);
      await tester.pumpWidget(app(light));
      expect(_style(tester, 'Total').color, light.colors.text);
      await tester.pumpWidget(app(dark));
      await tester.pumpAndSettle();
      expect(_style(tester, 'Total').color, dark.colors.text);
    });

    testWidgets('[Aparência] Estilo e cor do texto — Estilo do texto', (
      tester,
    ) async {
      final theme = GjaThemeData.light();
      await tester.pumpWidget(_themed(const GjaText('Total')));
      final base = theme.typography.base;
      final style = _style(tester, 'Total');
      expect(style.fontSize, base.fontSize);
      expect(style.height, base.height);
      expect(style.fontWeight, base.fontWeight);
      expect(style.color, theme.colors.text);
    });
  });

  testWidgets('[Estados] Sem estados de interação — Não recebe foco', (
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
            const GjaText('Entre os dois'),
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

  testWidgets('[Acessibilidade] Teclado e foco — Teclas ignoradas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GjaApp(home: Center(child: GjaText('Somente leitura'))),
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
  });

  group('[Acessibilidade] Semântica, contraste e escala de texto', () {
    testWidgets(
      '[Acessibilidade] Semântica, contraste e escala de texto — Leitor de tela',
      (tester) async {
        final handle = tester.ensureSemantics();
        const text = 'Pedidos em aberto no mês';
        await tester.pumpWidget(
          _column(60, const GjaText(text, maxLines: 1)),
        );
        expect(_paragraph(tester, text).didExceedMaxLines, isTrue);
        expect(
          tester.getSemantics(find.text(text)),
          matchesSemantics(label: text),
        );
        handle.dispose();
      },
    );

    // "Contraste do texto" fica em gja_text_contrast_test.dart, sem a
    // fonte real: a diretriz de contraste mede pixels e precisa dos glifos
    // sólidos da fonte de teste padrão.

    testWidgets(
      '[Acessibilidade] Semântica, contraste e escala de texto — Escala de texto 2,0',
      (tester) async {
        final theme = GjaThemeData.light();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: _column(320, const GjaText(_long)),
          ),
        );
        expect(tester.takeException(), isNull);
        final paragraph = _paragraph(tester, _long);
        expect(
          paragraph.textScaler.scale(theme.typography.base.fontSize!),
          theme.typography.base.fontSize! * 2,
        );
      },
    );
  });

  testWidgets(
    '[Responsividade] Tamanhos de tela e densidade — Densidade compacta',
    (tester) async {
      await tester.pumpWidget(
        _themed(
          const Row(
            children: [
              GjaText('confortável'),
              GjaTheme.density(
                density: GjaDensity.compact,
                child: GjaText('compacta'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_style(tester, 'compacta'), _style(tester, 'confortável'));
    },
  );

  testWidgets('[Integração] Dependências — Funciona sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaApp(
        home: ListView(
          children: const [
            GjaText(_long),
            GjaText(_long, maxLines: 2),
            GjaText(_long, wrapping: false),
          ],
        ),
      ),
    );
    expect(find.byType(GjaText), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura do texto', () {
    testWidgets('[Testes] Cobertura do texto — Goldens do texto', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_text_$name',
          theme: theme,
          child: _sample(),
        );
      }
    }, tags: ['golden']);

    test('[Testes] Cobertura do texto — Rastreabilidade', () {
      final names = scenarioNames('gja/widgets/gja-text', 'add-gja-text');
      expect(names, hasLength(19));
      expect(untestedScenarios(names), isEmpty);
    });
  });

  test('[Restrições] Fora do escopo — Sem cor arbitrária', () {
    final source = File(
      'lib/src/fundacao_layout/text/gja_text.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaText\((.*?)\)\s*:',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    for (final name in ['Color', 'TextStyle', 'TextSpan']) {
      expect(ctor, isNot(contains(name)), reason: name);
    }
    for (final name in ['tone', 'variant', 'heading']) {
      expect(ctor, isNot(contains('this.$name')), reason: name);
    }
    final fields = RegExp(
      r'^  final (\w+\??) ',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!.replaceAll('?', ''));
    for (final type in ['Color', 'TextStyle', 'TextSpan']) {
      expect(fields, isNot(contains(type)), reason: type);
    }
  });
}
