import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';
import 'package:gja_widgets/src/exibicao_dados/progress_indicator/gja_progress_view.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

/// Monta [child] centralizado, sob [theme] e [direction], sem `GjaApp`.
Widget _host(
  Widget child, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Center(child: child),
  ),
);

/// Fundo pintado do botão (de [index], quando há vários).
Finder _box([int index = 0]) => find
    .descendant(
      of: find.byType(GjaButton).at(index),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(_box(index)).decoration as BoxDecoration;

Text _label(WidgetTester tester) => tester.widget<Text>(
  find.descendant(of: find.byType(GjaButton), matching: find.byType(Text)),
);

final _light = GjaThemeData.light();

GjaControlColors _family(GjaControlFamily family) =>
    GjaControlColors.of(family, _light.colors);

void main() {
  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Botão mínimo', (tester) async {
      await tester.pumpWidget(
        _host(GjaButton(text: 'Salvar', onPress: () {})),
      );
      final box = tester.getRect(_box());
      expect(box.height, _light.density.controlHeight);
      final normal = _family(GjaControlFamily.standard).normal;
      expect(_decoration(tester).color, normal.background);
      expect(
        tester.getCenter(find.text('Salvar')).dx,
        closeTo(box.center.dx, 0.5),
      );
    });

    testWidgets('[API] Propriedades — Botão com ícone', (tester) async {
      await tester.pumpWidget(
        _host(
          GjaButton(text: 'Salvar', icon: GjaIcons.accept, onPress: () {}),
        ),
      );
      final icon = tester.getRect(find.byType(Icon));
      final text = tester.getRect(find.text('Salvar'));
      expect(text.left - icon.right, closeTo(_light.spacing.xs, 0.01));
    });
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Pressionar', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(GjaButton(text: 'Salvar', onPress: () => calls++)),
      );
      await tester.tap(find.byType(GjaButton));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('[API] Callbacks e controlador — Botão desabilitado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const GjaButton(text: 'Salvar', enabled: false)),
      );
      await tester.tap(find.byType(GjaButton), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(GjaButton),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        _light.interaction.disabledOpacity,
      );
    });

    testWidgets('[API] Callbacks e controlador — Botão sem ação', (
      tester,
    ) async {
      final first = FocusNode();
      addTearDown(first.dispose);
      await tester.pumpWidget(
        GjaApp(
          home: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: first,
                child: const SizedBox.square(dimension: 8),
              ),
              const GjaButton(text: 'Salvar'),
              Focus(child: const SizedBox.square(dimension: 8)),
            ],
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<GjaFocusRing>(
              find.descendant(
                of: find.byType(GjaButton),
                matching: find.byType(GjaFocusRing),
              ),
            )
            .visible,
        isTrue,
      );
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(GjaButton),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        1,
      );
      await tester.tap(find.byType(GjaButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('[Comportamento] Estado ocupado — Botão ocupado', (tester) async {
    var calls = 0;
    Widget button(bool busy) => _host(
      GjaButton(
        text: 'Enviar',
        icon: GjaIcons.upload,
        busy: busy,
        onPress: () => calls++,
      ),
    );
    await tester.pumpWidget(button(false));
    final width = tester.getSize(_box()).width;
    await tester.pumpWidget(button(true));
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(GjaProgressView), findsOneWidget);
    expect(tester.getSize(_box()).width, width);
    await tester.tap(find.byType(GjaButton));
    await tester.pump();
    expect(calls, 0);
    // Para a animação do indicador antes de encerrar.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('[Comportamento] Estado ocupado — Botão só com ícone ocupado', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaApp(
        home: Center(
          child: GjaButton(
            icon: GjaIcons.edit,
            tooltip: 'Editar',
            busy: true,
            onPress: () {},
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(GjaButton),
        matching: find.byType(GjaProgressView),
      ),
      findsOneWidget,
    );
    expect(find.byType(Icon), findsNothing);
    expect(tester.getSize(_box()), Size.square(_light.density.controlHeight));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('[Comportamento] Ativação pelo teclado — Enter e Espaço', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      GjaApp(
        home: Center(
          child: GjaButton(text: 'Salvar', onPress: () => calls++),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('[Aparência] Cores por tipo — Cores por tipo', (tester) async {
    for (final (type, family) in [
      (GjaButtonType.standard, GjaControlFamily.standard),
      (GjaButtonType.emphasized, GjaControlFamily.emphasized),
      (GjaButtonType.transparent, GjaControlFamily.transparent),
      (GjaButtonType.accept, GjaControlFamily.accept),
      (GjaButtonType.reject, GjaControlFamily.reject),
      (GjaButtonType.attention, GjaControlFamily.attention),
    ]) {
      await tester.pumpWidget(
        _host(GjaButton(text: type.name, type: type, onPress: () {})),
      );
      final normal = _family(family).normal;
      final decoration = _decoration(tester);
      expect(decoration.color, normal.background, reason: type.name);
      expect(decoration.border!.top.color, normal.border, reason: type.name);
      expect(_label(tester).style!.color, normal.text, reason: type.name);
    }
  });

  testWidgets(
    '[Aparência] Tokens de componente — Medidas da densidade compacta',
    (tester) async {
      final compact = GjaThemeData.light(density: GjaDensity.compact);
      await tester.pumpWidget(
        _host(
          theme: compact,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GjaButton(text: 'Salvar', onPress: () {}),
              GjaButton(
                icon: GjaIcons.edit,
                tooltip: 'Editar',
                onPress: () {},
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(_box(1)),
        Size.square(compact.density.controlHeight),
      );
      final box = tester.getRect(_box());
      expect(box.height, compact.density.controlHeight);
      expect(
        tester.getRect(find.text('Salvar')).left - box.left,
        closeTo(compact.spacing.m, 0.5),
      );
    },
  );

  group('[Estados] Interação', () {
    testWidgets('[Estados] Interação — Hover e pressionado', (tester) async {
      await tester.pumpWidget(
        _host(GjaButton(text: 'Salvar', onPress: () {})),
      );
      final standard = _family(GjaControlFamily.standard);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(GjaButton)));
      await tester.pump();
      expect(_decoration(tester).color, standard.hover.background);
      await mouse.down(tester.getCenter(find.byType(GjaButton)));
      await tester.pump();
      expect(_decoration(tester).color, standard.active.background);
      await mouse.up();
      await tester.pump();
    });

    testWidgets('[Estados] Interação — Foco pelo teclado', (tester) async {
      bool ringVisible() => tester
          .widget<GjaFocusRing>(
            find.descendant(
              of: find.byType(GjaButton),
              matching: find.byType(GjaFocusRing),
            ),
          )
          .visible;
      await tester.pumpWidget(
        GjaApp(
          home: Center(
            child: GjaButton(text: 'Salvar', onPress: () {}),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringVisible(), isTrue);

      await tester.pumpWidget(
        GjaApp(
          key: const Key('touch'),
          home: Center(
            child: GjaButton(text: 'Salvar', onPress: () {}),
          ),
        ),
      );
      await tester.tap(find.byType(GjaButton));
      await tester.pump();
      expect(ringVisible(), isFalse);
    });
  });

  group('[Acessibilidade] Semântica', () {
    testWidgets('[Acessibilidade] Semântica — Semântica do botão', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GjaButton(text: 'Salvar', onPress: () {}),
              const GjaButton(text: 'Excluir', enabled: false),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(GjaButton).at(0)),
        containsSemantics(
          isButton: true,
          label: 'Salvar',
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byType(GjaButton).at(1)),
        containsSemantics(
          isButton: true,
          label: 'Excluir',
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('[Acessibilidade] Semântica — Semântica do ocupado', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(GjaButton(text: 'Enviar', busy: true, onPress: () {})),
      );
      expect(
        tester.getSemantics(find.byType(GjaButton)),
        containsSemantics(label: 'Enviar', value: 'Carregando'),
      );
      handle.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('[Responsividade] Largura e direção', () {
    testWidgets('[Responsividade] Largura e direção — Botão em RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          direction: TextDirection.rtl,
          GjaButton(text: 'Salvar', icon: GjaIcons.accept, onPress: () {}),
        ),
      );
      expect(
        tester.getRect(find.byType(Icon)).left,
        greaterThanOrEqualTo(tester.getRect(find.text('Salvar')).right),
      );
    });

    testWidgets('[Responsividade] Largura e direção — Rótulo longo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: GjaButton(
              text: 'Encaminhar para aprovação do gestor',
              onPress: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(GjaButton)).width,
        lessThanOrEqualTo(120),
      );
      final label = _label(tester);
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(GjaButton),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
    });
  });

  testWidgets(
    '[Integração] Dependências do núcleo e de widgets — Botão sem Material',
    (tester) async {
      await tester.pumpWidget(
        GjaApp(
          home: Column(
            children: [
              for (final type in GjaButtonType.values)
                GjaButton(text: type.name, type: type, onPress: () {}),
              const GjaButton(text: 'Desabilitado', enabled: false),
              GjaButton(text: 'Ocupado', busy: true, onPress: () {}),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final type in GjaButtonType.values)
                    GjaButton(
                      icon: GjaIcons.edit,
                      tooltip: type.name,
                      type: type,
                      onPress: () {},
                    ),
                ],
              ),
            ],
          ),
        ),
      );
      for (final finder in find.byType(GjaButton).evaluate().toList()) {
        await tester.tap(find.byWidget(finder.widget), warnIfMissed: false);
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    '[Integração] Dependências de fundamentos — Botão pelo tema da subárvore',
    (tester) async {
      final dark = GjaThemeData.dark();
      await tester.pumpWidget(
        GjaApp(
          home: GjaTheme(
            data: dark,
            child: Center(
              child: GjaButton(
                text: 'Salvar',
                type: GjaButtonType.emphasized,
                onPress: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, dark.colors.brand);
    },
  );

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do botão', () {
      final names = scenarioNames(
        'gja/widgets/gja-button',
        'add-gja-button',
      );
      expect(names, hasLength(31));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do botão', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_button_$name',
          theme: theme,
          size: const Size(480, 460),
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: GjaVBox(
              gap: GjaSpace.s,
              items: [
                for (final type in GjaButtonType.values)
                  GjaHBox(
                    items: [
                      GjaButton(text: type.name, type: type, onPress: () {}),
                      GjaButton(
                        text: type.name,
                        type: type,
                        icon: GjaIcons.accept,
                        onPress: () {},
                      ),
                    ],
                  ),
                GjaHBox(
                  gap: GjaSpace.xs,
                  items: [
                    for (final type in GjaButtonType.values)
                      GjaButton(
                        icon: GjaIcons.edit,
                        tooltip: type.name,
                        type: type,
                        onPress: () {},
                      ),
                  ],
                ),
                GjaHBox(
                  items: [
                    const GjaButton(text: 'Desabilitado', enabled: false),
                    GjaButton(
                      text: 'Enviando',
                      type: GjaButtonType.emphasized,
                      icon: GjaIcons.upload,
                      busy: true,
                      onPress: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Botão sem valor literal', () {
    final source = File(
      'lib/src/acoes_navegacao/button/gja_button.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expect(fields, isNotEmpty);
    for (final type in fields) {
      expect(
        type,
        isNot(
          anyOf(
            'double',
            'double?',
            'Color',
            'Color?',
            'Duration',
            'Duration?',
          ),
        ),
      );
    }
  });
}
