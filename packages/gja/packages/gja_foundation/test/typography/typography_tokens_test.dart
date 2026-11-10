import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

const _fallback = GjaTypographyTokens.fallback();

/// Altura de linha em pixels lógicos (tamanho × altura relativa).
double _lineHeightPx(TextStyle s) => s.fontSize! * s.height!;

GjaTypographyTokens _bigger(GjaTypographyTokens t) => GjaTypographyTokens(
  header1: t.header1.copyWith(fontSize: t.header1.fontSize! + 4),
  header2: t.header2.copyWith(fontSize: t.header2.fontSize! + 4),
  header3: t.header3.copyWith(fontSize: t.header3.fontSize! + 4),
  header4: t.header4.copyWith(fontSize: t.header4.fontSize! + 4),
  header5: t.header5.copyWith(fontSize: t.header5.fontSize! + 4),
  header6: t.header6.copyWith(fontSize: t.header6.fontSize! + 4),
  large: t.large.copyWith(fontSize: t.large.fontSize! + 4),
  base: t.base.copyWith(fontSize: t.base.fontSize! + 4),
  baseSemibold: t.baseSemibold.copyWith(fontSize: t.baseSemibold.fontSize! + 4),
  baseBold: t.baseBold.copyWith(fontSize: t.baseBold.fontSize! + 4),
  small: t.small.copyWith(fontSize: t.small.fontSize! + 4),
);

