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

/// Círculo externo da opção de [index].
Finder _circle([int index = 0]) => find
    .descendant(
      of: find.byType(GjaRadioButton).at(index),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(_circle(index)).decoration as BoxDecoration;

Color _border(WidgetTester tester, [int index = 0]) =>
    (_decoration(tester, index).border! as Border).top.color;

/// Ponto interno da opção de [index] (o segundo `DecoratedBox`).
Finder _dot([int index = 0]) => find
    .descendant(
      of: find.byType(GjaRadioButton).at(index),
      matching: find.byType(DecoratedBox),
    )
    .at(1);

void main() {
  testWidgets('[API] Propriedades — Opção mínima', (tester) async {
    await tester.pumpWidget(
      _app(GjaRadioButton(text: 'Boleto', onSelect: (_) {})),
    );
    final circle = tester.getRect(_circle());
    expect(
      tester.getRect(find.text('Boleto')).left - circle.right,
      closeTo(_light.spacing.xs, 0.01),
    );
    expect(
      find.descendant(
        of: find.byType(GjaRadioButton),
        matching: find.byType(DecoratedBox),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(GjaInteractable)).height,
      greaterThanOrEqualTo(_light.density.minTargetSize),
    );
  });

  test('[API] Rótulo válido — Opção sem rótulo', () {
    expect(() => GjaRadioButton(onSelect: (_) {}), throwsAssertionError);
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Escolher a opção', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GjaRadioButton(text: 'a', onSelect: (_) => log.add('a')),
              GjaRadioButton(
                text: 'b',
                selected: true,
                onSelect: (_) => log.add('b'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('a'));
      await tester.tap(find.text('b'));
      expect(log, ['a']);
    });

    testWidgets('[API] Callbacks e controlador — Opção somente leitura', (
      tester,
    ) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _app(
          GjaRadioButton(text: 'leitura', editable: false, onSelect: log.add),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<GjaRadioButton>(),
        isNotNull,
      );
      await tester.tap(find.byType(GjaRadioButton));
      expect(log, isEmpty);
    });
  });

  testWidgets('[Comportamento] Texto — Toque no texto da opção', (
    tester,
  ) async {
    final log = <bool>[];
    await tester.pumpWidget(
      _app(GjaRadioButton(text: 'Pix', onSelect: log.add)),
    );
    await tester.tap(find.text('Pix'));
    expect(log, [true]);
  });

  testWidgets('[Aparência] Tokens de componente — Opção marcada', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaRadioButton(text: 'a', selected: true, onSelect: (_) {}),
            GjaRadioButton(
              text: 'b',
              valueState: GjaValueState.error,
              onSelect: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(_circle()),
      Size.square(_light.icons.control + _light.spacing.xxs),
    );
    expect(_border(tester), _light.colors.fieldBorder);
    expect(tester.getSize(_dot()), Size.square(_light.spacing.s));
    expect(
      (tester.widget<DecoratedBox>(_dot()).decoration as BoxDecoration).color,
      _light.colors.brand,
    );
    final error = _light.colors.stateColors(GjaValueState.error);
    expect(_border(tester, 1), error.border);
    expect(_decoration(tester, 1).color, error.background);
  });

  group('[Estados] Interação', () {
    testWidgets('[Estados] Interação — Hover na opção', (tester) async {
      await tester.pumpWidget(
        _app(GjaRadioButton(text: 'h', onSelect: (_) {})),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(_circle()));
      await tester.pump();
      expect(_border(tester), _light.colors.brand);
    });

    testWidgets('[Estados] Interação — Opção desabilitada', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _app(GjaRadioButton(text: 'off', enabled: false, onSelect: log.add)),
      );
      await tester.tap(find.byType(GjaRadioButton), warnIfMissed: false);
      expect(log, isEmpty);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(GjaRadioButton),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        _light.interaction.disabledOpacity,
      );
    });
  });

  testWidgets('[Acessibilidade] Semântica — Semântica da opção', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaRadioButton(text: 'Marcada', selected: true, onSelect: (_) {}),
            const GjaRadioButton(text: 'Desabilitada', enabled: false),
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
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        isEnabled: true,
      ),
    );
    expect(
      node('Desabilitada'),
      containsSemantics(
        isButton: false,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets(
    '[Acessibilidade] Contraste, alvo e escala — Contraste e alvo da opção',
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
                      GjaRadioButton(text: 'Não', onSelect: (_) {}),
                      GjaRadioButton(
                        text: 'Sim',
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
      }
      await tester.pumpWidget(
        _app(
          textScale: 2,
          SizedBox(
            width: 200,
            child: GjaRadioButton(
              text: 'Receber por e-mail todos os dias',
              onSelect: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets('[Responsividade] Direção — Opção em RTL', (tester) async {
    await tester.pumpWidget(
      _app(
        direction: TextDirection.rtl,
        GjaRadioButton(text: 'Direita', onSelect: (_) {}),
      ),
    );
    expect(
      tester.getRect(_circle()).left,
      greaterThan(tester.getRect(find.text('Direita')).right),
    );
  });

  testWidgets('[Integração] Dependências — Opção sem Material', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaRadioButton(text: 'a', selected: true, onSelect: (_) {}),
            GjaRadioButton(text: 'b', onSelect: (_) {}),
            const GjaRadioButton(text: 'c', editable: false),
            const GjaRadioButton(text: 'd', enabled: false),
          ],
        ),
      ),
    );
    for (final e in find.byType(GjaRadioButton).evaluate().toList()) {
      await tester.tap(find.byWidget(e.widget), warnIfMissed: false);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da opção', () {
      final names = scenarioNames(
        'gja/widgets/gja-radio-button',
        'add-gja-radio-button',
      );
      expect(names, hasLength(16));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da opção', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_radio_button_$name',
          theme: theme,
          size: const Size(420, 420),
          child: GjaVBox(
            gap: GjaSpace.none,
            items: [
              GjaRadioButton(text: 'Desmarcada', onSelect: (_) {}),
              GjaRadioButton(
                text: 'Marcada',
                selected: true,
                onSelect: (_) {},
              ),
              for (final state in GjaValueState.values.skip(1))
                GjaRadioButton(
                  text: state.name,
                  valueState: state,
                  selected: true,
                  onSelect: (_) {},
                ),
              const GjaRadioButton(
                text: 'Somente leitura',
                selected: true,
                editable: false,
              ),
              const GjaRadioButton(text: 'Desabilitada', enabled: false),
            ],
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Opção sem valor literal', () {
    final source = File(
      'lib/src/formularios/radio_button/gja_radio_button.dart',
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
