import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_separator_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaSeparator na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 1200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());
      await openGalleryPage(tester, GjaSeparatorPage.title);

      Iterable<Size> strokes(Key key) => [
        for (final e
            in find
                .descendant(
                  of: find.descendant(
                    of: find.byKey(key),
                    matching: find.byType(GjaSeparator),
                  ),
                  matching: find.byType(ColoredBox),
                )
                .evaluate())
          (e.renderObject! as RenderBox).size,
      ];

      final horizontal = strokes(GjaSeparatorPage.listKey);
      expect(horizontal, hasLength(2));
      expect(horizontal.every((s) => s.width > s.height), isTrue);
      final vertical = strokes(GjaSeparatorPage.barKey);
      expect(vertical, hasLength(1));
      expect(vertical.single.height, greaterThan(vertical.single.width));
      expect(tester.takeException(), isNull);
    },
  );
}
