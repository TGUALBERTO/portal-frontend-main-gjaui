import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_icon_tab_bar_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaIconTabBar na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaIconTabBarPage.title);
      expect(find.text(GjaIconTabBarPage.attachments), findsNothing);
      await tester.tap(find.text('Anexos'));
      await tester.pump();
      expect(find.text(GjaIconTabBarPage.attachments), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
