import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/breakpoints_page.dart';

void main() {
  testWidgets('Testes e documentação dos breakpoints — Página na galeria', (
    tester,
  ) async {
    // MediaQuery lê o tamanho da view, não o da superfície de render.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const cases = <(double, String)>[
      (500, 'small'),
      (800, 'medium'),
      (1200, 'large'),
      (1600, 'extraLarge'),
    ];
    for (final (width, expected) in cases) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpWidget(const GjaGalleryApp());
      await tester.tap(find.text(BreakpointsPage.title));
      await tester.pumpAndSettle();

      final current = tester.widget<Text>(
        find.byKey(BreakpointsPage.currentClassKey),
      );
      expect(current.data, 'Classe atual: $expected', reason: '$width px');
      for (final line in [
        'medium ≥ 600 px',
        'large ≥ 1024 px',
        'extraLarge ≥ 1440 px',
      ]) {
        expect(find.text(line), findsOneWidget, reason: '$width px: $line');
      }
      // Recria a árvore para a próxima largura, a partir do índice.
      await tester.pumpWidget(const SizedBox());
    }
  });
}
