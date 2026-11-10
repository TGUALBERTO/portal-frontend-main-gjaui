import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/states_page.dart';
import 'package:gja_ui/gja_ui.dart';

void main() {
  testWidgets('Testes e documentação dos estados — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(StatesPage.title));
    await tester.pumpAndSettle();

    const interaction = GjaInteractionStateTokens.fallback();
    for (final (mode, colors) in [
      ('claro', GjaColorTokens.light()),
      ('escuro', GjaColorTokens.dark()),
    ]) {
      for (final family in GjaControlFamily.values) {
        final expected = GjaControlColors.of(family, colors);
        for (final (label, states) in StatesPage.samples) {
          final reason = '$mode/${family.name}/$label';
          final ring = tester.widget<Container>(
            find.byKey(StatesPage.ringKey(mode, family, label)),
          );
          expect(ring.decoration != null, label == 'foco', reason: reason);
          final control = tester.widget<Container>(
            find.byKey(StatesPage.controlKey(mode, family, label)),
          );
          final box = control.decoration! as BoxDecoration;
          expect(
            box.color,
            expected.resolve(states).background,
            reason: reason,
          );
          final opacity = tester.widget<Opacity>(
            find.ancestor(
              of: find.byKey(StatesPage.controlKey(mode, family, label)),
              matching: find.byType(Opacity),
            ),
          );
          expect(opacity.opacity, interaction.opacity(states), reason: reason);
        }
      }
    }
    expect(GjaControlFamily.values.map((f) => f.name), [
      'standard',
      'emphasized',
      'transparent',
      'accept',
      'reject',
      'attention',
      'list',
    ]);
    for (final family in GjaControlFamily.values) {
      expect(find.text(family.name), findsNWidgets(2), reason: family.name);
    }
    for (final (label, _) in StatesPage.samples) {
      expect(
        find.text(label),
        findsNWidgets(2 * GjaControlFamily.values.length),
        reason: label,
      );
    }
  });
}
