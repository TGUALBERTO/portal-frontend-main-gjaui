import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

void main() {
  group('Cálculo de contraste', () {
    test('Cálculo de contraste — Extremos', () {
      expect(gjaContrastRatio(_black, _white), closeTo(21, 1e-9));
      expect(gjaContrastRatio(_white, _white), 1);
    });

    test('Cálculo de contraste — Simetria', () {
      const gray = Color(0xFF767676);
      expect(
        gjaContrastRatio(gray, _white),
        gjaContrastRatio(_white, gray),
      );
    });

    test('Cálculo de contraste — Cor translúcida', () {
      const translucent = Color(0x80000000);
      expect(
        () => gjaContrastRatio(translucent, _white),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('cor de fundo'),
          ),
        ),
      );
      expect(gjaContrastRatioOver(translucent, _white), greaterThan(1));
      expect(gjaContrastRatioOver(_black, _white), closeTo(21, 1e-9));
    });

    test('valor de referência: #767676 sobre branco ≈ 4,54', () {
      expect(
        gjaContrastRatio(const Color(0xFF767676), _white),
        closeTo(4.54, 0.01),
      );
    });
  });

  test('GjaValueState tem exatamente os cinco estados', () {
    expect(GjaValueState.values.map((s) => s.name), [
      'none',
      'success',
      'warning',
      'error',
      'information',
    ]);
  });
}
