import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

const _fallback = GjaIconTokens.fallback();

void main() {
  group('Passos e papéis de tamanho de ícone', () {
    test('Passos e papéis de tamanho de ícone — Mapeamento de referência', () {
      final steps = [
        _fallback.small,
        _fallback.medium,
        _fallback.large,
        _fallback.xLarge,
      ];
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i], greaterThan(steps[i - 1]));
      }
      expect(steps, contains(_fallback.inline));
      expect(steps, contains(_fallback.control));
      expect(_fallback.control, 16);
      final primitives = GjaIconPrimitives.sizes.values.toSet();
      for (final MapEntry(key: name, value: value)
          in _fallback.values.entries) {
        expect(primitives, contains(value), reason: name);
      }
    });

    test(
      'Passos e papéis de tamanho de ícone — Tamanho inválido rejeitado',
      () {
        for (final value in [0.0, -4.0, double.infinity]) {
          expect(
            () => _fallback.copyWith(control: value),
            throwsA(
              isA<AssertionError>().having(
                (e) => e.message,
                'message',
                contains('"control"'),
              ),
            ),
            reason: '$value',
          );
        }
      },
    );
  });

  group('Contrato do conjunto de tamanhos de ícone', () {
    test('Contrato do conjunto de tamanhos de ícone — Contrato verificado', () {
      final bigger = GjaIconTokens(
        small: _fallback.small + 4,
        medium: _fallback.medium + 4,
        large: _fallback.large + 4,
        xLarge: _fallback.xLarge + 4,
        inline: _fallback.inline + 4,
        control: _fallback.control + 4,
      );
      expectTokenSetContract(
        a: _fallback,
        // Instância não canônica, para testar a igualdade por valor.
        // ignore: prefer_const_constructors
        aCopy: GjaIconTokens.fallback(),
        b: bigger,
      );
      expect(_fallback.lerp(bigger, 0.5).control, _fallback.control + 2);
    });

    test('igualdade e copyWith consideram cada campo isoladamente', () {
      final variants = [
        _fallback.copyWith(small: 17),
        _fallback.copyWith(medium: 21),
        _fallback.copyWith(large: 25),
        _fallback.copyWith(xLarge: 33),
        _fallback.copyWith(inline: 17),
        _fallback.copyWith(control: 21),
      ];
      for (final (i, variant) in variants.indexed) {
        expect(variant, isNot(_fallback), reason: 'campo $i');
        expect(variant.lerp(_fallback, 1), _fallback, reason: 'campo $i');
      }
    });

    test('diagnóstico lista cada passo e papel', () {
      final dump = _fallback.toDiagnosticsNode().toStringDeep();
      for (final name in _fallback.values.keys) {
        expect(dump, contains('$name:'), reason: name);
      }
    });
  });
}
