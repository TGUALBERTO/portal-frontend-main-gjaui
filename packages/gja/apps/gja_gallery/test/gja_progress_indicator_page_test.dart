import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_progress_indicator_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaProgressIndicator na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaProgressIndicatorPage.title);
      final indicators = tester
          .widgetList<GjaProgressIndicator>(
            find.byType(GjaProgressIndicator),
          )
          .toList();
      expect(
        indicators.map((i) => i.state).toSet(),
        GjaValueState.values.toSet(),
      );

      double advancing() => tester
          .widget<GjaProgressIndicator>(
            find.byKey(GjaProgressIndicatorPage.advancingKey),
          )
          .percentValue;
      final before = advancing();
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(advancing(), before + 10);
      expect(tester.takeException(), isNull);
    },
  );
}
