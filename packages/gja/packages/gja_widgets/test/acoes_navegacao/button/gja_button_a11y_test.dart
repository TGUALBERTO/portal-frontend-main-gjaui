import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.

Widget _buttons(GjaThemeData theme, {double textScale = 1}) => GjaTheme(
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in GjaButtonType.values)
                  GjaButton(
                    text: type.name,
                    type: type,
                    icon: GjaIcons.accept,
                    onPress: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('[Acessibilidade] Contraste, alvo e escala — Contraste e alvo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
      for (final density in GjaDensity.values) {
        final theme = base.withDensity(density);
        await tester.pumpWidget(_buttons(theme));
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
    }
    handle.dispose();
  });

  testWidgets(
    '[Acessibilidade] Contraste, alvo e escala — Escala de texto 2,0',
    (tester) async {
      final theme = GjaThemeData.light();
      await tester.pumpWidget(_buttons(theme, textScale: 2));
      expect(tester.takeException(), isNull);
      for (final box
          in find
              .descendant(
                of: find.byType(GjaButton),
                matching: find.byType(DecoratedBox),
              )
              .evaluate()) {
        expect(
          tester.getSize(find.byWidget(box.widget)).height,
          greaterThanOrEqualTo(theme.density.controlHeight),
        );
      }

      // O botão só com ícone mantém o tamanho (a dica precisa do Overlay).
      await tester.pumpWidget(
        GjaApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Center(
            child: GjaButton(
              icon: GjaIcons.edit,
              tooltip: 'Editar',
              onPress: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(
          find
              .descendant(
                of: find.byType(GjaButton),
                matching: find.byType(DecoratedBox),
              )
              .first,
        ),
        Size.square(theme.density.controlHeight),
      );
    },
  );
}
