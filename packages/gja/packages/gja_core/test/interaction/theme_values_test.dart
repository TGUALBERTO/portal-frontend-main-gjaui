import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

const _key = Key('target');

/// Elemento interativo de conteúdo 16 × 16 sob [theme].
Widget _app(GjaThemeData theme, {double? minTargetSize}) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    builder: (context, _) => GjaThemeScope(
      data: theme,
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foco inicial: o Tab seguinte leva o foco ao alvo pelo teclado.
            const Focus(autofocus: true, child: SizedBox(width: 1, height: 1)),
            GjaInteractable(
              key: _key,
              onPressed: () {},
              minTargetSize: minTargetSize,
              builder: (context, states) =>
                  const SizedBox(width: 16, height: 16),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('Valores do tema ativo', () {
    testWidgets(
      'Valores do tema ativo — Tema com densidade compacta e marca própria',
      (tester) async {
        final base = GjaThemeData.light(density: GjaDensity.compact);
        final focus = GjaThemeData.dark().colors.focus;
        final theme = base.copyWith(colors: base.colors.copyWith(focus: focus));
        await tester.pumpWidget(_app(theme));
        await tester.pump();

        final size = tester.getSize(find.byKey(_key));
        expect(size.width, greaterThanOrEqualTo(theme.density.minTargetSize));
        expect(
          size.width,
          lessThan(GjaThemeData.light().density.minTargetSize),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final ring = tester.widget<GjaFocusRing>(
          find.descendant(
            of: find.byKey(_key),
            matching: find.byType(GjaFocusRing),
          ),
        );
        expect(ring.visible, isTrue);
        expect(ring.color, focus);
        expect(ring.width, theme.interaction.focusWidth);
        expect(ring.borderRadius, BorderRadius.circular(theme.radius.button));
      },
    );

    testWidgets('Valores do tema ativo — Valor recebido vence o tema', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          GjaThemeData.light(density: GjaDensity.compact),
          minTargetSize: 48,
        ),
      );
      final size = tester.getSize(find.byKey(_key));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('sem tema na árvore, usa o tema claro de referência', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: GjaInteractable(
              key: _key,
              onPressed: () {},
              builder: (context, states) =>
                  const SizedBox(width: 16, height: 16),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(_key)).width,
        GjaAccessibility.defaultMinTargetSize,
      );
    });
  });
}
