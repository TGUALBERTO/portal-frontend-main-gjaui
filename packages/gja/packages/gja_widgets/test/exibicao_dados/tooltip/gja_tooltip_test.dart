import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';
import '../../support/traceability.dart';

const _message = 'Editar pedido';
const _long =
    'Abre o pedido em modo de edição para alterar itens, quantidades, '
    'condições de pagamento e o endereço de entrega.';

/// Aplicação de teste com [home], sob [theme], opcionalmente com movimento
/// reduzido.
Widget _app(Widget home, {GjaThemeData? theme, bool reduceMotion = false}) =>
    GjaApp(
      theme: theme,
      darkTheme: theme,
      density: theme?.density.density,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: RepaintBoundary(key: const Key('golden'), child: child!),
      ),
      home: home,
    );

Widget _icon([String key = 'icon']) =>
    SizedBox(key: Key(key), width: 24, height: 24);

/// Bolha da dica: o contêiner em volta da mensagem.
Finder _bubble(String message) => find.ancestor(
  of: find.text(message),
  matching: find.byType(GjaContainer),
);

Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(target));
  return mouse;
}

final _light = GjaThemeData.light();

void main() {
  testWidgets('[API] Propriedades — Tooltip mínimo', (tester) async {
    await tester.pumpWidget(
      _app(
        const Center(
          child: GjaTooltip(
            message: _message,
            child: SizedBox(key: Key('icon'), width: 24, height: 24),
          ),
        ),
      ),
    );
    await _hover(tester, find.byKey(const Key('icon')));
    await tester.pump(_light.motion.long);
    await tester.pump();
    final icon = tester.getRect(find.byKey(const Key('icon')));
    final bubble = tester.getRect(_bubble(_message).first);
    expect(bubble.top, closeTo(icon.bottom + _light.spacing.xs, 0.01));
    expect(bubble.center.dx, closeTo(icon.center.dx, 0.01));
  });

  test('[API] Mensagem válida — Mensagem vazia', () {
    for (final message in ['']) {
      expect(
        () => GjaTooltip(message: message, child: const SizedBox()),
        throwsAssertionError,
      );
    }
  });

  testWidgets('[API] Callbacks e controlador — Toque no filho preservado', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        Center(
          child: GjaTooltip(
            message: _message,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: _icon(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('icon')));
    await tester.pump();
    expect(taps, 1);
  });

  group('[Comportamento] Abertura e fechamento pelo ponteiro', () {
    testWidgets(
      '[Comportamento] Abertura e fechamento pelo ponteiro — Hover com atraso',
      (tester) async {
        await tester.pumpWidget(
          _app(
            Center(
              child: GjaTooltip(message: _message, child: _icon()),
            ),
          ),
        );
        await _hover(tester, find.byKey(const Key('icon')));
        final half = _light.motion.long ~/ 2;
        await tester.pump(half);
        expect(find.text(_message), findsNothing);
        await tester.pump(_light.motion.long - half);
        await tester.pump();
        expect(find.text(_message), findsOneWidget);
      },
    );

    testWidgets(
      '[Comportamento] Abertura e fechamento pelo ponteiro — Saída do ponteiro',
      (tester) async {
        await tester.pumpWidget(
          _app(
            Center(
              child: GjaTooltip(message: _message, child: _icon()),
            ),
          ),
        );
        final mouse = await _hover(tester, find.byKey(const Key('icon')));
        await tester.pump(_light.motion.long);
        await tester.pump();
        expect(find.text(_message), findsOneWidget);
        await mouse.moveTo(const Offset(5, 5));
        await tester.pump(_light.motion.short);
        await tester.pump();
        expect(find.text(_message), findsNothing);
      },
    );
  });

  testWidgets(
    '[Comportamento] Permanência sobre a dica — Ponteiro sobre a dica',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: GjaTooltip(message: _message, child: _icon()),
          ),
        ),
      );
      final mouse = await _hover(tester, find.byKey(const Key('icon')));
      await tester.pump(_light.motion.long);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(_bubble(_message).first));
      await tester.pump(_light.motion.long);
      await tester.pump();
      expect(find.text(_message), findsOneWidget);
    },
  );

  group('[Comportamento] Abertura por foco e por toque', () {
    testWidgets(
      '[Comportamento] Abertura por foco e por toque — Foco pelo teclado',
      (tester) async {
        final first = FocusNode();
        final second = FocusNode();
        addTearDown(() {
          first.dispose();
          second.dispose();
        });
        await tester.pumpWidget(
          _app(
            Column(
              children: [
                GjaTooltip(
                  message: _message,
                  child: Focus(focusNode: first, child: _icon()),
                ),
                Focus(focusNode: second, child: _icon('other')),
              ],
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(first.hasPrimaryFocus, isTrue);
        expect(find.text(_message), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(second.hasPrimaryFocus, isTrue);
        expect(find.text(_message), findsNothing);
      },
    );

    testWidgets('[Comportamento] Abertura por foco e por toque — Toque longo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: GjaTooltip(message: _message, child: _icon()),
          ),
        ),
      );
      await tester.longPress(find.byKey(const Key('icon')));
      await tester.pump();
      expect(find.text(_message), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.text(_message), findsNothing);
    });
  });

  testWidgets(
    '[Comportamento] Uma dica por vez — Segunda dica fecha a primeira',
    (tester) async {
      final first = FocusNode();
      addTearDown(first.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GjaTooltip(
                message: 'Primeira',
                child: Focus(focusNode: first, child: _icon('a')),
              ),
              const SizedBox(height: 100),
              GjaTooltip(message: 'Segunda', child: _icon('b')),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.text('Primeira'), findsOneWidget);
      await tester.longPress(find.byKey(const Key('b')));
      await tester.pump();
      expect(find.text('Primeira'), findsNothing);
      expect(find.text('Segunda'), findsOneWidget);
    },
  );

  testWidgets('[Aparência] Tokens de componente — Aparência da dica', (
    tester,
  ) async {
    for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
      await tester.pumpWidget(
        _app(
          theme: theme,
          Center(
            key: ValueKey(theme.brightness),
            child: GjaTooltip(message: _message, child: _icon()),
          ),
        ),
      );
      await tester.longPress(find.byKey(const Key('icon')));
      await tester.pump();
      final container = tester.widget<GjaContainer>(_bubble(_message).first);
      expect(container.surface, GjaSurface.base);
      expect(container.border, isTrue);
      expect(container.radius, GjaRadius.s);
      expect(container.shadow, GjaShadow.popover);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: _bubble(_message).first,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, theme.colors.base);
      expect(decoration.border!.top.color, theme.colors.separator);
      expect(decoration.boxShadow, hasLength(theme.shadows.popover.length));
      final style = tester.widget<Text>(find.text(_message).last).style!;
      expect(style.fontSize, theme.typography.base.fontSize);
      expect(style.color, theme.colors.text);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
    }
  });

  testWidgets(
    '[Aparência] Movimento da dica — Abertura sem atraso no movimento reduzido',
    (tester) async {
      await tester.pumpWidget(
        _app(
          reduceMotion: true,
          Center(
            child: GjaTooltip(message: _message, child: _icon()),
          ),
        ),
      );
      await _hover(tester, find.byKey(const Key('icon')));
      await tester.pump();
      expect(find.text(_message), findsOneWidget);
    },
  );

  group('Teclado e foco', () {
    late FocusNode first;
    late FocusNode second;

    Future<void> pumpFocused(WidgetTester tester) async {
      first = FocusNode();
      second = FocusNode();
      addTearDown(() {
        first.dispose();
        second.dispose();
      });
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              GjaTooltip(
                message: _message,
                child: Focus(focusNode: first, child: _icon()),
              ),
              Focus(focusNode: second, child: _icon('other')),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.text(_message), findsOneWidget);
    }

    testWidgets('[Estados] Sem estados próprios — Dica não recebe foco', (
      tester,
    ) async {
      await pumpFocused(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.hasPrimaryFocus, isTrue);
    });

    testWidgets('[Acessibilidade] Teclado — Esc fecha a dica', (tester) async {
      await pumpFocused(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text(_message), findsNothing);
      expect(first.hasPrimaryFocus, isTrue);
    });
  });

  testWidgets(
    '[Acessibilidade] Semântica e contraste — Mensagem na semântica do filho',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Center(
            child: GjaTooltip(
              message: _message,
              child: Semantics(button: true, label: 'Editar', child: _icon()),
            ),
          ),
        ),
      );
      await tester.longPress(find.byKey(const Key('icon')));
      await tester.pump();
      expect(find.text(_message), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('icon'))),
        containsSemantics(label: 'Editar', tooltip: _message, isButton: true),
      );
      expect(find.bySemanticsLabel(_message), findsNothing);
      handle.dispose();
    },
  );

  testWidgets(
    '[Acessibilidade] Semântica e contraste — Dica fora da semântica',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Center(
            child: GjaTooltip(
              message: _message,
              excludeFromSemantics: true,
              child: Semantics(button: true, label: _message, child: _icon()),
            ),
          ),
        ),
      );
      await tester.longPress(find.byKey(const Key('icon')));
      await tester.pump();
      expect(find.text(_message), findsOneWidget);
      final node = tester.getSemantics(find.byKey(const Key('icon')));
      expect(node.tooltip, isEmpty);
      expect(find.bySemanticsLabel(_message), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('[Responsividade] Bordas e direção — Dica junto à borda', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.bottomRight,
          child: GjaTooltip(message: _long, child: _icon()),
        ),
      ),
    );
    await tester.longPress(find.byKey(const Key('icon')));
    await tester.pump();
    final icon = tester.getRect(find.byKey(const Key('icon')));
    final bubble = tester.getRect(_bubble(_long).first);
    expect(bubble.bottom, lessThanOrEqualTo(icon.top));
    expect(bubble.right, lessThanOrEqualTo(800));
    expect(bubble.left, greaterThanOrEqualTo(0));
    expect(bubble.width, lessThanOrEqualTo(_light.spacing.xxxl * 6 + 0.01));
  });

  testWidgets('[Integração] Dependências — Tooltip sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Center(
          child: GjaTooltip(message: _message, child: _icon()),
        ),
      ),
    );
    await tester.longPress(find.byKey(const Key('icon')));
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text(_message), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da dica', () {
      final names = scenarioNames(
        'gja/widgets/gja-tooltip',
        'add-gja-tooltip',
      );
      expect(names, hasLength(22));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da dica', (tester) async {
      await loadGjaFonts();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(480, 240);
      addTearDown(tester.view.reset);
      for (final (name, theme) in goldenThemes) {
        for (final (kind, message) in [('short', _message), ('long', _long)]) {
          await tester.pumpWidget(
            _app(
              theme: theme,
              reduceMotion: true,
              // O fundo da aplicação fica fora da captura; a amostra o pinta.
              GjaContainer(
                surface: GjaSurface.background,
                child: Align(
                  key: ValueKey('$name-$kind'),
                  alignment: const Alignment(0, -0.6),
                  child: GjaTooltip(
                    message: message,
                    child: const GjaIcon(GjaIcons.edit),
                  ),
                ),
              ),
            ),
          );
          await tester.longPress(find.byType(GjaIcon));
          await tester.pumpAndSettle();
          await expectLater(
            find.byKey(const Key('golden')),
            matchesGoldenFile('goldens/gja_tooltip_${kind}_$name.png'),
          );
          await tester.tapAt(Offset.zero);
          await tester.pump();
        }
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Tooltip sem valor literal', () {
    final source = File(
      'lib/src/exibicao_dados/tooltip/gja_tooltip.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).map((m) => (m.group(1)!, m.group(2)!)).toList();
    expect(fields, contains(('String', 'message')));
    for (final (type, name) in fields) {
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
      if (type == 'Widget') expect(name, 'child');
    }
  });
}
