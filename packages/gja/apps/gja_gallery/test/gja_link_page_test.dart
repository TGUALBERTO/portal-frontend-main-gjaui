import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_link_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaLink na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await openGalleryPage(tester, GjaLinkPage.title);
    expect(find.text(GjaLinkPage.opened), findsNothing);

    await tester.tap(find.text(GjaLinkPage.orderLink));
    await tester.pumpAndSettle();
    expect(find.text(GjaLinkPage.opened), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
