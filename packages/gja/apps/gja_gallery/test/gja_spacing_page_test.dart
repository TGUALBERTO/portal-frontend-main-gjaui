import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_spacing_page.dart';
import 'package:gja_ui/gja_ui.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaSpacing na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 2000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await tester.tap(find.text('Densidade: cozy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(GjaSpacingPage.title));
      await tester.pumpAndSettle();

      final spacing = GjaThemeData.light().spacing;
      for (final space in GjaSpace.values) {
        expect(find.text(space.name), findsOneWidget, reason: space.name);
        expect(
          tester.getSize(find.byKey(GjaSpacingPage.barKey(space))).width,
          GjaSpacing.resolve(spacing, space),
          reason: space.name,
        );
      }

      // Mesmo padding `l` nas duas densidades: o compacto é menor.
      double inset(GjaDensity density) {
        final text = find.byKey(GjaSpacingPage.paddedKey(density));
        final box = find.ancestor(
          of: text,
          matching: find.byType(DecoratedBox),
        );
        return tester.getTopLeft(text).dx - tester.getTopLeft(box.first).dx;
      }

      final compact = GjaThemeData.light(density: GjaDensity.compact);
      expect(inset(GjaDensity.cozy), spacing.l);
      expect(inset(GjaDensity.compact), compact.spacing.l);
    },
  );
}
