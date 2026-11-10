import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_page_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaPage na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await openGalleryPage(tester, GjaPagePage.title);
    GjaPage page() => tester.widget<GjaPage>(find.byType(GjaPage));
    expect(page().floatingFooter, isFalse);

    await tester.tap(find.byKey(GjaPagePage.floatingKey));
    await tester.pumpAndSettle();
    expect(page().floatingFooter, isTrue);

    final list = find.byKey(
      GjaPagePage.designKey(GjaPageBackgroundDesign.list),
    );
    await tester.ensureVisible(list);
    await tester.tap(list);
    await tester.pumpAndSettle();
    expect(page().backgroundDesign, GjaPageBackgroundDesign.list);

    await tester.tap(find.byIcon(GjaIcons.navBack));
    await tester.pumpAndSettle();
    expect(find.byType(GjaPage), findsNothing);
    expect(find.text(GjaPagePage.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
