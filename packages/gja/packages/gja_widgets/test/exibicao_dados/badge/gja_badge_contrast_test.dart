import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.
void main() {
  testWidgets('[Acessibilidade] Contraste — Contraste do contador', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
      await tester.pumpWidget(
        GjaTheme(
          key: ValueKey(theme.brightness),
          data: theme,
          duration: Duration.zero,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GjaContainer(
              surface: GjaSurface.background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final state in GjaValueState.values)
                      GjaBadge(count: 128, state: state),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
    handle.dispose();
  });
}
