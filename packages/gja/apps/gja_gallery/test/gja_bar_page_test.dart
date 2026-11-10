import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_bar_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaBar na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await openGalleryPage(tester, GjaBarPage.title);

    for (final design in GjaBarPage.designs) {
      expect(
        tester
            .widget<GjaBar>(find.byKey(GjaBarPage.designKey(design)))
            .design,
        design,
      );
    }
    for (final alignment in [
      GjaTitleAlignment.none,
      GjaTitleAlignment.start,
    ]) {
      expect(
        tester
            .widget<GjaBar>(find.byKey(GjaBarPage.alignmentKey(alignment)))
            .titleAlignment,
        alignment,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
