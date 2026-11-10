import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_label_page.dart';
import 'package:gja_ui/gja_ui.dart';

GjaLabel _label(WidgetTester tester, Key key) =>
    tester.widget<GjaLabel>(find.byKey(key));

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaLabel na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 2000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await tester.tap(find.text(GjaLabelPage.title));
      await tester.pumpAndSettle();

      expect(
        _label(tester, GjaLabelPage.standardKey).design,
        GjaLabelDesign.standard,
      );
      expect(
        _label(tester, GjaLabelPage.boldKey).design,
        GjaLabelDesign.bold,
      );
      expect(_label(tester, GjaLabelPage.colonKey).showColon, isTrue);
      expect(_label(tester, GjaLabelPage.requiredKey).required, isTrue);
      final truncated = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byKey(GjaLabelPage.truncatedKey),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(truncated.didExceedMaxLines, isTrue);
    },
  );
}
