import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_table_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaTable na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaTablePage.title);
      await tester.tap(
        find.descendant(
          of: find.byType(GjaTable<String>),
          matching: find.text('Teclado'),
        ),
      );
      await tester.pump();
      expect(find.text('Aberto: Teclado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
