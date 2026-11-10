import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/theme_page.dart';
import 'package:gja_ui/gja_ui.dart';

Color _previewSurface(WidgetTester tester) {
  final preview = tester.widget<Container>(find.byKey(ThemePage.previewKey));
  return (preview.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('Testes e documentação do tema — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(ThemePage.title));
    await tester.pumpAndSettle();

    expect(_previewSurface(tester), GjaThemeData.light().colors.base);

    await tester.tap(find.text('Claro'));
    await tester.pump();
    expect(_previewSurface(tester), GjaThemeData.dark().colors.base);

    await tester.tap(find.text('Padrão'));
    await tester.pump();
    final issues = tester.widget<Text>(find.byKey(ThemePage.issuesKey));
    expect(issues.data, 'Problemas de acessibilidade: nenhum');

    for (final dark in [false, true]) {
      for (final compact in [false, true]) {
        final brand = ThemePage.themeFor(
          dark: dark,
          compact: compact,
          brand: true,
        );
        expect(
          brand.accessibilityIssues(),
          isEmpty,
          reason: 'dark=$dark compact=$compact',
        );
      }
    }
  });
}
