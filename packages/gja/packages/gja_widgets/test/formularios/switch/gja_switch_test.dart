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

Widget _app(Widget home, {TextDirection direction = TextDirection.ltr}) =>
    GjaApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Center(child: home),
    );

/// Trilho (o `AnimatedContainer`) da chave de [index].
Finder _track([int index = 0]) => find
    .descendant(
      of: find.byType(GjaSwitch).at(index),
      matching: find.byType(AnimatedContainer),
    )
    .first;

/// Alça (o círculo) da chave de [index].
Finder _handle([int index = 0]) => find
    .descendant(
      of: find.byType(GjaSwitch).at(index),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    )
    .first;

Color? _trackColor(WidgetTester tester, [int index = 0]) {
  final box = tester.widget<AnimatedContainer>(_track(index)).decoration;
  return (box! as BoxDecoration).color;
}

void main() {
  testWidgets('[API] Propriedades — Chave mínima', (tester) async {
    await tester.pumpWidget(
      _app(GjaSwitch(semanticLabel: 'Notificações', onChange: (_) {})),
    );
    final track = tester.getRect(_track());
    expect(tester.getCenter(_handle()).dx, lessThan(track.center.dx));
    expect(
      tester.getSize(find.byType(GjaInteractable)).height,
      greaterThanOrEqualTo(_light.density.minTargetSize),
    );
  });

  test('[API] Rótulo válido — Chave sem rótulo', () {
    expect(() => GjaSwitch(semanticLabel: ''), throwsAssertionError);
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Ligar a chave', (
      tester,
    ) async {
      final log = <bool>[];
      var state = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => GjaSwitch(
              semanticLabel: 'Avisos',
              state: state,
              onChange: (value) {
                log.add(value);
                setState(() => state = value);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GjaSwitch));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(log, [true, false]);
    });

    testWidgets('[API] Callbacks e controlador — Chave desabilitada', (
      tester,
    ) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _app(
          GjaSwitch(semanticLabel: 'Off', enabled: false, onChange: log.add),
        ),
      );
      await tester.tap(find.byType(GjaSwitch), warnIfMissed: false);
      expect(log, isEmpty);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(GjaSwitch),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        _light.interaction.disabledOpacity,
      );
    });
  });

  testWidgets('[Comportamento] Posição da alça — Alça ligada', (tester) async {
    await tester.pumpWidget(
      _app(GjaSwitch(semanticLabel: 'On', state: true, onChange: (_) {})),
    );
    await tester.pumpAndSettle();
    final track = tester.getRect(_track());
    final handle = tester.getRect(_handle());
    expect(handle.center.dx, greaterThan(track.center.dx));
    expect(
      track.right - handle.right,
      closeTo((_light.icons.medium - _light.icons.control) / 2, 0.01),
    );
  });

  testWidgets('[Aparência] Tokens de componente — Cores do trilho', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaSwitch(semanticLabel: 'a', onChange: (_) {}),
            GjaSwitch(semanticLabel: 'b', state: true, onChange: (_) {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_trackColor(tester), _light.colors.fieldBorder);
    expect(_trackColor(tester, 1), _light.colors.brand);
    expect(
      (tester.widget<DecoratedBox>(_handle()).decoration as BoxDecoration)
          .color,
      _light.colors.base,
    );
    expect(
      tester.getSize(_track()),
      Size(2 * _light.icons.medium, _light.icons.medium),
    );
  });

  testWidgets('[Estados] Interação — Hover na chave', (tester) async {
    await tester.pumpWidget(
      _app(GjaSwitch(semanticLabel: 'h', state: true, onChange: (_) {})),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(_track()));
    await tester.pumpAndSettle();
    expect(_trackColor(tester), _light.colors.brandHover);
  });

  testWidgets('[Acessibilidade] Semântica — Semântica da chave', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaSwitch(semanticLabel: 'Ligada', state: true, onChange: (_) {}),
            const GjaSwitch(semanticLabel: 'Desabilitada', enabled: false),
          ],
        ),
      ),
    );
    SemanticsNode node(String label) =>
        tester.getSemantics(find.bySemanticsLabel(label));
    expect(
      node('Ligada'),
      containsSemantics(
        isButton: false,
        hasToggledState: true,
        isToggled: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      node('Desabilitada'),
      containsSemantics(
        isButton: false,
        hasToggledState: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('[Acessibilidade] Contraste e alvo — Contraste e alvo da chave', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final (_, theme) in goldenThemes) {
      await tester.pumpWidget(
        GjaTheme(
          key: ValueKey(theme),
          data: theme,
          duration: Duration.zero,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GjaSwitch(semanticLabel: 'a', onChange: (_) {}),
                  GjaSwitch(
                    semanticLabel: 'b',
                    state: true,
                    onChange: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(
        tester,
        meetsGuideline(
          MinimumTapTargetGuideline(
            size: Size.square(GjaAccessibility.minTargetSize(theme.density)),
            link: GjaAccessibility.targetSizeLink,
          ),
        ),
      );
      final c = theme.colors;
      for (final track in [c.fieldBorder, c.brand]) {
        for (final ground in [c.base, c.background]) {
          expect(
            gjaContrastRatioOver(track, ground),
            greaterThanOrEqualTo(GjaAccessibility.minNonTextContrast),
          );
        }
      }
    }
    handle.dispose();
  });

  testWidgets('[Responsividade] Direção e densidade — Chave em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        direction: TextDirection.rtl,
        GjaSwitch(semanticLabel: 'rtl', state: true, onChange: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(_handle()).dx,
      lessThan(tester.getRect(_track()).center.dx),
    );
  });

  testWidgets('[Integração] Dependências — Chave sem Material', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaSwitch(semanticLabel: 'a', state: true, onChange: (_) {}),
            GjaSwitch(semanticLabel: 'b', onChange: (_) {}),
            const GjaSwitch(semanticLabel: 'c', enabled: false),
          ],
        ),
      ),
    );
    for (final e in find.byType(GjaSwitch).evaluate().toList()) {
      await tester.tap(find.byWidget(e.widget), warnIfMissed: false);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da chave', () {
      final names = scenarioNames(
        'gja/widgets/gja-switch',
        'add-gja-switch',
      );
      expect(names, hasLength(15));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da chave', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_switch_$name',
          theme: theme,
          size: const Size(320, 140),
          child: GjaHBox(
            items: [
              GjaSwitch(semanticLabel: 'Desligada', onChange: (_) {}),
              GjaSwitch(
                semanticLabel: 'Ligada',
                state: true,
                onChange: (_) {},
              ),
              const GjaSwitch(semanticLabel: 'Off', enabled: false),
              const GjaSwitch(
                semanticLabel: 'On',
                state: true,
                enabled: false,
              ),
            ],
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Chave sem valor literal', () {
    final source = File(
      'lib/src/formularios/switch/gja_switch.dart',
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
