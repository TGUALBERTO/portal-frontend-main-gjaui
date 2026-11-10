import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_theme_page.dart';
import 'package:gja_ui/gja_ui.dart';

Color _previewColor(WidgetTester tester) {
  final box = tester.widget<Container>(find.byKey(GjaThemePage.previewKey));
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(GjaThemePage.title));
    await tester.pumpAndSettle();
    expect(_previewColor(tester), GjaThemeData.light().colors.base);

    await tester.tap(find.text('Tema: claro'));
    await tester.pumpAndSettle();
    expect(_previewColor(tester), GjaThemeData.dark().colors.base);

    final compact = GjaThemeData.light(density: GjaDensity.compact);
    final cozy = GjaThemeData.light();
    expect(
      tester.getSize(find.byKey(GjaThemePage.compactKey)).height,
      greaterThanOrEqualTo(compact.density.minTargetSize),
    );
    expect(
      tester.getSize(find.byKey(GjaThemePage.cozyKey)).height,
      greaterThanOrEqualTo(cozy.density.minTargetSize),
    );
    expect(
      find.text('Alvo mínimo: ${compact.density.minTargetSize.round()}'),
      findsOneWidget,
    );
    expect(
      find.text('Alvo mínimo: ${cozy.density.minTargetSize.round()}'),
      findsOneWidget,
    );
  });
}
