import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

const _fallback = GjaShadowTokens.fallback();

void main() {
  test('Sombras e papéis — Papéis do mapeamento de referência', () {
    final roles = [
      (_fallback.card, _fallback.shadow0),
      (_fallback.popover, _fallback.shadow2),
      (_fallback.dialog, _fallback.shadow3),
      (_fallback.dragged, _fallback.shadow3),
      (_fallback.header, GjaShadowPrimitives.header),
    ];
    for (final (i, (role, expected)) in roles.indexed) {
      expect(listEquals(role, expected), isTrue, reason: 'papel $i');
    }
    for (final MapEntry(key: name, value: primitive)
        in GjaShadowPrimitives.values.entries) {
      expect(
        listEquals(_fallback.values[name], primitive),
        isTrue,
        reason: name,
      );
    }
  });

  test('Sombras e papéis — Sem vocabulário do Material', () {
    final names = [
      ..._fallback.values.keys,
      ...GjaShadowPrimitives.values.keys,
    ];
    expect(names.where((n) => n.toLowerCase().contains('elevation')), isEmpty);
    // Nomes públicos declarados no código do fundamento (classes, membros,
    // arquivos e exports), fora dos comentários.
    final sources = [
      File('lib/gja_foundation.dart'),
      File('lib/gja_primitives.dart'),
      ...Directory('lib/src').listSync(recursive: true).whereType<File>(),
    ];
    for (final file in sources) {
      expect(file.path.toLowerCase(), isNot(contains('elevation')));
      final code = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        RegExp('elevation', caseSensitive: false).hasMatch(code),
        isFalse,
        reason: file.path,
      );
    }
  });

  group('Sombras com a cor do tema', () {
    test('Sombras com a cor do tema — Sombra com a cor do modo', () {
      final lightShadow = const GjaColorTokens.light().shadow;
      final darkShadow = const GjaColorTokens.dark().shadow;
      final light = _fallback.boxShadows(_fallback.card, lightShadow);
      final dark = _fallback.boxShadows(_fallback.card, darkShadow);
      expect(light, hasLength(_fallback.card.length));
      expect(dark, hasLength(_fallback.card.length));
      for (var i = 0; i < light.length; i++) {
        final layer = _fallback.card[i];
        expect(light[i].offset, dark[i].offset);
        expect(light[i].blurRadius, dark[i].blurRadius);
        expect(light[i].spreadRadius, dark[i].spreadRadius);
        expect(light[i].offset.dy, layer.offsetY);
        expect(light[i].color.a, closeTo(lightShadow.a * layer.opacity, 1e-3));
        expect(dark[i].color.a, closeTo(darkShadow.a * layer.opacity, 1e-3));
        expect(light[i].color.r, lightShadow.r);
      }
    });

    test('Sombras com a cor do tema — Sombra vazia', () {
      for (final color in [const Color(0xFF000000), const Color(0x66123456)]) {
        expect(_fallback.boxShadows(_fallback.none, color), isEmpty);
      }
    });
  });

  group('Contrato do conjunto de sombras', () {
    test('Contrato do conjunto de sombras — Contrato verificado', () {
      expectTokenSetContract(
        a: _fallback,
        // Instância não canônica, para testar a igualdade por valor.
        // ignore: prefer_const_constructors
        aCopy: GjaShadowTokens.fallback(),
        b: _fallback.copyWith(card: _fallback.shadow1),
      );
    });

    test(
      'Contrato do conjunto de sombras — Interpolação a partir de sombra vazia',
      () {
        final from = _fallback.copyWith(card: _fallback.none);
        final to = _fallback.copyWith(card: _fallback.shadow1);
        final mid = from.lerp(to, 0.5).card;
        expect(mid, hasLength(_fallback.shadow1.length));
        for (var i = 0; i < mid.length; i++) {
          final full = _fallback.shadow1[i];
          expect(mid[i].offsetY, full.offsetY / 2);
          expect(mid[i].blurRadius, full.blurRadius / 2);
          expect(mid[i].spreadRadius, full.spreadRadius / 2);
          expect(mid[i].opacity, full.opacity / 2);
        }
      },
    );

    test('camada inválida é rejeitada com o nome do campo', () {
      expect(
        () => _fallback.copyWith(
          popover: const [
            GjaShadowLayer(offsetY: 1, blurRadius: 2, opacity: 2),
          ],
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('"popover"'),
          ),
        ),
      );
    });

    test('igualdade e copyWith consideram cada campo isoladamente', () {
      const other = [GjaShadowLayer(offsetY: 9, blurRadius: 9)];
      final variants = [
        _fallback.copyWith(none: other),
        _fallback.copyWith(shadow0: other),
        _fallback.copyWith(shadow1: other),
        _fallback.copyWith(shadow2: other),
        _fallback.copyWith(shadow3: other),
        _fallback.copyWith(card: other),
        _fallback.copyWith(popover: other),
        _fallback.copyWith(dialog: other),
        _fallback.copyWith(dragged: other),
        _fallback.copyWith(header: other),
      ];
      for (final (i, variant) in variants.indexed) {
        expect(variant, isNot(_fallback), reason: 'campo $i');
        expect(variant.lerp(_fallback, 1), _fallback, reason: 'campo $i');
      }
    });

    test('diagnóstico lista cada sombra e papel', () {
      final dump = _fallback.toDiagnosticsNode().toStringDeep();
      for (final name in _fallback.values.keys) {
        expect(dump, contains('$name:'), reason: name);
      }
    });
  });
}
