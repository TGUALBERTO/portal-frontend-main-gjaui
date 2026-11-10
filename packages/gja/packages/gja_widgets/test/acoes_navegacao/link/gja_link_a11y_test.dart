import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.

Widget _links(GjaThemeData theme, {double textScale = 1}) => GjaTheme(
  key: ValueKey((theme.brightness, theme.density.density, textScale)),
  data: theme,
  duration: Duration.zero,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: GjaContainer(
          surface: GjaSurface.background,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GjaLink(text: 'Ver pedido', onPress: () {}),
                GjaLink(text: 'Ver nota', subtle: true, onPress: () {}),
                GjaLink(text: 'Ver fatura', emphasized: true, onPress: () {}),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    '[Acessibilidade] Contraste, alvo e escala — Contraste e alvo do link',
    (tester) async {
      final handle = tester.ensureSemantics();
      for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
        for (final density in GjaDensity.values) {
          final theme = base.withDensity(density);
          await tester.pumpWidget(_links(theme));
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
          // Contraste calculado sobre a outra superfície do tema.
          for (final color in [theme.colors.link, theme.colors.text]) {
            expect(
              gjaContrastRatioOver(color, theme.colors.base),
              greaterThanOrEqualTo(GjaAccessibility.minTextContrast),
            );
          }
        }
      }
      handle.dispose();
    },
  );

  testWidgets(
    '[Acessibilidade] Contraste, alvo e escala — Link com escala de texto 2,0',
    (tester) async {
      final theme = GjaThemeData.light();
      await tester.pumpWidget(_links(theme));
      final normal = tester.getSize(find.text('Ver pedido')).height;
      await tester.pumpWidget(_links(theme, textScale: 2));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text('Ver pedido')).height,
        greaterThan(normal),
      );
    },
  );
}
