import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';

const _light = GjaColorTokens.light();
const _dark = GjaColorTokens.dark();

void main() {
  group('Contraste mínimo dos papéis', () {
    test('Contraste mínimo dos papéis — Pares de texto', () {
      for (final tokens in [_light, _dark]) {
        final issues = gjaCheckContrast(
          tokens,
        ).where((i) => i.minimum == gjaTextContrastMinimum);
        expect(issues, isEmpty);
      }
      // Confere diretamente alguns pares, independentemente da lista.
      expect(
        gjaContrastRatio(_light.text, _light.selectionHoverBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        gjaContrastRatio(_dark.required, _dark.headerBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        gjaContrastRatio(_dark.contrastText, _dark.highlight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        gjaContrastRatio(_dark.brand, _dark.selectionBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        gjaContrastRatio(
          _light.warning.foreground,
          _light.warning.background,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        gjaContrastRatio(_dark.error.foreground, _dark.error.hoverBackground),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('Contraste mínimo dos papéis — Pares não textuais', () {
      for (final tokens in [_light, _dark]) {
        final issues = gjaCheckContrast(
          tokens,
        ).where((i) => i.minimum == gjaNonTextContrastMinimum);
        expect(issues, isEmpty);
      }
      expect(
        gjaContrastRatio(_dark.focus, _dark.headerBackground),
        greaterThanOrEqualTo(3),
      );
    });

    test(
      'Contraste mínimo dos papéis — Personalização que viola o contraste',
      () {
        // Cinza escolhido para ter ≈ 2:1 sobre branco.
        final custom = _light.copyWith(
          base: const Color(0xFFFFFFFF),
          text: const Color(0xFFAAAAAA),
        );
        final issue = gjaCheckContrast(
          custom,
        ).singleWhere((i) => i.foreground == 'text' && i.background == 'base');
        expect(issue.ratio, closeTo(2.32, 0.05));
        expect(issue.minimum, gjaTextContrastMinimum);
      },
    );

    test('Contraste mínimo dos papéis — Papéis isentos', () {
      final custom = _light.copyWith(separator: _light.base);
      expect(gjaCheckContrast(custom), isEmpty);
    });
  });
}
