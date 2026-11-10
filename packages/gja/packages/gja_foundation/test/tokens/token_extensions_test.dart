import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../support/token_set_contract.dart';

@immutable
class MarcaTokens extends GjaTokenExtension<MarcaTokens> {
  const MarcaTokens(this.logoHeight);

  final double logoHeight;

  @override
  MarcaTokens copyWith({double? logoHeight}) =>
      MarcaTokens(logoHeight ?? this.logoHeight);

  @override
  MarcaTokens lerp(MarcaTokens? other, double t) => other == null
      ? this
      : MarcaTokens(lerpDouble(logoHeight, other.logoHeight, t)!);

  @override
  bool operator ==(Object other) =>
      other is MarcaTokens && other.logoHeight == logoHeight;

  @override
  int get hashCode => logoHeight.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('logoHeight', logoHeight));
  }
}

@immutable
class RelatorioTokens extends GjaTokenExtension<RelatorioTokens> {
  const RelatorioTokens(this.columns);

  final int columns;

  @override
  RelatorioTokens copyWith({int? columns}) =>
      RelatorioTokens(columns ?? this.columns);

  @override
  RelatorioTokens lerp(RelatorioTokens? other, double t) =>
      other == null || t < 0.5 ? this : other;

  @override
  bool operator ==(Object other) =>
      other is RelatorioTokens && other.columns == columns;

  @override
  int get hashCode => columns.hashCode;
}

void main() {
  test('extensão cumpre o contrato de GjaTokenSet', () {
    expectTokenSetContract(
      a: const MarcaTokens(32),
      // ignore: prefer_const_constructors
      aCopy: MarcaTokens(32),
      b: const MarcaTokens(48),
    );
  });

  group('Extensões tipadas da aplicação', () {
    test('Extensões tipadas da aplicação — Extensão registrada', () {
      final extensions = GjaTokenExtensions([
        const MarcaTokens(32),
        const RelatorioTokens(3),
      ]);
      final MarcaTokens? marca = extensions.get<MarcaTokens>();
      expect(marca, const MarcaTokens(32));
      expect(extensions.get<RelatorioTokens>()?.columns, 3);
    });

    test('Extensões tipadas da aplicação — Extensão ausente', () {
      expect(
        GjaTokenExtensions([const MarcaTokens(32)]).get<RelatorioTokens>(),
        isNull,
      );
      expect(const GjaTokenExtensions.empty().get<MarcaTokens>(), isNull);
    });

    test('Extensões tipadas da aplicação — Interpolação das extensões', () {
      final a = GjaTokenExtensions([
        const MarcaTokens(32),
        const RelatorioTokens(3),
      ]);
      final b = GjaTokenExtensions([const MarcaTokens(48)]);
      final mid = a.lerp(b, 0.5);
      expect(mid.get<MarcaTokens>(), const MarcaTokens(40));
      expect(mid.get<RelatorioTokens>(), const RelatorioTokens(3));
      expect(b.lerp(a, 0.5).get<RelatorioTokens>(), const RelatorioTokens(3));
      expect(a.lerp(b, 0), a);
      expect(a.lerp(null, 0.5), a);
    });

    test('Extensões tipadas da aplicação — Registro duplicado', () {
      expect(
        () => GjaTokenExtensions([
          const MarcaTokens(32),
          const MarcaTokens(48),
        ]),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('MarcaTokens'),
          ),
        ),
      );
    });
  });

  test('coleções com as mesmas extensões são iguais', () {
    final a = GjaTokenExtensions([
      const MarcaTokens(32),
      const RelatorioTokens(3),
    ]);
    final b = GjaTokenExtensions([
      const RelatorioTokens(3),
      const MarcaTokens(32),
    ]);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(GjaTokenExtensions([const MarcaTokens(32)])));
  });

  test('diagnóstico lista as extensões pelo tipo', () {
    final dump = GjaTokenExtensions([
      const MarcaTokens(32),
    ]).toDiagnosticsNode().toStringDeep();
    expect(dump, contains('MarcaTokens'));
  });
}
