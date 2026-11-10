import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_radio_button_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

Future<void> _open(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const GjaGalleryApp());
  await openGalleryPage(tester, GjaRadioButtonPage.title);
}

GjaRadioButton _option(WidgetTester tester, String text) => tester
    .widget<GjaRadioButton>(find.widgetWithText(GjaRadioButton, text));

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaRadioButton na galeria',
    (tester) async {
      await _open(tester);
      expect(_option(tester, GjaRadioButtonPage.single).selected, isFalse);
      await tester.tap(find.text(GjaRadioButtonPage.single));
      await tester.pump();
      expect(_option(tester, GjaRadioButtonPage.single).selected, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaRadioButtonGroup na galeria',
    (tester) async {
      await _open(tester);
      expect(_option(tester, 'Boleto').selected, isTrue);
      await tester.tap(find.text('Pix'));
      await tester.pump();
      expect(_option(tester, 'Pix').selected, isTrue);
      expect(_option(tester, 'Boleto').selected, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
