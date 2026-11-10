import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

// Sem carregar a Inter: a diretriz de contraste mede os pixels do texto, e os
// glifos sólidos da fonte de teste padrão dão as cores reais de frente e fundo.
void main() {
  testWidgets('[Acessibilidade] Contraste e alvo — Contraste e alvo na barra', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 400);
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
      for (final density in GjaDensity.values) {
        final theme = base.withDensity(density);
        await tester.pumpWidget(
          GjaTheme(
            key: ValueKey((theme.brightness, density)),
            data: theme,
            duration: Duration.zero,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topCenter,
                child: GjaShellBar(
                  title: 'Compras',
                  secondTitle: 'Pedidos',
                  showMenuButton: true,
                  showSearch: true,
                  showNotifications: true,
                  showProductSwitcher: true,
                  profile: const GjaAvatar(initials: 'TA'),
                  onMenuButtonPressed: () {},
                  onSearchButtonPressed: () {},
                  onNotificationsPressed: () {},
                  onProductSwitcherPressed: () {},
                  onAvatarPressed: () {},
                ),
              ),
            ),
          ),
        );
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
  });
}
