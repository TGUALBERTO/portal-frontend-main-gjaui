import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

/// App com um botão "Abrir" que abre [dialog] e guarda o resultado.
Widget _launcher(
  WidgetBuilder dialog, {
  List<Object?>? results,
  bool dismissible = true,
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => GjaApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  darkTheme: theme,
  density: theme?.density.density,
  builder: (context, child) =>
      Directionality(textDirection: direction, child: child!),
  home: Builder(
    builder: (context) => Center(
      child: GjaButton(
        text: 'Abrir',
        onPress: () async {
          final result = await GjaDialog.open<Object?>(
            context,
            builder: dialog,
            dismissible: dismissible,
          );
          results?.add(result);
        },
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

GjaDialog _simple(
  BuildContext context, {
  String title = 'Excluir pedido',
  GjaValueState state = GjaValueState.none,
}) => GjaDialog(
  title: title,
  state: state,
  content: const GjaText('O pedido 4711 será excluído.'),
  beginButton: GjaButton(
    text: 'Excluir',
    type: GjaButtonType.emphasized,
    onPress: () => Navigator.of(context).pop(true),
  ),
  endButton: GjaButton(
    text: 'Cancelar',
    onPress: () => Navigator.of(context).pop(false),
  ),
);

Finder get _panel => find
    .descendant(
      of: find.byType(GjaDialog),
      matching: find.byType(GjaContainer),
    )
    .first;

void main() {
  setUpAll(loadGjaFonts);

  testWidgets('[API] Propriedades — Diálogo mínimo', (tester) async {
    await tester.pumpWidget(_launcher(_simple));
    await _open(tester);
    final panel = tester.getRect(_panel);
    final screen = tester.getRect(find.byType(GjaApp));
    expect(panel.center.dx, closeTo(screen.center.dx, 1));
    expect(
      tester.getTopLeft(find.text('Excluir pedido')).dy,
      lessThan(tester.getTopLeft(find.text('O pedido 4711 será excluído.')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Excluir')).dy,
      greaterThan(
        tester.getTopLeft(find.text('O pedido 4711 será excluído.')).dy,
      ),
    );
  });

  test('[API] Nome válido — Diálogo sem nome', () {
    expect(() => GjaDialog(content: const SizedBox()), throwsAssertionError);
  });

  testWidgets('[API] Callbacks e controlador — Resultado do diálogo', (
    tester,
  ) async {
    final results = <Object?>[];
    await tester.pumpWidget(_launcher(_simple, results: results));
    await _open(tester);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.byType(GjaDialog), findsNothing);
    expect(results, [true]);
  });

  testWidgets('[Comportamento] Fechar com Esc — Esc no diálogo', (
    tester,
  ) async {
    final results = <Object?>[];
    await tester.pumpWidget(_launcher(_simple, results: results));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(GjaDialog), findsNothing);
    expect(results, [null]);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_launcher(_simple, dismissible: false));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(GjaDialog), findsOneWidget);
  });

  testWidgets('[Comportamento] Rodapé e rolagem — Conteúdo longo', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _launcher(
        (context) => GjaDialog(
          title: 'Longo',
          content: const SizedBox(height: 1000, child: GjaText('Início')),
          endButton: GjaButton(
            text: 'Fechar',
            onPress: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
    await _open(tester);
    final panel = tester.getRect(_panel);
    expect(panel.height, lessThanOrEqualTo(400));
    expect(tester.getRect(find.text('Longo')).top, greaterThanOrEqualTo(0));
    expect(tester.getRect(find.text('Fechar')).bottom, lessThanOrEqualTo(400));
    expect(
      find.descendant(
        of: find.byType(GjaDialog),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('[Aparência] Tokens de componente — Diálogo de erro', (
    tester,
  ) async {
    await tester.pumpWidget(
      _launcher((context) => _simple(context, state: GjaValueState.error)),
    );
    await _open(tester);
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(GjaDialog),
        matching: find.byIcon(GjaIcons.error),
      ),
    );
    expect(
      icon.color,
      _light.colors.stateColors(GjaValueState.error).foreground,
    );
    final container = tester.widget<GjaContainer>(_panel);
    expect(container.surface, GjaSurface.base);
    expect(container.shadow, GjaShadow.dialog);
    expect(container.radius, GjaRadius.element);
    expect(tester.getSize(_panel).width, _light.spacing.xxxl * 8);
  });

  testWidgets('[Estados] Foco preso — Foco no diálogo', (tester) async {
    await tester.pumpWidget(_launcher(_simple));
    await _open(tester);
    final seen = <String?>{};
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      seen.add(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<GjaButton>()
            ?.text,
      );
    }
    expect(seen, {'Excluir', 'Cancelar'});
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<GjaButton>()
          ?.text,
      'Abrir',
    );
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets(
      '[Acessibilidade] Semântica e contraste — Semântica do diálogo',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_launcher(_simple));
        await _open(tester);
        expect(
          tester.getSemantics(find.byType(GjaDialog)),
          containsSemantics(
            label: 'Excluir pedido',
            scopesRoute: true,
            namesRoute: true,
          ),
        );
        expect(
          tester.getSemantics(find.text('Excluir pedido')),
          containsSemantics(isHeader: true),
        );
        expect(find.semantics.byLabel('Abrir'), findsNothing);
        handle.dispose();
      },
    );
  });

  testWidgets('[Responsividade] Largura e direção — Diálogo em tela estreita', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_launcher(_simple));
    await _open(tester);
    expect(tester.getSize(_panel).width, 320 - 2 * _light.spacing.l);
  });

  testWidgets('[Integração] Dependências — Diálogo sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      _launcher((context) => _simple(context, state: GjaValueState.warning)),
    );
    await _open(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do diálogo', () {
      final names = scenarioNames(
        'gja/widgets/gja-dialog',
        'add-gja-dialog',
      );
      expect(names, hasLength(15));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do diálogo', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 400);
      addTearDown(tester.view.reset);
      for (final base in [
        ('light', GjaThemeData.light()),
        ('dark', GjaThemeData.dark()),
      ]) {
        for (final density in GjaDensity.values) {
          final theme = base.$2.withDensity(density);
          for (final (kind, state) in [
            ('standard', GjaValueState.none),
            ('error', GjaValueState.error),
          ]) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              _launcher(
                (context) => _simple(context, state: state),
                theme: theme,
              ),
            );
            await _open(tester);
            await expectLater(
              find.byType(GjaApp),
              matchesGoldenFile(
                'goldens/gja_dialog_${kind}_${base.$1}_${density.name}.png',
              ),
            );
          }
        }
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Diálogo sem valor literal', () {
    final source = File(
      'lib/src/feedback_sobreposicoes/dialog/gja_dialog.dart',
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
