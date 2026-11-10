import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/spacing_page.dart';

void main() {
  testWidgets('Testes e documentação dos espaçamentos — Página na galeria', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(SpacingPage.title));
    await tester.pumpAndSettle();

    final expected = <String, String>{
      'xxs': '2 px',
      'xs': '4 px',
      's': '8 px',
      'm': '12 px',
      'l': '16 px',
      'xl': '24 px',
      'xxl': '32 px',
      'xxxl': '48 px',
      'inlineGap': '8 px',
      'stackGap': '12 px',
      'sectionGap': '32 px',
      'pageMargin': '16 px',
      'margem S': '16 px',
      'margem M': '32 px',
      'margem L': '32 px',
      'margem XL': '48 px',
    };
    for (final MapEntry(key: name, value: value) in expected.entries) {
      final row = find.ancestor(
        of: find.text(name),
        matching: find.byType(Row),
      );
      expect(row, findsOneWidget, reason: name);
      expect(
        find.descendant(of: row, matching: find.text(value)),
        findsOneWidget,
        reason: name,
      );
    }
  });
}
