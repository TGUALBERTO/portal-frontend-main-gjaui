import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_primitives.dart';

void main() {
  test('Escalas tipográficas primitivas — Escalas em ordem', () {
    void expectScale(Map<String, double> scale, String prefix) {
      final values = scale.values.toList();
      for (final (i, MapEntry(key: name, value: value))
          in scale.entries.indexed) {
        expect(
          double.parse(name.substring(prefix.length)),
          value,
          reason: name,
        );
        if (i > 0) expect(value, greaterThan(values[i - 1]), reason: name);
      }
    }

    expectScale(GjaTypographyPrimitives.sizes, 'size');
    expectScale(GjaTypographyPrimitives.lineHeights, 'lineHeight');
    for (final value in GjaTypographyPrimitives.lineHeights.values) {
      expect(value % 4, 0, reason: '$value');
    }
    final weights = GjaTypographyPrimitives.weights.values.toList();
    expect(weights.map((w) => w.value), [400, 500, 600, 700]);
  });
}
