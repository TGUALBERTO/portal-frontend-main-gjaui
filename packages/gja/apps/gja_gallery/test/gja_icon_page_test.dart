import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_icon_page.dart';
import 'package:gja_ui/gja_ui.dart';

bool _mirrored(WidgetTester tester, Key key) => tester
    .widgetList<Transform>(
      find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
    )
    .any((t) => t.transform.storage[0] == -1);

void main() {
  testWidgets('[Documentação] Exemplos mínimos — Página GjaIcon na galeria', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(GjaIconPage.title));
    await tester.pumpAndSettle();

    for (final size in GjaIconSize.values) {
      expect(find.text(size.name), findsOneWidget, reason: size.name);
    }
    for (final tone in GjaIconTone.values) {
      expect(find.text(tone.name), findsOneWidget, reason: tone.name);
    }
    // O rótulo do ícone se junta ao do texto ao lado, no mesmo nó.
    final labeled = find.byWidgetPredicate(
      (w) => w is GjaIcon && w.semanticLabel == 'Aviso',
    );
    expect(tester.getSemantics(labeled).label, contains('Aviso'));
    expect(_mirrored(tester, GjaIconPage.ltrKey), isFalse);
    expect(_mirrored(tester, GjaIconPage.rtlKey), isTrue);
    handle.dispose();
  });
}
