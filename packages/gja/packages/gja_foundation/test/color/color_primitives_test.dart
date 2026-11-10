import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_primitives.dart';

void main() {
  group('Escalas primitivas de cor', () {
    test('Escalas primitivas de cor — Ordem de luminância', () {
      expect(
        GjaColorPrimitives.scales.keys,
        containsAll([
          'neutral',
          'blue',
          'green',
          'amber',
          'red',
          'cyan',
          'magenta',
        ]),
      );
      for (final MapEntry(key: hue, value: scale)
          in GjaColorPrimitives.scales.entries) {
        final names = scale.keys.toList();
        final positions = [
          for (final n in names) int.parse(n.substring(hue.length)),
        ];
        expect(positions, orderedEquals([...positions]..sort()), reason: hue);
        final luminances = [for (final c in scale.values) c.computeLuminance()];
        for (var i = 1; i < luminances.length; i++) {
          expect(
            luminances[i],
            lessThan(luminances[i - 1]),
            reason: '${names[i]} deve ser mais escura que ${names[i - 1]}',
          );
        }
      }
    });

    test('Escalas primitivas de cor — Escala magenta', () {
      final magenta = GjaColorPrimitives.scales['magenta']!;
      expect(magenta.keys.first, 'magenta50');
      expect(magenta.keys.last, 'magenta900');
      expect(magenta, hasLength(10));
    });

    test('Escalas primitivas de cor — Escalas fora da API dos widgets', () {
      final entry = File('lib/gja_foundation.dart').readAsStringSync();
      final primitives = File('lib/gja_primitives.dart').readAsStringSync();
      expect(entry, isNot(contains('primitives/')));
      expect(entry, isNot(contains("gja_primitives.dart'")));
      expect(
        primitives,
        contains("export 'src/color/primitives/color_primitives.dart';"),
      );
      expect(entry, contains("export 'src/color/color_tokens.dart';"));
      expect(entry, contains("export 'src/color/value_state.dart';"));
    });
  });
}
