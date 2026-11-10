import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_toolbar_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaToolbar na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaToolbarPage.title);
      await tester.tap(find.text(GjaToolbarPage.filters));
      await tester.pumpAndSettle();
      expect(find.text(GjaToolbarPage.cleared), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
