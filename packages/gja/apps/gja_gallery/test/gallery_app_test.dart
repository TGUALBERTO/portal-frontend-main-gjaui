import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_ui/gja_ui.dart';

/// Spec `gja/widgets/gja-app`: a galeria usa `GjaApp` como raiz.
void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    Finder background(GjaThemeData theme) => find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == theme.colors.background,
    );
    expect(find.byType(GjaApp), findsOneWidget);
    expect(background(GjaThemeData.light()), findsOneWidget);

    await tester.tap(find.text('Tema: escuro'));
    await tester.pumpAndSettle();
    expect(background(GjaThemeData.dark()), findsOneWidget);

    await tester.tap(find.text('Densidade: compacta'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text(GjaGalleryApp.title));
    expect(GjaTheme.of(context).density.density, GjaDensity.compact);
  });
}
