import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_menu_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaMenu na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await openGalleryPage(tester, GjaMenuPage.title);

    await tester.tap(find.text(GjaMenuPage.actions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir'), findsNothing);
    expect(find.text(GjaMenuPage.lastAction('Copiar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
