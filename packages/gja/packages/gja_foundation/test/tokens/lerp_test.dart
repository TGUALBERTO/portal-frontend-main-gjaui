import 'package:flutter_test/flutter_test.dart';
// Helper interno, testado diretamente por não ser exportado.
// ignore: implementation_imports
import 'package:gja_foundation/src/tokens/lerp.dart';

void main() {
  group('lerpDurationValue', () {
    const a = Duration(milliseconds: 100);
    const b = Duration(milliseconds: 300);

    test('extremos retornam as durações de origem e destino', () {
      expect(lerpDurationValue(a, b, 0), a);
      expect(lerpDurationValue(a, b, 1), b);
    });

    test('ponto médio de 100 ms a 300 ms é 200 ms', () {
      expect(lerpDurationValue(a, b, 0.5), const Duration(milliseconds: 200));
    });

    test('arredonda para o microssegundo mais próximo', () {
      expect(
        lerpDurationValue(Duration.zero, const Duration(microseconds: 3), 0.5),
        const Duration(microseconds: 2),
      );
    });
  });

  group('lerpDiscrete', () {
    test('troca em t = 0.5', () {
      expect(lerpDiscrete('a', 'b', 0.49), 'a');
      expect(lerpDiscrete('a', 'b', 0.5), 'b');
    });
  });
}
