import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_container_page.dart';
import 'package:gja_ui/gja_ui.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaContainer na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 2200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await tester.tap(find.text(GjaContainerPage.title));
      await tester.pumpAndSettle();

      Iterable<GjaContainer> containers() =>
          tester.widgetList<GjaContainer>(find.byType(GjaContainer));
      for (final surface in GjaSurface.values) {
        expect(
          containers().where((c) => c.surface == surface && c.border),
          isNotEmpty,
          reason: surface.name,
        );
      }
      for (final radius in GjaRadius.values) {
        expect(find.text(radius.name), findsWidgets, reason: radius.name);
      }
      for (final shadow in GjaShadow.values) {
        expect(
          containers().where((c) => c.shadow == shadow),
          isNotEmpty,
          reason: shadow.name,
        );
      }
      final card = tester.widget<GjaContainer>(
        find.byKey(GjaContainerPage.cardKey),
      );
      expect(card.surface, GjaSurface.base);
      expect(card.border, isTrue);
      expect(card.radius, GjaRadius.tile);
      expect(card.shadow, GjaShadow.card);
      expect(card.padding, GjaSpace.l);
    },
  );
}
