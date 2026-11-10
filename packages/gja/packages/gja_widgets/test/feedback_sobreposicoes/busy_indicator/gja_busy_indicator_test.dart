import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

Widget _app(Widget home, {GjaThemeData? theme}) => GjaApp(
  theme: theme,
  darkTheme: theme,
  home: Center(child: home),
);

/// Pontos (os círculos) do indicador.
Finder get _dots => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).shape == BoxShape.circle,
);

void main() {
  testWidgets('[API] Propriedades — Indicador mínimo', (tester) async {
    await tester.pumpWidget(_app(const GjaBusyIndicator()));
    expect(_dots, findsNWidgets(3));
    final first = tester.widget<DecoratedBox>(_dots.first);
    expect((first.decoration as BoxDecoration).color, _light.colors.brand);
    final y = tester.getCenter(_dots.at(0)).dy;
    expect(tester.getCenter(_dots.at(2)).dy, y);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('[API] Callbacks e controlador — Indicador sem ação', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const GjaBusyIndicator()));
    await tester.tap(find.byType(GjaBusyIndicator), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('[Comportamento] Animação — Pontos parados sem animação', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const GjaBusyIndicator(),
        theme: GjaThemeData.light().copyWith(
          animationMode: GjaAnimationMode.none,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    expect(_dots, findsNWidgets(3));
  });

  group('[Comportamento] Conteúdo ocupado', () {
    testWidgets('[Comportamento] Conteúdo ocupado — Conteúdo bloqueado', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _app(
          GjaBusyIndicator(
            child: GjaButton(text: 'Salvar', onPress: () => calls++),
          ),
        ),
      );
      await tester.tap(find.text('Salvar'), warnIfMissed: false);
      await tester.pump();
      expect(calls, 0);
      expect(_dots, findsNWidgets(3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('[Comportamento] Conteúdo ocupado — Conteúdo liberado', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _app(
          GjaBusyIndicator(
            busy: false,
            child: GjaButton(text: 'Salvar', onPress: () => calls++),
          ),
        ),
      );
      await tester.tap(find.text('Salvar'));
      expect(calls, 1);
      expect(_dots, findsNothing);
    });
  });

  testWidgets('[Aparência] Tokens de componente — Indicador com texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const GjaBusyIndicator(text: 'Carregando pedidos')),
    );
    expect(tester.getSize(_dots.first), Size.square(_light.spacing.s));
    final text = tester.getRect(find.text('Carregando pedidos'));
    final dots = tester.getRect(find.byType(Row).first);
    expect(text.top, greaterThanOrEqualTo(dots.bottom));
    expect(text.center.dx, closeTo(dots.center.dx, 0.5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('[Estados] Sem estados de interação — Indicador sem foco', (
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
            const GjaBusyIndicator(),
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
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('[Acessibilidade] Semântica — Semântica do indicador', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      GjaApp(
        locale: const Locale('pt', 'BR'),
        home: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GjaBusyIndicator(),
              GjaBusyIndicator(child: GjaText('Pedidos')),
            ],
          ),
        ),
      ),
    );
    final nodes = find.bySemanticsLabel('Carregando');
    expect(nodes, findsNWidgets(2));
    for (final e in nodes.evaluate()) {
      expect(
        tester.getSemantics(find.byWidget(e.widget)),
        containsSemantics(isLiveRegion: true),
      );
    }
    expect(find.bySemanticsLabel('Pedidos'), findsNothing);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('[Responsividade] Tamanho — Indicador sobre conteúdo grande', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const GjaBusyIndicator(child: SizedBox(width: 300, height: 200))),
    );
    final box = tester.getRect(find.byType(GjaBusyIndicator));
    expect(box.size, const Size(300, 200));
    expect(tester.getCenter(_dots.at(1)), box.center);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('[Integração] Dependências — Indicador sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaBusyIndicator(text: 'a'),
            GjaBusyIndicator(child: SizedBox(width: 100, height: 40)),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do indicador', () {
      final names = scenarioNames(
        'gja/widgets/gja-busy-indicator',
        'add-gja-busy-indicator',
      );
      expect(names, hasLength(14));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do indicador', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_busy_indicator_$name',
          theme: theme.copyWith(animationMode: GjaAnimationMode.none),
          size: const Size(360, 300),
          child: const GjaVBox(
            gap: GjaSpace.l,
            items: [
              GjaBusyIndicator(),
              GjaBusyIndicator(text: 'Carregando pedidos'),
              GjaBusyIndicator(
                child: SizedBox(
                  width: 240,
                  height: 80,
                  child: GjaContainer(
                    surface: GjaSurface.header,
                    child: Center(child: GjaText('Conteúdo')),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Indicador sem valor literal', () {
    final source = File(
      'lib/src/feedback_sobreposicoes/busy_indicator/gja_busy_indicator.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaBusyIndicator\(\{(.*?)\}\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    final fields = RegExp(r'^  final (\S+) (\w+);$', multiLine: true)
        .allMatches(source.substring(0, source.indexOf('class _Dots')))
        .map((m) => m.group(1)!);
    expect(ctor, isNotEmpty);
    for (final type in fields) {
      expect(type, isNot(anyOf('double', 'Color', 'Duration')));
    }
  });
}
