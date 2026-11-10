import 'dart:ui' show RRect, Radius, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

const _fallback = GjaRadiusTokens.fallback();

List<double> _steps(GjaRadiusTokens t) => [
  t.none,
  t.xs,
  t.s,
  t.m,
  t.l,
  t.xl,
  t.full,
];

void main() {
  test('Escala primitiva de raios — Escala em ordem', () {
    final entries = GjaRadiusPrimitives.values.entries.toList();
    for (final (i, MapEntry(key: name, value: value)) in entries.indexed) {
      expect(
        double.parse(name.substring('radius'.length)),
        value,
        reason: name,
      );
      if (i > 0) expect(value, greaterThan(entries[i - 1].value), reason: name);
    }
    expect(
      GjaRadiusPrimitives.values.values,
      containsAll(<double>[0, 2, 4, 6, 8, 12, 16]),
    );
  });

  group('Formato de pílula', () {
    test('Formato de pílula — Pílula em um controle', () {
      final rrect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 120, 32),
        Radius.circular(_fallback.full),
      ).scaleRadii();
      for (final corner in [
        rrect.tlRadius,
        rrect.trRadius,
        rrect.blRadius,
        rrect.brRadius,
      ]) {
        expect(corner.x, closeTo(16, 1e-9));
        expect(corner.y, closeTo(16, 1e-9));
      }
    });

    test('Formato de pílula — Valor finito', () {
      for (final value in [_fallback.full, GjaRadiusPrimitives.radiusFull]) {
        expect(value.isFinite, isTrue);
        expect(value, greaterThanOrEqualTo(2048));
      }
    });
  });

  group('Passos e papéis semânticos de raio', () {
    test('Passos e papéis semânticos de raio — Ordem dos passos', () {
      final steps = _steps(_fallback);
      expect(_fallback.none, 0);
      for (var i = 1; i < steps.length; i++) {
        expect(
          steps[i],
          greaterThanOrEqualTo(steps[i - 1]),
          reason: 'passo $i',
        );
      }
    });

    test('Passos e papéis semânticos de raio — Papéis apontam para passos', () {
      final steps = _steps(_fallback).toSet();
      for (final role in [
        _fallback.button,
        _fallback.field,
        _fallback.popover,
        _fallback.element,
        _fallback.tile,
      ]) {
        expect(steps, contains(role));
      }
    });

    test('Passos e papéis semânticos de raio — Papéis do Fiori', () {
      expect(_fallback.button, 8);
      expect(_fallback.field, 4);
      expect(_fallback.popover, 8);
      expect(_fallback.element, 12);
      expect(_fallback.tile, 16);
      expect(_fallback.values.keys, isNot(contains('control')));
      expect(_fallback.values.keys, isNot(contains('container')));
    });

    test('Passos e papéis semânticos de raio — Valor negativo rejeitado', () {
      expect(
        () => _fallback.copyWith(button: -1),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('"button"'),
          ),
        ),
      );
      expect(
        () => _fallback.copyWith(full: double.infinity),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Contrato do conjunto de raios', () {
    test('Contrato do conjunto de raios — Contrato verificado', () {
      final doubled = _fallback.copyWith(
        xs: _fallback.xs * 2,
        s: _fallback.s * 2,
        m: _fallback.m * 2,
        l: _fallback.l * 2,
        xl: _fallback.xl * 2,
        button: _fallback.button * 2,
        field: _fallback.field * 2,
        popover: _fallback.popover * 2,
        element: _fallback.element * 2,
        tile: _fallback.tile * 2,
      );
      expectTokenSetContract(
        a: _fallback,
        // Instância não canônica, para testar a igualdade por valor.
        // ignore: prefer_const_constructors
        aCopy: GjaRadiusTokens.fallback(),
        b: doubled,
      );
    });

    test('Contrato do conjunto de raios — Interpolação de um papel', () {
      final a = _fallback.copyWith(button: 4);
      final b = _fallback.copyWith(button: 8);
      expect(a.lerp(b, 0.5).button, 6);
    });

    test('Contrato do conjunto de raios — Valores vêm dos primitivos', () {
      final primitives = {
        ...GjaRadiusPrimitives.values.values,
        GjaRadiusPrimitives.radiusFull,
      };
      for (final MapEntry(key: name, value: value)
          in _fallback.values.entries) {
        expect(primitives, contains(value), reason: name);
      }
    });

    test('igualdade e copyWith consideram cada campo isoladamente', () {
      final variants = [
        _fallback.copyWith(none: 1),
        _fallback.copyWith(xs: 3),
        _fallback.copyWith(s: 5),
        _fallback.copyWith(m: 9),
        _fallback.copyWith(l: 13),
        _fallback.copyWith(xl: 17),
        _fallback.copyWith(full: 5000),
        _fallback.copyWith(button: 5),
        _fallback.copyWith(field: 5),
        _fallback.copyWith(popover: 5),
        _fallback.copyWith(element: 5),
        _fallback.copyWith(tile: 5),
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
