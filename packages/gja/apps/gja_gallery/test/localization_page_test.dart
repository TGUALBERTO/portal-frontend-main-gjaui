import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/localization_page.dart';

void main() {
  testWidgets('Testes e documentação da localização — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(LocalizationPage.title));
    await tester.pumpAndSettle();

    expect(find.text('cancel: Cancelar'), findsOneWidget);
    expect(find.text('decimal: 1.234.567,89'), findsOneWidget);
    expect(find.text('1000: 1.000 itens selecionados'), findsOneWidget);

    await tester.tap(find.text('en'));
    await tester.pumpAndSettle();

    expect(find.text('cancel: Cancel'), findsOneWidget);
    expect(find.text('decimal: 1,234,567.89'), findsOneWidget);
    expect(find.text('cancel: Cancelar'), findsNothing);
  });
}
