import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.
void main() {
  testWidgets(
    '[Acessibilidade] Semântica e contraste — Texto sobre as superfícies',
    (tester) async {
      final handle = tester.ensureSemantics();
      for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
        await tester.pumpWidget(
          GjaTheme(
            key: ValueKey(theme.brightness),
            data: theme,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                children: [
                  for (final surface in GjaSurface.values.skip(1))
                    GjaContainer(
                      surface: surface,
                      padding: GjaSpace.s,
                      child: GjaText('texto ${surface.name}'),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      handle.dispose();
    },
  );
}
