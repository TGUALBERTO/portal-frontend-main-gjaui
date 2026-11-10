import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/shadows_page.dart';
import 'package:gja_ui/gja_ui.dart';

void main() {
  testWidgets('Testes e documentação das sombras — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(ShadowsPage.title));
    await tester.pumpAndSettle();

    const shadows = GjaShadowTokens.fallback();
    for (final (mode, colors) in [
      ('claro', GjaColorTokens.light()),
      ('escuro', GjaColorTokens.dark()),
    ]) {
      for (final MapEntry(key: name, value: shadow) in shadows.values.entries) {
        final card = tester.widget<Container>(
          find.byKey(ShadowsPage.cardKey(mode, name)),
        );
        final decoration = card.decoration! as BoxDecoration;
        expect(
          decoration.boxShadow,
          shadows.boxShadows(shadow, colors.shadow),
          reason: '$mode/$name',
        );
      }
      expect(find.text(mode), findsOneWidget);
    }
    expect(find.text('card'), findsNWidgets(2));
    expect(find.text('dialog'), findsNWidgets(2));
  });
}
