import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

/// Aplicação de teste com [home] centralizado (a dica precisa do `Overlay`).
Widget _app(
  Widget home, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) => GjaApp(
  theme: theme,
  darkTheme: theme,
  density: theme?.density.density,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(textDirection: direction, child: child!),
  ),
  home: Center(child: home),
);

Finder _box([int index = 0]) => find
    .descendant(
      of: find.byType(GjaButton).at(index),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(_box(index)).decoration as BoxDecoration;

/// Nó interativo do botão de [index], que tem a semântica.
Finder _interactable(int index) => find.descendant(
  of: find.byType(GjaButton).at(index),
  matching: find.byType(GjaInteractable),
);

Icon _icon(WidgetTester tester) => tester.widget<Icon>(
  find.descendant(of: find.byType(GjaButton), matching: find.byType(Icon)),
);

final _light = GjaThemeData.light();

GjaControlColors _family(GjaControlFamily family) =>
    GjaControlColors.of(family, _light.colors);

void main() {
  testWidgets('[API] Propriedades — Botão só com ícone', (tester) async {
    await tester.pumpWidget(
      _app(
        GjaButton(icon: GjaIcons.edit, tooltip: 'Editar', onPress: () {}),
      ),
    );
    final box = tester.getRect(_box());
    expect(box.size, Size.square(_light.density.controlHeight));
    final normal = _family(GjaControlFamily.standard).normal;
    expect(_decoration(tester).color, normal.background);
    expect(_icon(tester).size, _light.icons.control);
    expect(tester.getCenter(find.byType(Icon)), box.center);
  });

  test('[API] Conteúdo válido — Botão sem conteúdo', () {
    expect(() => GjaButton(onPress: () {}), throwsAssertionError);
    expect(() => GjaButton(text: '', onPress: () {}), throwsAssertionError);
    for (final tooltip in [null, '']) {
      expect(
        () => GjaButton(
          icon: GjaIcons.edit,
          tooltip: tooltip,
          onPress: () {},
        ),
        throwsAssertionError,
      );
    }
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Pressionar (só com ícone)', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _app(
          GjaButton(
            icon: GjaIcons.edit,
            tooltip: 'Editar',
            onPress: () => calls++,
            type: GjaButtonType.transparent,
          ),
        ),
      );
      await tester.tap(find.byType(GjaButton));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets(
      '[API] Callbacks e controlador — Botão desabilitado (só com ícone)',
      (tester) async {
        await tester.pumpWidget(
          _app(
            const GjaButton(
              icon: GjaIcons.delete,
              tooltip: 'Excluir',
              enabled: false,
              type: GjaButtonType.transparent,
            ),
          ),
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
      },
    );
  });

  testWidgets('[Comportamento] Dica — Dica no hover', (tester) async {
    await tester.pumpWidget(
      _app(
        GjaButton(
          icon: GjaIcons.edit,
          tooltip: 'Editar pedido',
          onPress: () {},
          type: GjaButtonType.transparent,
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(GjaButton)));
    await tester.pump(_light.motion.long);
    await tester.pump();
    expect(find.text('Editar pedido'), findsOneWidget);
  });

  testWidgets(
    '[Comportamento] Ativação pelo teclado — Enter e Espaço (só com ícone)',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _app(
          GjaButton(
            icon: GjaIcons.edit,
            tooltip: 'Editar',
            onPress: () => calls++,
            type: GjaButtonType.transparent,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, 2);
    },
  );

  testWidgets('[Aparência] Cores por tipo — Cores por tipo (só com ícone)', (
    tester,
  ) async {
    for (final (type, family) in [
      (GjaButtonType.standard, GjaControlFamily.standard),
      (GjaButtonType.emphasized, GjaControlFamily.emphasized),
      (GjaButtonType.transparent, GjaControlFamily.transparent),
      (GjaButtonType.accept, GjaControlFamily.accept),
      (GjaButtonType.reject, GjaControlFamily.reject),
      (GjaButtonType.attention, GjaControlFamily.attention),
    ]) {
      await tester.pumpWidget(
        _app(
          GjaButton(
            key: ValueKey(type),
            icon: GjaIcons.edit,
            tooltip: type.name,
            type: type,
            onPress: () {},
          ),
        ),
      );
      final normal = _family(family).normal;
      final decoration = _decoration(tester);
      expect(decoration.color, normal.background, reason: type.name);
      expect(decoration.border!.top.color, normal.border, reason: type.name);
      expect(_icon(tester).color, normal.text, reason: type.name);
    }
  });

  testWidgets(
    '[Aparência] Tokens de componente — Medidas da densidade compacta (só com ícone)',
    (tester) async {
      final compact = GjaThemeData.light(density: GjaDensity.compact);
      await tester.pumpWidget(
        _app(
          theme: compact,
          textScale: 2,
          GjaButton(
            icon: GjaIcons.edit,
            tooltip: 'Editar',
            onPress: () {},
            type: GjaButtonType.transparent,
          ),
        ),
      );
      expect(
        tester.getSize(_box()),
        Size.square(compact.density.controlHeight),
      );
      expect(
        tester.getSize(find.byType(Icon)),
        Size.square(compact.icons.control),
      );
    },
  );

  group('[Estados] Interação', () {
    testWidgets('[Estados] Interação — Hover e pressionado (só com ícone)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          GjaButton(
            icon: GjaIcons.edit,
            tooltip: 'Editar',
            onPress: () {},
            type: GjaButtonType.transparent,
          ),
        ),
      );
      final transparent = _family(GjaControlFamily.transparent);
      final center = tester.getCenter(find.byType(GjaButton));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(center);
      await tester.pump();
      expect(_decoration(tester).color, transparent.hover.background);
      await mouse.down(center);
      // O toque longo da dica compete com o toque: o pressionado vem após
      // kPressTimeout.
      await tester.pump(kPressTimeout);
      expect(_decoration(tester).color, transparent.active.background);
      await mouse.up();
      // A dica do hover abre e fecha com os atrasos.
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
    });

    testWidgets('[Comportamento] Dica — Dica no foco do teclado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          GjaButton(
            icon: GjaIcons.edit,
            tooltip: 'Editar pedido',
            onPress: () {},
            type: GjaButtonType.transparent,
          ),
        ),
      );
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
      expect(find.text('Editar pedido'), findsOneWidget);
    });
  });

  testWidgets('[Acessibilidade] Semântica — Semântica do botão só com ícone', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaButton(
              icon: GjaIcons.edit,
              tooltip: 'Editar',
              onPress: () {},
              type: GjaButtonType.transparent,
            ),
            const GjaButton(
              icon: GjaIcons.delete,
              tooltip: 'Excluir',
              enabled: false,
              type: GjaButtonType.transparent,
            ),
          ],
        ),
      ),
    );
    final edit = tester.getSemantics(_interactable(0));
    expect(
      edit,
      containsSemantics(
        isButton: true,
        label: 'Editar',
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(edit.tooltip, isEmpty);
    final delete = tester.getSemantics(_interactable(1));
    expect(
      delete,
      containsSemantics(
        isButton: true,
        label: 'Excluir',
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    expect(delete.tooltip, isEmpty);
    expect(find.bySemanticsLabel('Editar'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        GjaButton(text: 'Salvar', tooltip: 'Salvar o pedido', onPress: () {}),
      ),
    );
    final save = tester.getSemantics(_interactable(0));
    expect(save, containsSemantics(isButton: true, label: 'Salvar'));
    expect(save.tooltip, 'Salvar o pedido');
    handle.dispose();
  });

  testWidgets('[Responsividade] Largura e direção — Ícone direcional em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        direction: TextDirection.rtl,
        GjaButton(
          icon: GjaIcons.navBack,
          tooltip: 'Voltar',
          onPress: () {},
          type: GjaButtonType.transparent,
        ),
      ),
    );
    final icon = _icon(tester);
    expect(icon.icon!.matchTextDirection, isTrue);
    expect(
      Directionality.of(tester.element(find.byType(Icon))),
      TextDirection.rtl,
    );
  });

  group('[Integração] Dependências', () {
    testWidgets(
      '[Integração] Dependências do núcleo e de widgets — Botão sem Material (só com ícone)',
      (tester) async {
        await tester.pumpWidget(
          _app(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final type in GjaButtonType.values)
                  GjaButton(
                    icon: GjaIcons.edit,
                    tooltip: type.name,
                    type: type,
                    onPress: () {},
                  ),
                const GjaButton(
                  icon: GjaIcons.edit,
                  tooltip: 'Desabilitado',
                  enabled: false,
                  type: GjaButtonType.transparent,
                ),
              ],
            ),
          ),
        );
        for (final element in find.byType(GjaButton).evaluate().toList()) {
          await tester.tap(find.byWidget(element.widget), warnIfMissed: false);
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '[Integração] Dependências do núcleo e de widgets — Barra e página usam o botão',
      (tester) async {
        await tester.pumpWidget(
          GjaApp(
            locale: const Locale('pt', 'BR'),
            home: GjaToolPage(
              header: GjaShellBar(
                showMenuButton: true,
                onMenuButtonPressed: () {},
              ),
              mainContents: [
                GjaPage(
                  title: 'Pedidos',
                  showNavButton: true,
                  onNavButtonPress: () {},
                ),
              ],
            ),
          ),
        );
        final buttons = tester
            .widgetList<GjaButton>(find.byType(GjaButton))
            .toList();
        expect(buttons.map((b) => b.tooltip).toSet(), {'Menu', 'Voltar'});
        for (final button in buttons) {
          expect(button.text, isNull);
          expect(button.type, GjaButtonType.transparent);
        }
      },
    );
  });
}
