import 'package:flutter/material.dart' show Material, MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/design_tokens_page.dart';

void main() {
  testWidgets('Testes e documentação — Página na galeria', (tester) async {
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(DesignTokensPage.title));
    await tester.pumpAndSettle();

    for (final role in ['instant', 'short', 'medium', 'long']) {
      expect(find.text(role), findsOneWidget, reason: role);
    }
    expect(find.text('0 ms'), findsOneWidget);
    expect(find.text('200 ms'), findsOneWidget);
    expect(find.text('standard: ease-in-out'), findsOneWidget);
    expect(find.text('enter: ease-out'), findsOneWidget);
    expect(find.text('exit: ease-in'), findsOneWidget);
    expect(find.byType(MaterialApp), findsNothing);
    expect(find.byType(Material), findsNothing);
  });

  testWidgets('a página interpola entre fallback e o conjunto lento', (
    tester,
  ) async {
    await tester.pumpWidget(const GjaGalleryApp());
    await tester.tap(find.text(DesignTokensPage.title));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alternar conjunto (interpolação)'));
    await tester.pumpAndSettle();

    expect(find.text('400 ms'), findsOneWidget);
    expect(find.text('600 ms'), findsOneWidget);
  });
}
