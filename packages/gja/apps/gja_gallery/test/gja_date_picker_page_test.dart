import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_date_picker_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaDatePicker na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaDatePickerPage.title);
      final field = find.byType(EditableText).first;
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, '20/03/2030');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Entrega: 20/03/2030'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
