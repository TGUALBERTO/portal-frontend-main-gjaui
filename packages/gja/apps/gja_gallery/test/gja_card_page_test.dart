import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_card_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

Future<void> _open(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const GjaGalleryApp());
  await openGalleryPage(tester, GjaCardPage.title);
}

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaCard na galeria', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text(GjaCardPage.opened), findsNothing);

    await tester.tap(find.text(GjaCardPage.pendingTitle));
    await tester.pumpAndSettle();
    expect(find.text(GjaCardPage.opened), findsOneWidget);
    expect(
      tester
          .widget<GjaCard>(find.byKey(GjaCardPage.bottomCardKey))
          .headerPosition,
      GjaCardHeaderPosition.bottom,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '[Documentação] Exemplos mínimos — Cabeçalhos na página GjaCard',
    (tester) async {
      await _open(tester);
      final full = tester.widget<GjaCardHeader>(
        find.byKey(GjaCardPage.fullHeaderKey),
      );
      expect(full.iconInitials, isNotNull);
      expect(full.statusText, isNotNull);
      expect(full.dataTimestamp, isNotNull);
      final actionable = tester.widget<GjaCardHeader>(
        find.ancestor(
          of: find.text(GjaCardPage.pendingTitle),
          matching: find.byType(GjaCardHeader),
        ),
      );
      expect(actionable.onPress, isNotNull);
      expect(
        tester
            .widget<GjaCardHeader>(find.byKey(GjaCardPage.toolbarHeaderKey))
            .toolbar,
        isNotNull,
      );
    },
  );
}
