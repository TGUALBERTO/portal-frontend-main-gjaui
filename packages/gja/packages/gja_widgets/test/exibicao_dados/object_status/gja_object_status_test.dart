import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

/// Monta [child] centralizado, sob [direction] e escala de texto, sem
/// `GjaApp`.
Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) => GjaTheme(
  data: GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Center(child: child),
      ),
    ),
  ),
);

/// Texto do valor (o último `Text` do status de [index]).
Text _value(WidgetTester tester, String text) => tester.widget<Text>(
  find.descendant(
    of: find.byType(GjaObjectStatus),
    matching: find.text(text),
  ),
);

const _long = 'Aguardando aprovação do gestor do centro de custo';

final _light = GjaThemeData.light();

void main() {
  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Status mínimo', (tester) async {
      await tester.pumpWidget(
        _host(
          const GjaObjectStatus(
            text: 'Aprovado',
            state: GjaValueState.success,
          ),
        ),
      );
      final style = _value(tester, 'Aprovado').style!;
      expect(
        style.color,
        _light.colors.stateColors(GjaValueState.success).foreground,
      );
      expect(style.fontSize, _light.typography.base.fontSize);
      expect(
        find.descendant(
          of: find.byType(GjaObjectStatus),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('[API] Propriedades — Status com título e ícone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const GjaObjectStatus(
            title: 'Situação',
            icon: GjaIcons.sysEnter2,
            text: 'Aprovado',
            state: GjaValueState.success,
          ),
        ),
      );
      final title = tester.getRect(find.text('Situação:'));
      final icon = tester.getRect(find.byType(GjaIcon));
      final text = tester.getRect(find.text('Aprovado'));
      expect(title.right, lessThanOrEqualTo(icon.left));
      expect(icon.right, lessThanOrEqualTo(text.left));
      final label = tester.widget<GjaLabel>(find.byType(GjaLabel));
      expect(label.text, 'Situação');
      expect(label.showColon, isTrue);
    });
  });

  test('[API] Conteúdo válido — Status vazio', () {
    for (final text in [null, '']) {
      expect(() => GjaObjectStatus(text: text), throwsAssertionError);
    }
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Status ativo', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        GjaApp(
          home: Center(
            child: GjaObjectStatus(
              text: '3 pendências',
              state: GjaValueState.warning,
              onPress: () => calls++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GjaObjectStatus));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('[API] Callbacks e controlador — Status inativo', (
      tester,
    ) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(() {
        first.dispose();
        second.dispose();
      });
      await tester.pumpWidget(
        GjaApp(
          home: Column(
            children: [
              Focus(focusNode: first, child: const SizedBox(height: 20)),
              const GjaObjectStatus(text: 'Aprovado'),
              Focus(focusNode: second, child: const SizedBox(height: 20)),
            ],
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.hasPrimaryFocus, isTrue);
      expect(
        find.descendant(
          of: find.byType(GjaObjectStatus),
          matching: find.byType(GjaInteractable),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('[Comportamento] Quebra do texto — Texto longo quebra', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 160,
          child: GjaObjectStatus(
            icon: GjaIcons.pending,
            text: _long,
            state: GjaValueState.information,
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(_long), matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(
      paragraph.size.height,
      greaterThan(paragraph.preferredLineHeight * 1.5),
    );
    final text = tester.getRect(find.text(_long));
    final icon = tester.getRect(find.byType(GjaIcon));
    // O ícone fica na faixa da primeira linha.
    expect(icon.top, greaterThanOrEqualTo(text.top));
    expect(
      icon.bottom,
      lessThanOrEqualTo(text.top + paragraph.preferredLineHeight + 0.5),
    );
  });

  testWidgets('[Aparência] Cores por estado — Cores do status por estado', (
    tester,
  ) async {
    for (final state in GjaValueState.values) {
      await tester.pumpWidget(
        _host(
          GjaObjectStatus(
            key: ValueKey(state),
            icon: GjaIcons.information,
            text: state.name,
            state: state,
          ),
        ),
      );
      final expected = state == GjaValueState.none
          ? _light.colors.text
          : _light.colors.stateColors(state).foreground;
      expect(_value(tester, state.name).style!.color, expected);
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(GjaIcon),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.color, expected, reason: state.name);
    }
  });

  testWidgets('[Aparência] Status invertido — Status invertido', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const GjaObjectStatus(
          text: 'Rejeitado',
          state: GjaValueState.error,
          inverted: true,
        ),
      ),
    );
    final error = _light.colors.stateColors(GjaValueState.error);
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(GjaObjectStatus),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, error.background);
    expect(decoration.border!.top.color, error.border);
    expect(decoration.borderRadius, BorderRadius.circular(_light.radius.s));
    expect(_value(tester, 'Rejeitado').style!.color, error.foreground);
  });

  testWidgets(
    '[Aparência] Tokens de componente — Ícone acompanha a escala de texto',
    (tester) async {
      await tester.pumpWidget(
        _host(
          textScale: 2,
          const GjaObjectStatus(
            icon: GjaIcons.information,
            text: 'Em análise',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(Icon)).width,
        greaterThan(_light.icons.inline),
      );
    },
  );

  testWidgets('[Estados] Interação do status ativo — Status ativo em hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(GjaObjectStatus(text: '3 pendências', onPress: () {})),
    );
    TextDecoration? decoration() =>
        _value(tester, '3 pendências').style!.decoration;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(GjaObjectStatus)));
    await tester.pump();
    expect(decoration(), TextDecoration.underline);
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(decoration(), TextDecoration.none);
  });

  testWidgets('[Acessibilidade] Semântica — Semântica do status', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GjaObjectStatus(
              title: 'Situação',
              icon: GjaIcons.sysEnter2,
              text: 'Aprovado',
            ),
            GjaObjectStatus(text: 'Atrasado', onPress: () {}),
          ],
        ),
      ),
    );
    final plain = tester.getSemantics(find.byType(GjaObjectStatus).at(0));
    expect(
      plain,
      containsSemantics(label: 'Situação: Aprovado', isButton: false),
    );
    expect(
      tester.getSemantics(find.byType(GjaObjectStatus).at(1)),
      containsSemantics(label: 'Atrasado', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('[Responsividade] Direção — Status em RTL', (tester) async {
    await tester.pumpWidget(
      _host(
        direction: TextDirection.rtl,
        const GjaObjectStatus(
          icon: GjaIcons.information,
          text: 'Em análise',
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(GjaIcon)).left,
      greaterThanOrEqualTo(tester.getRect(find.text('Em análise')).right),
    );
  });

  testWidgets('[Integração] Dependências — Status sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaApp(
        home: Column(
          children: [
            const GjaObjectStatus(text: 'Normal'),
            const GjaObjectStatus(
              text: 'Invertido',
              state: GjaValueState.error,
              inverted: true,
            ),
            GjaObjectStatus(text: 'Ativo', onPress: () {}),
          ],
        ),
      ),
    );
    for (final element in find.byType(GjaObjectStatus).evaluate().toList()) {
      await tester.tap(find.byWidget(element.widget), warnIfMissed: false);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do status', () {
      final names = scenarioNames(
        'gja/widgets/gja-object-status',
        'update-gja-status-indicator-fiori-object-status',
      );
      expect(names, hasLength(18));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do status', (
      tester,
    ) async {
      const icons = {
        GjaValueState.none: GjaIcons.information,
        GjaValueState.success: GjaIcons.sysEnter2,
        GjaValueState.warning: GjaIcons.warning,
        GjaValueState.error: GjaIcons.error,
        GjaValueState.information: GjaIcons.information,
      };
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_object_status_$name',
          theme: theme,
          size: const Size(480, 320),
          child: GjaVBox(
            items: [
              for (final state in GjaValueState.values)
                GjaHBox(
                  gap: GjaSpace.l,
                  items: [
                    GjaObjectStatus(
                      icon: icons[state],
                      text: state.name,
                      state: state,
                    ),
                    GjaObjectStatus(
                      text: state.name,
                      state: state,
                      inverted: true,
                    ),
                  ],
                ),
              const GjaObjectStatus(
                title: 'Situação',
                icon: GjaIcons.sysEnter2,
                text: 'Aprovado',
                state: GjaValueState.success,
              ),
              GjaObjectStatus(
                icon: GjaIcons.warning,
                text: '3 pendências',
                state: GjaValueState.warning,
                onPress: () {},
              ),
            ],
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Status sem valor literal', () {
    final source = File(
      'lib/src/exibicao_dados/object_status/gja_object_status.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expect(fields, isNotEmpty);
    for (final type in fields) {
      expect(
        type.replaceAll('?', ''),
        isNot(isIn(['double', 'Color', 'TextStyle'])),
      );
    }
  });
}
