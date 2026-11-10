import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/color_page.dart';

void main() {
  testWidgets('Testes e documentação das cores — Página na galeria', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(ColorPage.title));
    await tester.pumpAndSettle();

    for (final mode in ['Claro', 'Escuro']) {
      expect(find.text(mode), findsOneWidget);
      expect(find.text('$mode · brand'), findsOneWidget);
    }
    final ratio = RegExp(r' — \d+\.\d{2}:1$');
    for (final pair in ['text / base', 'error.foreground / base']) {
      final matches = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').startsWith('$pair —') &&
            ratio.hasMatch(w.data!),
      );
      expect(matches, findsNWidgets(2), reason: pair);
    }
    expect(find.byType(Material), findsNothing);
  });
}
