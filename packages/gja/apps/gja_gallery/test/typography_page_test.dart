import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/typography_page.dart';

import 'support/inter_font.dart';

void main() {
  testWidgets('Testes e documentação da tipografia — Página na galeria', (
    tester,
  ) async {
    await tester.runAsync(loadInterFont);
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(TypographyPage.title));
    await tester.pumpAndSettle();

    const expected = {
      'header1': '48/60 · 700',
      'header2': '32/40 · 700',
      'header3': '24/32 · 700',
      'header4': '20/24 · 700',
      'header5': '16/20 · 700',
      'header6': '14/20 · 700',
      'large': '16/24 · 400',
      'base': '14/20 · 400',
      'baseSemibold': '14/20 · 600',
      'baseBold': '14/20 · 700',
      'small': '12/16 · 400',
    };
    for (final MapEntry(key: name, value: measures) in expected.entries) {
      expect(find.text('$name · $measures'), findsOneWidget, reason: name);
    }
    final samples = tester.widgetList<Text>(find.text(TypographyPage.sample));
    expect(samples, hasLength(11));
    for (final sample in samples) {
      expect(sample.style!.fontFamily, 'packages/gja_foundation/Inter');
    }
  });
}
