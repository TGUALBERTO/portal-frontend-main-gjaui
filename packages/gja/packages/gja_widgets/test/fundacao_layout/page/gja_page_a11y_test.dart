import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.

Widget _page(GjaThemeData theme) => GjaTheme(
  key: ValueKey((theme.brightness, theme.density.density)),
  data: theme,
  duration: Duration.zero,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: GjaPage(
      title: 'Pedido 4711',
      titleLevel: GjaTitleLevel.h2,
      showNavButton: true,
      onNavButtonPress: () {},
      content: const [GjaText('Itens do pedido')],
    ),
  ),
);

void _view(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('[Acessibilidade] Semântica e contraste — Semântica da página', (
    tester,
  ) async {
    _view(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_page(GjaThemeData.light()));
    final title = tester
        .getSemantics(find.text('Pedido 4711'))
        .getSemanticsData();
    expect(title.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(title.headingLevel, 2);
    expect(
      tester.getSemantics(find.byType(GjaInteractable)),
      containsSemantics(isButton: true, label: 'Voltar', hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets(
    '[Acessibilidade] Semântica e contraste — Contraste e alvo na página',
    (tester) async {
      _view(tester);
      final handle = tester.ensureSemantics();
      for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
        for (final density in GjaDensity.values) {
          final theme = base.withDensity(density);
          await tester.pumpWidget(_page(theme));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
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
    },
  );
}
