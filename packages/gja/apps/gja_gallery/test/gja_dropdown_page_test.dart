import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_dropdown_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaDropdown na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaDropdownPage.title);

      await tester.tap(find.text(GjaDropdownPage.status('Em aberto')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprovado'));
      await tester.pumpAndSettle();

      expect(find.text('Rejeitado'), findsNothing);
      expect(find.text(GjaDropdownPage.status('Aprovado')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
