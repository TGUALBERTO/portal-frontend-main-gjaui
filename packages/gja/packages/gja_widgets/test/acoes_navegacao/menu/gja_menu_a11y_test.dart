import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.
void main() {
  testWidgets('[Acessibilidade] Contraste e alvo — Contraste e alvo do menu', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
      for (final density in GjaDensity.values) {
        final theme = base.withDensity(density);
        final controller = GjaPopoverController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          GjaApp(
            key: ValueKey((theme.brightness, density)),
            theme: theme,
            darkTheme: theme,
            density: density,
            home: GjaContainer(
              surface: GjaSurface.background,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: GjaMenu(
                    controller: controller,
                    semanticLabel: 'Ações',
                    items: [
                      GjaMenuItem(
                        text: 'Editar',
                        icon: GjaIcons.edit,
                        shortcutText: 'Ctrl+E',
                        onPress: () {},
                      ),
                      GjaMenuItem(
                        text: 'Copiar',
                        icon: GjaIcons.copy,
                        shortcutText: 'Ctrl+C',
                        onPress: () {},
                      ),
                      GjaMenuItem(
                        text: 'Excluir',
                        icon: GjaIcons.delete,
                        startsSection: true,
                        onPress: () {},
                      ),
                    ],
                    child: GjaButton(
                      text: 'Ações',
                      onPress: controller.toggle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        controller.open();
        await tester.pumpAndSettle();
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
}
