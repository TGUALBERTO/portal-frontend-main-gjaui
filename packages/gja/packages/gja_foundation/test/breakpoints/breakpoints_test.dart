import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

const _fallback = GjaBreakpointTokens.fallback();
const _custom = GjaBreakpointTokens(
  medium: 480,
  large: 960,
  extraLarge: 1280,
);

void main() {
  test('Escala primitiva de larguras — Escala em ordem', () {
    final entries = GjaBreakpointPrimitives.values.entries.toList();
    for (final (i, MapEntry(key: name, value: value)) in entries.indexed) {
      expect(double.parse(name.substring('width'.length)), value, reason: name);
      if (i > 0) expect(value, greaterThan(entries[i - 1].value), reason: name);
    }
    expect(GjaBreakpointPrimitives.values.values, <double>[600, 1024, 1440]);
  });

  test('Escala primitiva de larguras — Faixas do SAPUI5', () {
    expect(GjaBreakpointPrimitives.values.values, [600, 1024, 1440]);
    for (final other in [360.0, 840.0, 1280.0, 1920.0]) {
      expect(GjaBreakpointPrimitives.values.values, isNot(contains(other)));
    }
  });

  test('Classes de tamanho — Comparação de classes', () {
    expect(GjaSizeClass.values, [
      GjaSizeClass.small,
      GjaSizeClass.medium,
      GjaSizeClass.large,
      GjaSizeClass.extraLarge,
    ]);
    expect(GjaSizeClass.large.isAtLeast(GjaSizeClass.medium), isTrue);
    expect(GjaSizeClass.small.isAtLeast(GjaSizeClass.medium), isFalse);
    expect(GjaSizeClass.small.isAtMost(GjaSizeClass.medium), isTrue);
    expect(GjaSizeClass.extraLarge.isAtMost(GjaSizeClass.large), isFalse);
    for (final c in GjaSizeClass.values) {
      expect(c.isAtLeast(c), isTrue, reason: c.name);
      expect(c.isAtMost(c), isTrue, reason: c.name);
    }
  });

  group('Limiares semânticos', () {
    test('Limiares semânticos — Mapeamento de referência', () {
      expect(_fallback.medium, 600);
      expect(_fallback.large, 1024);
      expect(_fallback.extraLarge, 1440);
      final primitives = GjaBreakpointPrimitives.values.values.toSet();
      for (final v in [
        _fallback.medium,
        _fallback.large,
        _fallback.extraLarge,
      ]) {
        expect(primitives, contains(v));
      }
    });

    test('Limiares semânticos — Limiares fora de ordem rejeitados', () {
      expect(
        () => _fallback.copyWith(large: 600),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            allOf(contains('medium < large < extraLarge'), contains('600')),
          ),
        ),
      );
      expect(
        () => _fallback.copyWith(medium: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _fallback.copyWith(extraLarge: double.infinity),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Classificação de uma largura', () {
    test('Classificação de uma largura — Larguras nas bordas', () {
      const cases = <(double, GjaSizeClass)>[
        (0.0, GjaSizeClass.small),
        (599.9, GjaSizeClass.small),
        (600.0, GjaSizeClass.medium),
        (1023.9, GjaSizeClass.medium),
        (1024.0, GjaSizeClass.large),
        (1439.9, GjaSizeClass.large),
        (1440.0, GjaSizeClass.extraLarge),
        (4000.0, GjaSizeClass.extraLarge),
      ];
      for (final (width, expected) in cases) {
        expect(_fallback.classify(width), expected, reason: '$width');
      }
    });

    test('Classificação de uma largura — Largura sem limite', () {
      expect(_fallback.classify(double.infinity), GjaSizeClass.extraLarge);
    });

    test('Classificação de uma largura — Largura inválida', () {
      for (final width in [-1.0, double.nan]) {
        expect(
          () => _fallback.classify(width),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'width')),
          reason: '$width',
        );
      }
      expect(
        () => _fallback.classify(-1),
        throwsA(
          isA<ArgumentError>().having((e) => e.invalidValue, 'valor', -1),
        ),
      );
    });

    test('Classificação de uma largura — Limiares personalizados', () {
      expect(_custom.classify(500), GjaSizeClass.medium);
      expect(_fallback.classify(500), GjaSizeClass.small);
    });

    test('minWidthOf retorna o limiar de cada classe', () {
      expect(_fallback.minWidthOf(GjaSizeClass.small), 0);
      expect(_fallback.minWidthOf(GjaSizeClass.medium), 600);
      expect(_fallback.minWidthOf(GjaSizeClass.large), 1024);
      expect(_fallback.minWidthOf(GjaSizeClass.extraLarge), 1440);
      for (final c in GjaSizeClass.values) {
        expect(_fallback.classify(_fallback.minWidthOf(c)), c, reason: c.name);
      }
    });
  });

  group('Contrato do conjunto de breakpoints', () {
    test('Contrato do conjunto de breakpoints — Contrato verificado', () {
      expectTokenSetContract(
        a: _fallback,
        // Instância não canônica, para testar a igualdade por valor.
        // ignore: prefer_const_constructors
        aCopy: GjaBreakpointTokens.fallback(),
        b: _custom,
      );
      final mid = _fallback.lerp(_custom, 0.5);
      expect(mid.medium < mid.large && mid.large < mid.extraLarge, isTrue);
    });

    test('Contrato do conjunto de breakpoints — Interpolação de limiar', () {
      final b = _fallback.copyWith(large: 960);
      expect(_fallback.lerp(b, 0.5).large, 992);
    });

    test('igualdade e copyWith consideram cada limiar isoladamente', () {
      final variants = [
        _fallback.copyWith(medium: 640),
        _fallback.copyWith(large: 1100),
        _fallback.copyWith(extraLarge: 1600),
      ];
      for (final (i, variant) in variants.indexed) {
        expect(variant, isNot(_fallback), reason: 'limiar $i');
        expect(variant.lerp(_fallback, 1), _fallback, reason: 'limiar $i');
      }
    });

    test('diagnóstico lista cada limiar', () {
      final dump = _fallback.toDiagnosticsNode().toStringDeep();
      for (final name in ['medium', 'large', 'extraLarge']) {
        expect(dump, contains('$name:'), reason: name);
      }
    });
  });
}
