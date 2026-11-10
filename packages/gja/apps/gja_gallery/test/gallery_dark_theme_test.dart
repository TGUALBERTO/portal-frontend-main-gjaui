import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gallery_comparison.dart';

/// Se [element] está dentro de um painel que compara modos ou densidades de
/// propósito ([GalleryComparison]).
bool _inComparison(Element element) {
  var found = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is GalleryComparison) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Páginas da galeria no tema escuro',
    (tester) async {
      const screen = Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screen;
      addTearDown(tester.view.reset);
      final dark = GjaThemeData.dark();
      final darkSurfaces = {
        dark.colors.background,
        dark.colors.base,
        dark.colors.headerBackground,
      };
      final darkTexts = {dark.colors.text, dark.colors.label};

      await tester.pumpWidget(const GjaGalleryApp());
      await tester.tap(find.text('Tema: escuro'));
      await tester.pumpAndSettle();

      final failures = <String>[];
      for (final page in galleryPages) {
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pushNamed(page.route);
        // Algumas páginas têm animações contínuas: avança só a transição.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final onPage = find.descendant(
          of: find.byType(Navigator),
          matching: find.byType(ColoredBox),
        );
        for (final element in onPage.evaluate()) {
          if (_inComparison(element)) continue;
          final box = element.renderObject;
          if (box is! RenderBox || !box.hasSize) continue;
          // Só as superfícies de página (quase a tela inteira) contam.
          final area = box.size.width * box.size.height;
          if (area < screen.width * screen.height * 0.8) continue;
          final color = (element.widget as ColoredBox).color;
          if (!darkSurfaces.contains(color)) {
            failures.add('${page.title}: fundo $color');
          }
        }
        final styles = find.descendant(
          of: find.byType(Navigator),
          matching: find.byType(DefaultTextStyle),
        );
        for (final element in styles.evaluate()) {
          if (_inComparison(element)) continue;
          final color = (element.widget as DefaultTextStyle).style.color;
          if (color != null && !darkTexts.contains(color)) {
            failures.add('${page.title}: texto $color');
          }
        }

        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      expect(failures, isEmpty);
    },
  );
}
