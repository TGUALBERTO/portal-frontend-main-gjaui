import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_input_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaInput na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaInputPage.title);
      final name = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is GjaInput && w.semanticLabel == GjaInputPage.nameLabel,
        ),
        matching: find.byType(EditableText),
      );
      await tester.tap(name);
      await tester.pump();
      await tester.enterText(name, 'Ana');
      await tester.pump();
      expect(find.text('Olá, Ana'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
