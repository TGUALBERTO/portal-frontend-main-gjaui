import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_object_status_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaObjectStatus na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaObjectStatusPage.title);
      expect(find.text(GjaObjectStatusPage.opened), findsNothing);

      await tester.tap(find.text(GjaObjectStatusPage.pending));
      await tester.pumpAndSettle();
      expect(find.text(GjaObjectStatusPage.opened), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
