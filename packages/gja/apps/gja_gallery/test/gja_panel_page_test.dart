import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_panel_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaPanel na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaPanelPage.title);
      expect(find.text('Boleto em 30 dias').hitTestable(), findsNothing);
      await tester.tap(find.text('Pagamento'));
      await tester.pumpAndSettle();
      expect(find.text('Boleto em 30 dias').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
