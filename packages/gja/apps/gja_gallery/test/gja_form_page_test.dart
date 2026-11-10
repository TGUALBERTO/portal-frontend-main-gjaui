import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_form_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaForm na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await openGalleryPage(tester, GjaFormPage.title);
    final name = find.byType(EditableText).first;
    await tester.tap(name);
    await tester.pump();
    await tester.enterText(name, 'ACME');
    await tester.pump();
    expect(find.text('Resumo: ACME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
