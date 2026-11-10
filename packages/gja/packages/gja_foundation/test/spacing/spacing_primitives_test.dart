import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_primitives.dart';

void main() {
  group('Escala primitiva de espaçamento', () {
    test('Escala primitiva de espaçamento — Grade de 4 pixels', () {
      final values = GjaSpacingPrimitives.values.values.toList();
      expect(
        values,
        containsAll(<double>[0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64]),
      );
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        expect(v == 2 || v % 4 == 0, isTrue, reason: '$v');
        if (i > 0) expect(v, greaterThan(values[i - 1]));
      }
    });

    test('Escala primitiva de espaçamento — Nome corresponde ao valor', () {
      for (final MapEntry(key: name, value: value)
          in GjaSpacingPrimitives.values.entries) {
        expect(
          double.parse(name.substring('space'.length)),
          value,
          reason: name,
        );
      }
      expect(GjaSpacingPrimitives.space16, 16);
    });
  });
}
