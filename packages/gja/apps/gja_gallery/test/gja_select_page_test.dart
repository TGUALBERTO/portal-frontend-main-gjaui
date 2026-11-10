import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_select_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaSelect na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaSelectPage.title);
      final status = find.byWidgetPredicate(
        (w) =>
            w is GjaSelect<String> &&
            w.semanticLabel == GjaSelectPage.statusLabel,
      );
      await tester.tap(status);
      await tester.pumpAndSettle();
      // O item da lista, cujo elemento interativo tem o nome do item.
      final item = find.byWidgetPredicate(
        (w) => w is GjaInteractable && w.semanticLabel == 'Aprovado',
      );
      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(
        tester.widget<GjaSelect<String>>(status).selectedKey,
        'aprovado',
      );
      expect(
        find.descendant(of: status, matching: find.text('Aprovado')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
