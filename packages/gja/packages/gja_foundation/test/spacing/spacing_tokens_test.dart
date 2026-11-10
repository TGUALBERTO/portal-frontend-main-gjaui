import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

const _fallback = GjaSpacingTokens.fallback();

List<double> _steps(GjaSpacingTokens t) => [
  t.none,
  t.xxs,
  t.xs,
  t.s,
  t.m,
  t.l,
  t.xl,
  t.xxl,
  t.xxxl,
];

Map<String, double> _layout(GjaSpacingTokens t) => {
  'inlineGap': t.inlineGap,
  'stackGap': t.stackGap,
  'sectionGap': t.sectionGap,
  'pageMargin': t.pageMargin,
};

GjaSpacingTokens _doubled(GjaSpacingTokens t) => GjaSpacingTokens(
  none: t.none * 2,
  xxs: t.xxs * 2,
  xs: t.xs * 2,
  s: t.s * 2,
  m: t.m * 2,
  l: t.l * 2,
  xl: t.xl * 2,
  xxl: t.xxl * 2,
  xxxl: t.xxxl * 2,
  inlineGap: t.inlineGap * 2,
  stackGap: t.stackGap * 2,
  sectionGap: t.sectionGap * 2,
  pageMargin: t.pageMargin * 2,
  pageMarginMedium: t.pageMarginMedium * 2,
  pageMarginLarge: t.pageMarginLarge * 2,
  pageMarginExtraLarge: t.pageMarginExtraLarge * 2,
);

void main() {
  group('Passos semânticos de espaçamento', () {
    test('Passos semânticos de espaçamento — Ordem dos passos', () {
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

    test('Passos semânticos de espaçamento — Valor negativo rejeitado', () {
      expect(
        () => _fallback.copyWith(m: -4),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('"m"'),
          ),
        ),
      );
      expect(
        () => _fallback.copyWith(pageMargin: double.infinity),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Papéis de layout', () {
    test('Papéis de layout — Papéis apontam para passos', () {
      final steps = _steps(_fallback).toSet();
      for (final MapEntry(key: role, value: value) in _layout(
        _fallback,
      ).entries) {
        expect(steps, contains(value), reason: role);
      }
    });

    test('Papéis de layout — Hierarquia dos papéis', () {
      expect(_fallback.inlineGap, lessThanOrEqualTo(_fallback.stackGap));
      expect(_fallback.stackGap, lessThanOrEqualTo(_fallback.sectionGap));
    });

    test('Papéis de layout — Margem de página por classe de tamanho', () {
      expect(
        [for (final c in GjaSizeClass.values) _fallback.pageMarginFor(c)],
        [16, 32, 32, 48],
      );
      expect(
        _fallback.pageMarginFor(GjaSizeClass.small),
        _fallback.pageMargin,
      );
      final steps = _steps(_fallback).toSet();
      for (final c in GjaSizeClass.values) {
        expect(steps, contains(_fallback.pageMarginFor(c)), reason: c.name);
      }
    });
  });

  test('Classes de margem do Fiori — Passos e classes de margem', () {
    expect(
      [_fallback.s, _fallback.l, _fallback.xxl, _fallback.xxxl],
      [8, 16, 32, 48],
    );
  });

  group('Contrato do conjunto de espaçamento', () {
    test('Contrato do conjunto de espaçamento — Contrato verificado', () {
      expectTokenSetContract(
        a: _fallback,
        // Instância não canônica, para testar a igualdade por valor.
        // ignore: prefer_const_constructors
        aCopy: GjaSpacingTokens.fallback(),
        b: _doubled(_fallback),
      );
    });

    test('Contrato do conjunto de espaçamento — Interpolação de um passo', () {
      final a = _fallback.copyWith(m: 12);
      final b = _fallback.copyWith(m: 20);
      expect(a.lerp(b, 0.5).m, 16);
    });

    test(
      'Contrato do conjunto de espaçamento — Valores vêm dos primitivos',
      () {
        final primitives = GjaSpacingPrimitives.values.values.toSet();
        for (final value in [
          ..._steps(_fallback),
          ..._layout(_fallback).values,
        ]) {
          expect(primitives, contains(value));
        }
      },
    );

    test('igualdade e copyWith consideram cada campo isoladamente', () {
      final variants = [
        _fallback.copyWith(none: 1),
        _fallback.copyWith(xxs: 3),
        _fallback.copyWith(xs: 5),
        _fallback.copyWith(s: 9),
        _fallback.copyWith(m: 13),
        _fallback.copyWith(l: 17),
        _fallback.copyWith(xl: 25),
        _fallback.copyWith(xxl: 33),
        _fallback.copyWith(xxxl: 49),
        _fallback.copyWith(inlineGap: 9),
        _fallback.copyWith(stackGap: 13),
        _fallback.copyWith(sectionGap: 33),
        _fallback.copyWith(pageMargin: 17),
        _fallback.copyWith(pageMarginMedium: 33),
        _fallback.copyWith(pageMarginLarge: 33),
        _fallback.copyWith(pageMarginExtraLarge: 49),
      ];
      for (final (i, variant) in variants.indexed) {
        expect(variant, isNot(_fallback), reason: 'campo $i');
        expect(variant.lerp(_fallback, 1), _fallback, reason: 'campo $i');
      }
    });

    test('diagnóstico lista cada passo e papel', () {
      final dump = _fallback.toDiagnosticsNode().toStringDeep();
      for (final name in [
        'none',
        'xxs',
        'xs',
        's',
        'm',
        'l',
        'xl',
        'xxl',
        'xxxl',
        ..._layout(_fallback).keys,
      ]) {
        expect(dump, contains('$name:'), reason: name);
      }
    });
  });
}
