import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

/// Aplicação de teste com [home] centralizado.
Widget _app(
  Widget home, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) => GjaApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(textDirection: direction, child: child!),
  ),
  home: Center(child: home),
);

/// Caixa que guarda o próprio valor e registra cada `onSelect`.
Widget _stateful(List<bool> log, {bool initial = false, String? text}) {
  var selected = initial;
  return StatefulBuilder(
    builder: (context, setState) => GjaCheckBox(
      text: text ?? 'Aceito os termos',
      selected: selected,
      onSelect: (value) {
        log.add(value);
        setState(() => selected = value);
      },
    ),
  );
}

/// Quadrado pintado da caixa de [index].
Finder _square([int index = 0]) => find
    .descendant(
      of: find.byType(GjaCheckBox).at(index),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(_square(index)).decoration as BoxDecoration;

Color _border(WidgetTester tester, [int index = 0]) =>
    (_decoration(tester, index).border! as Border).top.color;

void main() {
  testWidgets('[API] Propriedades — Caixa mínima', (tester) async {
    await tester.pumpWidget(
      _app(GjaCheckBox(text: 'Aceito os termos', onSelect: (_) {})),
    );
    final square = tester.getRect(_square());
    final text = tester.getRect(find.text('Aceito os termos'));
    expect(text.left - square.right, closeTo(_light.spacing.xs, 0.01));
    expect(find.byType(Icon), findsNothing);
    final whole = tester.getSize(find.byType(GjaInteractable));
    expect(whole.height, greaterThanOrEqualTo(_light.density.minTargetSize));
  });

  test('[API] Rótulo válido — Caixa sem rótulo', () {
    expect(() => GjaCheckBox(onSelect: (_) {}), throwsAssertionError);
    expect(
      () => GjaCheckBox(text: '', onSelect: (_) {}),
      throwsAssertionError,
    );
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Marcar a caixa', (
      tester,
    ) async {
      final log = <bool>[];
      await tester.pumpWidget(_app(_stateful(log)));
      await tester.tap(find.byType(GjaCheckBox));
      await tester.pump();
      expect(find.byType(Icon), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(log, [true, false]);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('[API] Callbacks e controlador — Caixa somente leitura', (
      tester,
    ) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _app(
          GjaCheckBox(
            text: 'Somente leitura',
            editable: false,
            onSelect: log.add,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<GjaCheckBox>();
      expect(focused, isNotNull);
      await tester.tap(find.byType(GjaCheckBox));
      await tester.pump();
      expect(log, isEmpty);
    });
  });

  testWidgets('[Comportamento] Estado parcial — Caixa parcial', (tester) async {
    final log = <bool>[];
    await tester.pumpWidget(
      _app(
        GjaCheckBox(
          text: 'Todos',
          partiallySelected: true,
          onSelect: log.add,
        ),
      ),
    );
    expect(find.byType(Icon), findsNothing);
    expect(
      find.descendant(
        of: find.byType(GjaCheckBox),
        matching: find.byType(ColoredBox),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(GjaCheckBox));
    expect(log, [true]);
  });

  testWidgets('[Comportamento] Texto — Toque no texto', (tester) async {
    final log = <bool>[];
    await tester.pumpWidget(
      _app(GjaCheckBox(text: 'Receber avisos', onSelect: log.add)),
    );
    await tester.tap(find.text('Receber avisos'));
    expect(log, [true]);
  });

  testWidgets('[Aparência] Tokens de componente — Caixa marcada', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(GjaCheckBox(text: 'Marcada', selected: true, onSelect: (_) {})),
    );
    expect(
      tester.getSize(_square()),
      Size.square(_light.icons.control + _light.spacing.xxs),
    );
    expect(_decoration(tester).color, _light.colors.base);
    expect(_border(tester), _light.colors.fieldBorder);
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, GjaIcons.accept);
    expect(icon.color, _light.colors.brand);
    expect(icon.size, _light.icons.control);
  });

  testWidgets(
    '[Aparência] Estado de valor e somente leitura — Caixa com erro',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GjaCheckBox(
                text: 'Erro',
                valueState: GjaValueState.error,
                onSelect: (_) {},
              ),
              const GjaCheckBox(
                text: 'Leitura',
                selected: true,
                editable: false,
              ),
            ],
          ),
        ),
      );
      final error = _light.colors.stateColors(GjaValueState.error);
      expect(_decoration(tester).color, error.background);
      expect(_border(tester), error.border);
      expect(_decoration(tester, 1).color, _light.colors.background);
      expect(_border(tester, 1), _light.colors.separator);
      expect(tester.widget<Icon>(find.byType(Icon)).color, _light.colors.label);
    },
  );

  group('[Estados] Interação', () {
    testWidgets('[Estados] Interação — Hover na caixa', (tester) async {
      await tester.pumpWidget(
        _app(GjaCheckBox(text: 'Hover', onSelect: (_) {})),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(_square()));
      await tester.pump();
      expect(_border(tester), _light.colors.brand);
    });

    testWidgets('[Estados] Interação — Caixa desabilitada', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _app(GjaCheckBox(text: 'Off', enabled: false, onSelect: log.add)),
      );
      await tester.tap(find.byType(GjaCheckBox), warnIfMissed: false);
      expect(log, isEmpty);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(GjaCheckBox),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        _light.interaction.disabledOpacity,
      );
    });
  });

  testWidgets('[Acessibilidade] Semântica — Semântica da caixa', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaCheckBox(text: 'Marcada', selected: true, onSelect: (_) {}),
            GjaCheckBox(
              text: 'Parcial',
              partiallySelected: true,
              onSelect: (_) {},
            ),
            const GjaCheckBox(text: 'Desabilitada', enabled: false),
            const GjaCheckBox(text: 'Leitura', editable: false),
          ],
        ),
      ),
    );
    SemanticsNode node(String label) =>
        tester.getSemantics(find.bySemanticsLabel(label));
    expect(
      node('Marcada'),
      containsSemantics(
        isButton: false,
        hasCheckedState: true,
        isChecked: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      node('Parcial'),
      containsSemantics(isButton: false, isCheckStateMixed: true),
    );
    expect(
      node('Desabilitada'),
      containsSemantics(
        isButton: false,
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    expect(
      node('Leitura'),
      containsSemantics(
        isButton: false,
        hasCheckedState: true,
        isReadOnly: true,
      ),
    );
    handle.dispose();
  });

  group('[Acessibilidade] Contraste, alvo e escala', () {
    testWidgets(
      '[Acessibilidade] Contraste, alvo e escala — Contraste e alvo da caixa',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final (_, theme) in goldenThemes) {
          await tester.pumpWidget(
            GjaTheme(
              key: ValueKey(theme),
              data: theme,
              duration: Duration.zero,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: GjaContainer(
                  surface: GjaSurface.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GjaCheckBox(text: 'Não', onSelect: (_) {}),
                        GjaCheckBox(
                          text: 'Sim',
                          selected: true,
                          onSelect: (_) {},
                        ),
                        for (final state in GjaValueState.values)
                          GjaCheckBox(
                            text: state.name,
                            valueState: state,
                            selected: true,
                            onSelect: (_) {},
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
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
          final c = theme.colors;
          for (final ground in [c.base, c.background]) {
            expect(
              gjaContrastRatioOver(c.fieldBorder, ground),
              greaterThanOrEqualTo(GjaAccessibility.minNonTextContrast),
            );
            expect(
              gjaContrastRatioOver(c.brand, ground),
              greaterThanOrEqualTo(GjaAccessibility.minNonTextContrast),
            );
          }
        }
        handle.dispose();
      },
    );

    testWidgets(
      '[Acessibilidade] Contraste, alvo e escala — Escala de texto da caixa',
      (tester) async {
        await tester.pumpWidget(
          _app(
            textScale: 2,
            SizedBox(
              width: 200,
              child: GjaCheckBox(
                text: 'Receber avisos por e-mail todos os dias',
                onSelect: (_) {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('[Responsividade] Direção e densidade — Caixa em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        direction: TextDirection.rtl,
        GjaCheckBox(text: 'Direita', onSelect: (_) {}),
      ),
    );
    expect(
      tester.getRect(_square()).left,
      greaterThan(tester.getRect(find.text('Direita')).right),
    );
  });

  testWidgets('[Integração] Dependências — Caixa sem Material', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaCheckBox(text: 'a', selected: true, onSelect: (_) {}),
            GjaCheckBox(text: 'b', partiallySelected: true, onSelect: (_) {}),
            const GjaCheckBox(text: 'c', editable: false),
            const GjaCheckBox(text: 'd', enabled: false),
          ],
        ),
      ),
    );
    for (final e in find.byType(GjaCheckBox).evaluate().toList()) {
      await tester.tap(find.byWidget(e.widget), warnIfMissed: false);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da caixa', () {
      final names = scenarioNames(
        'gja/widgets/gja-check-box',
        'add-gja-check-box',
      );
      expect(names, hasLength(19));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da caixa', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_check_box_$name',
          theme: theme,
          size: const Size(420, 460),
          child: GjaVBox(
            gap: GjaSpace.none,
            items: [
              GjaCheckBox(text: 'Desmarcada', onSelect: (_) {}),
              GjaCheckBox(text: 'Marcada', selected: true, onSelect: (_) {}),
              GjaCheckBox(
                text: 'Parcial',
                partiallySelected: true,
                onSelect: (_) {},
              ),
              for (final state in GjaValueState.values.skip(1))
                GjaCheckBox(
                  text: state.name,
                  valueState: state,
                  selected: true,
                  onSelect: (_) {},
                ),
              const GjaCheckBox(
                text: 'Somente leitura',
                selected: true,
                editable: false,
              ),
              const GjaCheckBox(text: 'Desabilitada', enabled: false),
            ],
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Caixa sem valor literal', () {
    final source = File(
      'lib/src/formularios/check_box/gja_check_box.dart',
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
