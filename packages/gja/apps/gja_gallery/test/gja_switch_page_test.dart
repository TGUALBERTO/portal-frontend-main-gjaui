import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_switch_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaSwitch na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaSwitchPage.title);
      final finder = find.byWidgetPredicate(
        (w) =>
            w is GjaSwitch &&
            w.semanticLabel == GjaSwitchPage.notifications,
      );
      expect(tester.widget<GjaSwitch>(finder).state, isFalse);

      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(tester.widget<GjaSwitch>(finder).state, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
