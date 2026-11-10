import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/interaction_page.dart';

void main() {
  testWidgets('Testes e documentação da interação — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(InteractionPage.title));
    await tester.pumpAndSettle();

    expect(find.text('Ativações: 0'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(InteractionPage.statesKey)).data,
      'estados: normal',
    );

    final target = find.byKey(InteractionPage.enabledKey);
    final gesture = await tester.startGesture(tester.getCenter(target));
    // Dentro de uma lista rolável o toque compete com o arrasto, e o
    // pressionado só é confirmado após kPressTimeout.
    await tester.pump(kPressTimeout + const Duration(milliseconds: 10));
    expect(
      tester.widget<Text>(find.byKey(InteractionPage.statesKey)).data,
      contains('pressed'),
    );
    await gesture.up();
    await tester.pump();

    expect(find.text('Ativações: 1'), findsOneWidget);
    expect(find.text('estados: disabled'), findsOneWidget);
  });
}
