import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

void main() {
  test('Estados de interação — Conjunto de estados', () {
    expect(GjaInteractionState.values.map((s) => s.name), [
      'hovered',
      'focused',
      'pressed',
      'selected',
      'disabled',
    ]);
    expect(<GjaInteractionState>{}, isEmpty);
  });

  test('Estados de interação — Sem estado de arraste', () {
    expect(
      GjaInteractionState.values.map((s) => s.name),
      isNot(contains('dragged')),
    );
  });

  test('escalas primitivas de interação em ordem e nomeadas pelo valor', () {
    final opacities = GjaInteractionPrimitives.opacities.entries.toList();
    for (final (i, MapEntry(key: name, value: value)) in opacities.indexed) {
      final percent = int.parse(name.substring('opacity'.length));
      expect(value, closeTo(percent / 100, 1e-12), reason: name);
      expect(value, inInclusiveRange(0, 1), reason: name);
      if (i > 0) {
        expect(value, greaterThan(opacities[i - 1].value), reason: name);
      }
    }
    final strokes = GjaInteractionPrimitives.strokes.entries.toList();
    for (final (i, MapEntry(key: name, value: value)) in strokes.indexed) {
      expect(
        double.parse(name.substring('stroke'.length)),
        value,
        reason: name,
      );
      if (i > 0) expect(value, greaterThan(strokes[i - 1].value), reason: name);
    }
  });
}
