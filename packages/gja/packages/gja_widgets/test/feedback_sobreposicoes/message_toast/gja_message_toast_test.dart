import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

/// App com um botão "Avisar" que mostra [message].
Widget _app(String message, {GjaThemeData? theme, VoidCallback? onBehind}) =>
    GjaApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      density: theme?.density.density,
      home: Builder(
        builder: (context) => Stack(
          children: [
            Center(
              child: GjaButton(
                text: 'Avisar',
                onPress: () => GjaMessageToast.show(context, message),
              ),
            ),
            if (onBehind != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBehind,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

Future<void> _show(WidgetTester tester) async {
  await tester.tap(find.text('Avisar'));
  // Quadro do toque, quadro que começa o esmaecimento e o fim dele.
  await tester.pump();
  await tester.pump();
  await tester.pump(_light.motion.medium);
}

/// Avança até o aviso sumir e o deixa sem tarefas pendentes.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(GjaMessageToast.defaultDuration);
  await tester.pumpAndSettle();
}

Finder _box(String message) => find
    .ancestor(of: find.text(message), matching: find.byType(DecoratedBox))
    .first;

void main() {
  setUpAll(loadGjaFonts);

  testWidgets('[API] Propriedades — Aviso mínimo', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app('Pedido salvo'));
    await _show(tester);
    final box = tester.getRect(_box('Pedido salvo'));
    expect(box.center.dx, closeTo(400, 0.5));
    expect(box.bottom, closeTo(600 - _light.spacing.xxxl, 0.5));
    await _finish(tester);
  });

  testWidgets('[API] Callbacks e controlador — Aviso vazio', (tester) async {
    await tester.pumpWidget(_app(''));
    await tester.tap(find.text('Avisar'));
    expect(tester.takeException(), isA<AssertionError>());
  });

  group('[Comportamento] Duração e substituição', () {
    testWidgets('[Comportamento] Duração e substituição — Aviso some sozinho', (
      tester,
    ) async {
      await tester.pumpWidget(_app('Pedido salvo'));
      await _show(tester);
      expect(find.text('Pedido salvo'), findsOneWidget);
      await _finish(tester);
      expect(find.text('Pedido salvo'), findsNothing);
    });

    testWidgets(
      '[Comportamento] Duração e substituição — Novo aviso substitui',
      (tester) async {
        await tester.pumpWidget(
          GjaApp(
            home: Builder(
              builder: (context) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GjaButton(
                    text: 'Um',
                    onPress: () => GjaMessageToast.show(context, 'Primeiro'),
                  ),
                  GjaButton(
                    text: 'Dois',
                    onPress: () => GjaMessageToast.show(context, 'Segundo'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.text('Um'));
        await tester.pump();
        await tester.tap(find.text('Dois'));
        await tester.pump();
        expect(find.text('Primeiro'), findsNothing);
        expect(find.text('Segundo'), findsOneWidget);
        await _finish(tester);
      },
    );
  });

  testWidgets('[Aparência] Tokens de componente — Cores do aviso', (
    tester,
  ) async {
    await tester.pumpWidget(_app('Pedido salvo'));
    await _show(tester);
    final box = tester.widget<DecoratedBox>(_box('Pedido salvo'));
    expect((box.decoration as BoxDecoration).color, _light.colors.text);
    expect(
      tester.widget<Text>(find.text('Pedido salvo')).style?.color,
      _light.colors.contrastText,
    );
    expect(
      tester.getSize(_box('Pedido salvo')).width,
      lessThanOrEqualTo(_light.spacing.xxxl * 5),
    );
    await _finish(tester);
  });

  testWidgets('[Estados] Sem interação — Toque passa pelo aviso', (
    tester,
  ) async {
    var behind = 0;
    await tester.pumpWidget(_app('Pedido salvo', onBehind: () => behind++));
    await _show(tester);
    await tester.tap(find.text('Pedido salvo'), warnIfMissed: false);
    expect(behind, 1);
    // O aviso fica fora do foco: nenhum nó dele pode recebê-lo.
    expect(
      find.ancestor(
        of: find.text('Pedido salvo'),
        matching: find.byType(ExcludeFocus),
      ),
      findsOneWidget,
    );
    await _finish(tester);
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets('[Acessibilidade] Semântica e contraste — Semântica do aviso', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app('Pedido salvo'));
      await _show(tester);
      final node = find.semantics.byLabel('Pedido salvo').evaluate().single;
      expect(
        node,
        containsSemantics(label: 'Pedido salvo', isLiveRegion: true),
      );
      await _finish(tester);
      handle.dispose();
    });

    testWidgets('[Acessibilidade] Semântica e contraste — Contraste do aviso', (
      tester,
    ) async {
      for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
        final c = theme.colors;
        expect(
          gjaContrastRatioOver(c.contrastText, c.text),
          greaterThanOrEqualTo(GjaAccessibility.minTextContrast),
          reason: theme.brightness.name,
        );
      }
    });
  });

  testWidgets('[Responsividade] Largura — Aviso em tela estreita', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(200, 600);
    addTearDown(tester.view.reset);
    const message =
        'O pedido 4711 foi salvo e enviado para aprovação do gestor.';
    await tester.pumpWidget(_app(message));
    await _show(tester);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(_box(message)).width,
      lessThanOrEqualTo(200 - 2 * _light.spacing.l),
    );
    await _finish(tester);
  });

  testWidgets('[Integração] Dependências — Aviso sem Material', (tester) async {
    await tester.pumpWidget(_app('Pedido salvo'));
    await _show(tester);
    await _finish(tester);
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do aviso', () {
      final names = scenarioNames(
        'gja/widgets/gja-message-toast',
        'add-gja-message-toast',
      );
      expect(names, hasLength(14));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do aviso', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(480, 320);
      addTearDown(tester.view.reset);
      for (final (themeName, base) in [
        ('light', GjaThemeData.light()),
        ('dark', GjaThemeData.dark()),
      ]) {
        for (final density in GjaDensity.values) {
          for (final (kind, message) in [
            ('short', 'Pedido salvo'),
            ('long', 'O pedido 4711 foi salvo e enviado para aprovação.'),
          ]) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              _app(message, theme: base.withDensity(density)),
            );
            await _show(tester);
            await expectLater(
              find.byType(GjaApp),
              matchesGoldenFile(
                'goldens/gja_message_toast_${kind}_${themeName}_${density.name}.png',
              ),
            );
            await _finish(tester);
          }
        }
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Aviso sem valor literal', () {
    final source = File(
      'lib/src/feedback_sobreposicoes/message_toast/gja_message_toast.dart',
    ).readAsStringSync();
    final show = RegExp(
      r'static void show\((.*?)\)',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    expect(show, isNot(contains('double')));
    expect(show, isNot(contains('Color')));
  });
}
