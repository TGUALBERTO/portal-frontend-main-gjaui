import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.
void main() {
  testWidgets('[Acessibilidade] Semântica e contraste — Contraste do título', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
      for (final surface in [theme.colors.base, theme.colors.background]) {
        await tester.pumpWidget(
          GjaTheme(
            // Chave por tema: sem transição entre um tema e outro.
            key: ValueKey((theme.brightness, surface)),
            data: theme,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ColoredBox(
                color: surface,
                child: Column(
                  children: [
                    for (final style in GjaTitleLevel.values)
                      GjaTitle('Título ${style.name}', titleStyle: style),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
    }
    handle.dispose();
  });
}
