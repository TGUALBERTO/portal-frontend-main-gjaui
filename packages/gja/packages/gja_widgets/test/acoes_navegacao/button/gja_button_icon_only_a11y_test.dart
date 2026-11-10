import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter, como nos demais testes de acessibilidade.

const _families = {
  GjaButtonType.standard: GjaControlFamily.standard,
  GjaButtonType.emphasized: GjaControlFamily.emphasized,
  GjaButtonType.transparent: GjaControlFamily.transparent,
  GjaButtonType.accept: GjaControlFamily.accept,
  GjaButtonType.reject: GjaControlFamily.reject,
  GjaButtonType.attention: GjaControlFamily.attention,
};

void main() {
  testWidgets(
    '[Acessibilidade] Contraste, alvo e escala — Contraste e alvo (só com ícone)',
    (tester) async {
      final handle = tester.ensureSemantics();
      for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
        for (final density in GjaDensity.values) {
          final theme = base.withDensity(density);
          await tester.pumpWidget(
            GjaApp(
              key: ValueKey((theme.brightness, density)),
              theme: theme,
              darkTheme: theme,
              density: density,
              home: Center(
                child: Wrap(
                  spacing: 8,
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
              ),
            ),
          );
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
          // Contraste não textual do ícone sobre o fundo de cada estado.
          final c = theme.colors;
          for (final type in GjaButtonType.values) {
            final family = GjaControlColors.of(_families[type]!, c);
            for (final state in family.states.values) {
              final grounds = state.background.a == 0
                  ? [c.base, c.background]
                  : [state.background];
              for (final ground in grounds) {
                expect(
                  gjaContrastRatioOver(state.text, ground),
                  greaterThanOrEqualTo(GjaAccessibility.minNonTextContrast),
                  reason: '${theme.brightness.name}/${type.name}',
                );
              }
            }
          }
        }
      }
      handle.dispose();
    },
  );
}
