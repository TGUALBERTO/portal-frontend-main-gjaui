import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_popover_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaPopover na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaPopoverPage.title);
      expect(find.text(GjaPopoverPage.applied), findsNothing);

      await tester.tap(find.text(GjaPopoverPage.filter));
      await tester.pumpAndSettle();
      expect(find.text('Filtros'), findsOneWidget);

      await tester.tap(find.text(GjaPopoverPage.apply));
      await tester.pumpAndSettle();
      expect(find.text('Filtros'), findsNothing);
      expect(find.text(GjaPopoverPage.applied), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
