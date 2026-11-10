import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_hbox_vbox_page.dart';
import 'package:gja_ui/gja_ui.dart';

Future<void> _open(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1000, 2200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const GjaGalleryApp());
  await tester.tap(find.text(GjaHBoxVBoxPage.title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaHBox na galeria', (
    tester,
  ) async {
    await _open(tester);
    for (final alignment in GjaFlexJustifyContent.values) {
      final row = tester.widget<GjaHBox>(
        find.byKey(GjaHBoxVBoxPage.rowKey(alignment)),
      );
      expect(row.justifyContent, alignment);
    }
    expect(
      tester
          .widget<GjaHBox>(find.byKey(GjaHBoxVBoxPage.baselineKey))
          .alignItems,
      GjaFlexAlignItems.baseline,
    );
    expect(find.byKey(GjaHBoxVBoxPage.rowExpandedKey), findsOneWidget);
    // A linha com quebra ocupa mais de uma linha de blocos.
    final wrap = tester.getSize(find.byKey(GjaHBoxVBoxPage.wrapKey));
    final block = tester.getSize(find.byKey(GjaHBoxVBoxPage.rowExpandedKey));
    expect(wrap.height, greaterThan(block.height));
  });

  testWidgets('[Documentação] Exemplos mínimos — Página GjaVBox na galeria', (
    tester,
  ) async {
    await _open(tester);
    for (final alignment in GjaFlexAlignItems.values) {
      if (alignment == GjaFlexAlignItems.baseline) continue;
      final column = tester.widget<GjaVBox>(
        find.byKey(GjaHBoxVBoxPage.columnKey(alignment)),
      );
      expect(column.alignItems, alignment);
    }
    expect(find.byKey(GjaHBoxVBoxPage.columnExpandedKey), findsOneWidget);
  });
}
