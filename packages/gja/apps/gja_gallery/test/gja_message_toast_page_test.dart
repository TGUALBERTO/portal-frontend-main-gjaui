import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_message_toast_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaMessageToast na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaMessageToastPage.title);
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(find.text(GjaMessageToastPage.saved), findsOneWidget);
      await tester.pump(GjaMessageToast.defaultDuration);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
