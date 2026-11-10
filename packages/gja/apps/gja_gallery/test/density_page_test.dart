import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/density_page.dart';
import 'package:gja_ui/gja_ui.dart';

void main() {
  testWidgets('Testes e documentação da densidade — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(DensityPage.title));
    await tester.pumpAndSettle();

    const expected = {
      GjaDensity.cozy: (36.0, 'controle 36 · item 44 · alvo 44'),
      GjaDensity.compact: (26.0, 'controle 26 · item 32 · alvo 32'),
    };
    for (final MapEntry(key: density, value: (height, measures))
        in expected.entries) {
      expect(find.text(density.name), findsOneWidget, reason: density.name);
      expect(find.text(measures), findsOneWidget, reason: density.name);
      final control = tester.getSize(
        find.byKey(DensityPage.controlKey(density)),
      );
      expect(control.height, height, reason: density.name);
    }
  });
}
