import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_check_box_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaCheckBox na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaCheckBoxPage.title);
      GjaCheckBox terms() => tester.widget<GjaCheckBox>(
        find.widgetWithText(GjaCheckBox, GjaCheckBoxPage.terms),
      );
      expect(terms().selected, isFalse);

      await tester.tap(find.text(GjaCheckBoxPage.terms));
      await tester.pump();
      expect(terms().selected, isTrue);
      expect(
        tester
            .widget<GjaCheckBox>(
              find.widgetWithText(GjaCheckBox, 'Todos os canais'),
            )
            .partiallySelected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
