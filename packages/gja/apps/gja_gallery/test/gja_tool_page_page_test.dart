import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_tool_page_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaToolPage na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 900);
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaToolPagePage.title);
      expect(find.byKey(GjaToolPagePage.navigationKey), findsNothing);
      expect(
        find.semantics.byLabel(
          RegExp(RegExp.escape(GjaToolPagePage.bodyText)),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(GjaIcons.menu2));
      await tester.pumpAndSettle();
      final navigation = tester.getRect(
        find.byKey(GjaToolPagePage.navigationKey),
      );
      expect(navigation.width, 500);
      expect(
        navigation.overlaps(
          tester.getRect(find.byKey(GjaToolPagePage.mainKey)),
        ),
        isTrue,
      );
      expect(
        find.semantics.byLabel(
          RegExp(RegExp.escape(GjaToolPagePage.bodyText)),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );
}
