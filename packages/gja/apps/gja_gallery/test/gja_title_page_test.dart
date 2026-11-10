import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_title_page.dart';
import 'package:gja_ui/gja_ui.dart';

RenderParagraph _paragraph(WidgetTester tester, Key key) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
    );

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaTitle na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 2000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await tester.tap(find.text(GjaTitlePage.title));
      await tester.pumpAndSettle();

      for (final style in GjaTitleLevel.values) {
        final label = GjaTitlePage.styleLabel(style);
        expect(
          tester
              .widget<GjaTitle>(find.widgetWithText(GjaTitle, label))
              .titleStyle,
          style,
          reason: label,
        );
      }
      final level = tester.widget<GjaTitle>(
        find.byKey(GjaTitlePage.levelKey),
      );
      expect(level.level, GjaTitleLevel.h1);
      expect(level.titleStyle, GjaTitleLevel.h5);
      expect(
        _paragraph(tester, GjaTitlePage.truncatedKey).didExceedMaxLines,
        isTrue,
      );
      final wrapping = _paragraph(tester, GjaTitlePage.wrappingKey);
      expect(wrapping.didExceedMaxLines, isFalse);
      expect(
        wrapping.size.height,
        greaterThan(
          _paragraph(tester, GjaTitlePage.truncatedKey).size.height,
        ),
      );
    },
  );
}
