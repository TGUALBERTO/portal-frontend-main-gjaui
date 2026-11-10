import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

/// Conjunto com todos os campos diferentes do `fallback()`.
const _slow = GjaMotionTokens(
  instant: Duration.zero,
  short: Duration(milliseconds: 200),
  medium: Duration(milliseconds: 400),
  long: Duration(milliseconds: 600),
  standard: Curves.linear,
  enter: Curves.easeIn,
  exit: Curves.easeOut,
);

void main() {
  const fallback = GjaMotionTokens.fallback();

  test('cumpre o contrato de GjaTokenSet', () {
    expectTokenSetContract(
      a: fallback,
      // Instância não canônica, para testar a igualdade por valor.
      // ignore: prefer_const_constructors
      aCopy: GjaMotionTokens.fallback(),
      b: _slow,
    );
  });

  test('igualdade e copyWith consideram cada campo isoladamente', () {
    final variants = <String, GjaMotionTokens>{
      'short': fallback.copyWith(short: GjaMotionPrimitives.duration150),
      'medium': fallback.copyWith(medium: GjaMotionPrimitives.duration250),
      'long': fallback.copyWith(long: GjaMotionPrimitives.duration400),
      'standard': fallback.copyWith(standard: _slow.standard),
      'enter': fallback.copyWith(enter: _slow.enter),
      'exit': fallback.copyWith(exit: _slow.exit),
    };
    for (final MapEntry(key: field, value: variant) in variants.entries) {
      expect(variant, isNot(fallback), reason: field);
      expect(variant.lerp(fallback, 1), fallback, reason: field);
    }
  });

  group('Três níveis de tokens', () {
    test('Três níveis de tokens — Token semântico derivado de primitivo', () {
      expect(fallback.instant, GjaMotionPrimitives.duration0);
      expect(fallback.short, GjaMotionPrimitives.duration100);
      expect(fallback.medium, GjaMotionPrimitives.duration200);
      expect(fallback.long, GjaMotionPrimitives.duration300);
      expect(fallback.standard, same(GjaMotionPrimitives.curveEaseInOut));
      expect(fallback.enter, same(GjaMotionPrimitives.curveEaseOut));
      expect(fallback.exit, same(GjaMotionPrimitives.curveEaseIn));
    });
  });

  group('Conjuntos de tokens imutáveis', () {
    test('Conjuntos de tokens imutáveis — copyWith substitui um campo', () {
      final original = fallback;
      final changed = original.copyWith(
        medium: const Duration(milliseconds: 250),
      );
      expect(changed.medium, const Duration(milliseconds: 250));
      expect(
        changed,
        original.copyWith(medium: const Duration(milliseconds: 250)),
      );
      expect(changed.copyWith(medium: original.medium), original);
      expect(original.medium, GjaMotionPrimitives.duration200);
    });

    test('Conjuntos de tokens imutáveis — copyWith sem argumentos', () {
      expect(fallback.copyWith(), fallback);
      expect(_slow.copyWith(), _slow);
    });
  });

  group('Igualdade por valor', () {
    test('Igualdade por valor — Conjuntos com valores iguais', () {
      // ignore: prefer_const_constructors
      final a = GjaMotionTokens.fallback();
      // ignore: prefer_const_constructors
      final b = GjaMotionTokens.fallback();
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('Igualdade por valor — Conjuntos com um valor diferente', () {
      expect(
        fallback.copyWith(long: GjaMotionPrimitives.duration400),
        isNot(fallback),
      );
    });
  });

  group('Interpolação entre conjuntos', () {
    test('Interpolação entre conjuntos — Extremos da interpolação', () {
      expect(fallback.lerp(_slow, 0), fallback);
      expect(fallback.lerp(_slow, 1), _slow);
    });

    test('Interpolação entre conjuntos — Ponto médio de token contínuo', () {
      final a = fallback.copyWith(short: const Duration(milliseconds: 100));
      final b = fallback.copyWith(
        short: const Duration(milliseconds: 300),
        medium: const Duration(milliseconds: 300),
        long: const Duration(milliseconds: 300),
      );
      expect(a.lerp(b, 0.5).short, const Duration(milliseconds: 200));
    });

    test('Interpolação entre conjuntos — Token discreto', () {
      expect(fallback.lerp(_slow, 0.49).standard, fallback.standard);
      expect(fallback.lerp(_slow, 0.5).standard, _slow.standard);
    });

    test('Interpolação entre conjuntos — Interpolação com nulo', () {
      expect(fallback.lerp(null, 0.7), fallback);
    });
  });

  group('Tokens de movimento', () {
    test('Tokens de movimento — Ordem das durações', () {
      expect(fallback.instant, Duration.zero);
      expect(fallback.instant <= fallback.short, isTrue);
      expect(fallback.short <= fallback.medium, isTrue);
      expect(fallback.medium <= fallback.long, isTrue);
    });

    test('Tokens de movimento — Curvas CSS', () {
      expect(fallback.standard, const Cubic(0.42, 0, 0.58, 1));
      expect(fallback.enter, const Cubic(0, 0, 0.58, 1));
      expect(fallback.exit, const Cubic(0.42, 0, 1, 1));
    });

    test('Tokens de movimento — Sem curvas do Material', () {
      const material = [
        Cubic(0.4, 0, 0.2, 1),
        Cubic(0, 0, 0.2, 1),
        Cubic(0.4, 0, 1, 1),
      ];
      final curves = GjaMotionPrimitives.curves;
      for (final curve in curves.values) {
        expect(material, isNot(contains(curve)));
      }
      expect(curves.keys, ['curveEaseInOut', 'curveEaseOut', 'curveEaseIn']);
    });

    test('Tokens de movimento — mapeamento fora de ordem é rejeitado', () {
      expect(
        () => fallback.copyWith(short: GjaMotionPrimitives.duration500),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => fallback.copyWith(instant: GjaMotionPrimitives.duration50),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Nomenclatura dos tokens', () {
    test('Nomenclatura dos tokens — Primitivo identificado pela escala', () {
      final scale = GjaMotionPrimitives.durations;
      final positions = [
        for (final name in scale.keys)
          int.parse(RegExp(r'^duration(\d+)$').firstMatch(name)!.group(1)!),
      ];
      expect(positions, orderedEquals([...positions]..sort()));
      for (final MapEntry(key: name, value: value) in scale.entries) {
        expect(
          value.inMilliseconds,
          int.parse(name.substring('duration'.length)),
          reason: name,
        );
      }
    });
  });

  group('Inspeção dos tokens', () {
    test('Inspeção dos tokens — Propriedades no diagnóstico', () {
      final dump = fallback.toDiagnosticsNode().toStringDeep();
      for (final name in [
        'instant',
        'short',
        'medium',
        'long',
        'standard',
        'enter',
        'exit',
      ]) {
        expect(dump, contains('$name:'), reason: name);
      }
      expect(dump, contains('0:00:00.200000'));
    });
  });
}
