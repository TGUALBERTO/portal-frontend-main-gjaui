import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/accessibility_page.dart';

Future<void> _openPage(WidgetTester tester) async {
  await tester.pumpWidget(const GjaGalleryApp());
  await tester.tap(find.text(AccessibilityPage.title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Escala de texto — Conteúdo em 200%', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 1600);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _openPage(tester);

    expect(tester.takeException(), isNull);
    // Em 200% a amostra fica abaixo da área visível; o ListView é preguiçoso.
    await tester.scrollUntilVisible(find.text(AccessibilityPage.sample), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(AccessibilityPage.sample),
    );
    expect(paragraph.textScaler, const TextScaler.linear(2));
  });

  testWidgets('Testes e documentação da acessibilidade — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);

    await _openPage(tester);

    for (final line in AccessibilityPage.limits()) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    expect(find.textContaining('WCAG 2.2 AA'), findsOneWidget);
    for (final mode in ['full', 'basic']) {
      expect(
        find.text('$mode: short 100 ms · medium 200 ms · long 300 ms'),
        findsOneWidget,
        reason: mode,
      );
    }
    for (final mode in ['minimal', 'none']) {
      expect(
        find.text('$mode: short 0 ms · medium 0 ms · long 0 ms'),
        findsOneWidget,
        reason: mode,
      );
    }
  });
}
