import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_avatar_page.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaAvatar na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaAvatarPage.title);
      expect(find.text(GjaAvatarPage.opened), findsNothing);

      await tester.tap(find.bySemanticsLabel(GjaAvatarPage.person));
      await tester.pumpAndSettle();
      expect(find.text(GjaAvatarPage.opened), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
