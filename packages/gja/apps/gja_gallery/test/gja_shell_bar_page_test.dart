import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_shell_bar_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaShellBar na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaShellBarPage.title);

      for (final key in [
        GjaShellBarPage.fullKey,
        GjaShellBarPage.titleOnlyKey,
        GjaShellBarPage.narrowKey,
      ]) {
        expect(find.byKey(key), findsOneWidget);
      }
      final narrowSecond = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(GjaShellBarPage.narrowKey),
          matching: find.text('Pedidos de compra em aberto no período'),
        ),
      );
      expect(narrowSecond.didExceedMaxLines, isTrue);

      await tester.tap(
        find.descendant(
          of: find.byKey(GjaShellBarPage.fullKey),
          matching: find.byIcon(GjaIcons.menu2),
        ),
      );
      await tester.pump();
      expect(find.text(GjaShellBarPage.menuMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
