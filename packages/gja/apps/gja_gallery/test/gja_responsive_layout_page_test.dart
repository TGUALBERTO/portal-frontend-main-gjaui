import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_responsive_layout_page.dart';

Finder _inside(Key key, String text) =>
    find.descendant(of: find.byKey(key), matching: find.text(text));

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaResponsiveLayout na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await tester.tap(find.text(GjaResponsiveLayoutPage.title));
      await tester.pumpAndSettle();

      const screen = GjaResponsiveLayoutPage.screenKey;
      const container = GjaResponsiveLayoutPage.containerKey;
      expect(_inside(screen, GjaResponsiveLayoutPage.twoColumns), findsOne);
      // O painel de 400 continua em uma coluna mesmo em tela larga.
      expect(_inside(container, GjaResponsiveLayoutPage.oneColumn), findsOne);

      tester.view.physicalSize = const Size(500, 1600);
      await tester.pumpAndSettle();
      expect(_inside(screen, GjaResponsiveLayoutPage.oneColumn), findsOne);
      expect(tester.takeException(), isNull);
    },
  );
}
