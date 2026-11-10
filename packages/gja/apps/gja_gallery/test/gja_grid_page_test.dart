import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_grid_page.dart';

/// Cartões da primeira grade na mesma linha do primeiro.
int _perRow(WidgetTester tester) {
  final top = tester.getTopLeft(find.byKey(GjaGridPage.cardKey(0))).dy;
  return [
    for (var i = 0; i < 6; i++)
      tester.getTopLeft(find.byKey(GjaGridPage.cardKey(i))).dy,
  ].where((t) => t == top).length;
}

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaGrid na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(GjaGridPage.title));
    await tester.pumpAndSettle();
    expect(_perRow(tester), 4);
    expect(find.byKey(GjaGridPage.highlightKey), findsOneWidget);

    tester.view.physicalSize = const Size(500, 2400);
    await tester.pumpAndSettle();
    expect(_perRow(tester), 1);
    expect(tester.takeException(), isNull);
  });
}
