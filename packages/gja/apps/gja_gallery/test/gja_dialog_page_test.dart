import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_dialog_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaDialog na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaDialogPage.title);
      await tester.tap(find.text(GjaDialogPage.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      expect(find.text(GjaDialogPage.deleted), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
