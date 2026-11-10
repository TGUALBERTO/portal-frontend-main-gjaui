import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_message_strip_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaMessageStrip na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaMessageStripPage.title);
      expect(find.text(GjaMessageStripPage.closable), findsOneWidget);
      final close = find.descendant(
        of: find.widgetWithText(
          GjaMessageStrip,
          GjaMessageStripPage.closable,
        ),
        matching: find.byType(GjaButton),
      );
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text(GjaMessageStripPage.closable), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
