import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_illustrated_message_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaIllustratedMessage na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 1400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaIllustratedMessagePage.title);
      expect(find.text(GjaIllustratedMessagePage.list), findsNothing);
      await tester.tap(find.text(GjaIllustratedMessagePage.clear));
      await tester.pumpAndSettle();
      expect(find.text(GjaIllustratedMessagePage.list), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
