import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_breadcrumbs_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaBreadcrumbs na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaBreadcrumbsPage.title);
      final trail = find.byKey(GjaBreadcrumbsPage.trailKey);
      await tester.tap(
        find.descendant(of: trail, matching: find.text('Pedidos')),
      );
      await tester.pump();
      expect(
        tester.widget<GjaBreadcrumbs>(trail).currentLocationText,
        'Pedidos',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