void main() {
  test('Fontes de fallback do sistema — Fallback sem prefixo de pacote', () {
    for (final MapEntry(key: name, value: style) in _fallback.styles.entries) {
      expect(style.fontFamily, 'packages/gja_foundation/Inter', reason: name);
      expect(style.fontFamilyFallback, isNotEmpty, reason: name);
      for (final family in style.fontFamilyFallback!) {
        expect(
          family,
          isNot(startsWith('packages/')),
          reason: '$name: $family',
        );
      }
    }
  });

  group('Estilos semânticos de texto', () {
    test('Estilos semânticos de texto — Estilo completo e sem cor', () {
      expect(_fallback.styles.keys, [
        'header1',
        'header2',
        'header3',
        'header4',
        'header5',
        'header6',
        'large',
        'base',
        'baseSemibold',
        'baseBold',
        'small',
      ]);
      for (final MapEntry(key: name, value: s) in _fallback.styles.entries) {
        expect(s.fontFamily, isNotNull, reason: name);
        expect(s.fontFamilyFallback, isNotNull, reason: name);
        expect(s.fontSize, isNotNull, reason: name);
        expect(s.height, isNotNull, reason: name);
        expect(s.fontWeight, isNotNull, reason: name);
        expect(s.color, isNull, reason: name);
        expect(s.backgroundColor, isNull, reason: name);
        expect(s.foreground, isNull, reason: name);
        expect(s.background, isNull, reason: name);
      }
    });

    test('Estilos semânticos de texto — Hierarquia de tamanhos', () {
      final t = _fallback;
      final headers = [t.header1, t.header2, t.header3, t.header4, t.header5];
      for (var i = 1; i < headers.length; i++) {
        expect(headers[i].fontSize, lessThan(headers[i - 1].fontSize!));
      }
      expect(t.header6.fontSize, lessThan(t.header5.fontSize!));
      expect(t.header6.fontSize, greaterThanOrEqualTo(t.small.fontSize!));
      expect(t.large.fontSize, greaterThan(t.base.fontSize!));
      expect(t.base.fontSize, greaterThan(t.small.fontSize!));
    });

    test('Estilos semânticos de texto — Pesos do texto base', () {
      final t = _fallback;
      for (final s in [t.baseSemibold, t.baseBold]) {
        expect(s.fontSize, t.base.fontSize);
        expect(s.height, t.base.height);
      }
      expect([t.base, t.baseSemibold, t.baseBold].map((s) => s.fontWeight), [
        FontWeight.w400,
        FontWeight.w600,
        FontWeight.w700,
      ]);
    });

    test('Estilos semânticos de texto — Sem nomes do Material', () {
      const material = [
        'display',
        'headline',
        'title',
        'subtitle',
        'body',
        'label',
        'caption',
      ];
      for (final name in _fallback.styles.keys) {
        expect(material, isNot(contains(name)), reason: name);
      }
    });

    test('títulos são negritos e o texto é regular', () {
      final t = _fallback;
      for (final s in [
        t.header1,
        t.header2,
        t.header3,
        t.header4,
        t.header5,
        t.header6,
      ]) {
        expect(s.fontWeight, FontWeight.w700);
      }
      for (final s in [t.large, t.base, t.small]) {
        expect(s.fontWeight, FontWeight.w400);
      }
    });
  });

  group('Ritmo vertical e legibilidade', () {
    test('Ritmo vertical e legibilidade — Altura de linha na grade', () {
      for (final MapEntry(key: name, value: s) in _fallback.styles.entries) {
        final px = _lineHeightPx(s);
        expect(
          (px / 4 - (px / 4).round()).abs(),
          lessThan(1e-9),
          reason: '$name: $px',
        );
        expect(
          px,
          greaterThanOrEqualTo(1.2 * s.fontSize! - 1e-9),
          reason: name,
        );
        expect(
          s.leadingDistribution,
          TextLeadingDistribution.even,
          reason: name,
        );
      }
    });

    test('Ritmo vertical e legibilidade — Tamanho mínimo', () {
      for (final MapEntry(key: name, value: s) in _fallback.styles.entries) {
        expect(s.fontSize, greaterThanOrEqualTo(12), reason: name);
      }
    });
  });

  group('Contrato do conjunto tipográfico', () {
    test('Contrato do conjunto tipográfico — Contrato verificado', () {
      expectTokenSetContract(
        a: _fallback,
        // Instância não canônica, para testar a igualdade por valor.
        // ignore: prefer_const_constructors
        aCopy: GjaTypographyTokens.fallback(),
        b: _bigger(_fallback),
      );
    });

    test('Contrato do conjunto tipográfico — Interpolação de tamanho', () {
      final a = _fallback.copyWith(base: _fallback.base.copyWith(fontSize: 14));
      final b = _fallback.copyWith(base: _fallback.base.copyWith(fontSize: 18));
      expect(a.lerp(b, 0.5).base.fontSize, 16);
    });

    test('Contrato do conjunto tipográfico — Valores vêm dos primitivos', () {
      final sizes = GjaTypographyPrimitives.sizes.values.toSet();
      final lineHeights = GjaTypographyPrimitives.lineHeights.values.toList();
      final weights = GjaTypographyPrimitives.weights.values.toSet();
      for (final MapEntry(key: name, value: s) in _fallback.styles.entries) {
        expect(sizes, contains(s.fontSize), reason: name);
        expect(weights, contains(s.fontWeight), reason: name);
        final px = _lineHeightPx(s);
        expect(
          lineHeights.any((lh) => (lh - px).abs() < 1e-9),
          isTrue,
          reason: '$name: $px',
        );
      }
    });

    test('igualdade e copyWith consideram cada estilo isoladamente', () {
      const other = TextStyle(fontSize: 99);
      final variants = [
        _fallback.copyWith(header1: other),
        _fallback.copyWith(header2: other),
        _fallback.copyWith(header3: other),
        _fallback.copyWith(header4: other),
        _fallback.copyWith(header5: other),
        _fallback.copyWith(header6: other),
        _fallback.copyWith(large: other),
        _fallback.copyWith(base: other),
        _fallback.copyWith(baseSemibold: other),
        _fallback.copyWith(baseBold: other),
        _fallback.copyWith(small: other),
      ];
      for (final (i, variant) in variants.indexed) {
        expect(variant, isNot(_fallback), reason: 'estilo $i');
      }
    });

    test('diagnóstico lista cada estilo', () {
      final dump = _fallback.toDiagnosticsNode().toStringDeep();
      for (final name in _fallback.styles.keys) {
        expect(dump, contains('$name:'), reason: name);
      }
    });
  });
}
