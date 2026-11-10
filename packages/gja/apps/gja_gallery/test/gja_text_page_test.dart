import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_text_page.dart';

RenderParagraph _paragraph(WidgetTester tester, Key key) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
    );

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaText na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(GjaTextPage.title));
    await tester.pumpAndSettle();

    final free = _paragraph(tester, GjaTextPage.freeKey);
    expect(free.maxLines, isNull);
    expect(free.didExceedMaxLines, isFalse);
    final truncated = _paragraph(tester, GjaTextPage.truncatedKey);
    expect(truncated.maxLines, 2);
    expect(truncated.didExceedMaxLines, isTrue);
    final noWrap = _paragraph(tester, GjaTextPage.noWrapKey);
    expect(noWrap.maxLines, 1);
    expect(noWrap.didExceedMaxLines, isTrue);
  });
}
