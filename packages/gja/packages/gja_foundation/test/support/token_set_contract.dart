import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Verifica o contrato comum de [GjaTokenSet] (design D1).
///
/// [a] e [b] são conjuntos do mesmo tipo com valores diferentes, e [aCopy] é
/// construído separadamente com os mesmos valores de [a].
void expectTokenSetContract<T extends GjaTokenSet<T>>({
  required T a,
  required T aCopy,
  required T b,
}) {
  expect(
    identical(a, aCopy),
    isFalse,
    reason: 'aCopy deve ser outra instância',
  );
  expect(a, aCopy, reason: 'conjuntos com valores iguais devem ser iguais');
  expect(
    a.hashCode,
    aCopy.hashCode,
    reason: 'hashCode deve seguir a igualdade',
  );
  expect(a, isNot(b), reason: 'a e b devem diferir em algum token');
  expect(
    a.copyWith(),
    a,
    reason: 'copyWith() sem argumentos deve ser igual ao original',
  );
  expect(a.lerp(b, 0), a, reason: 'lerp em t = 0 deve ser igual à origem');
  expect(a.lerp(b, 1), b, reason: 'lerp em t = 1 deve ser igual ao destino');
  expect(a.lerp(null, 0.5), a, reason: 'lerp com nulo deve ser igual à origem');
  expect(a.toDiagnosticsNode().toStringDeep(), isNotEmpty);
}

/// Conjunto mínimo usado para exercitar [expectTokenSetContract].
@immutable
class SampleTokens extends GjaTokenSet<SampleTokens> {
  /// Cria o conjunto.
  const SampleTokens(this.size);

  /// Token contínuo de exemplo.
  final double size;

  @override
  SampleTokens copyWith({double? size}) => SampleTokens(size ?? this.size);

  @override
  SampleTokens lerp(SampleTokens? other, double t) =>
      other == null ? this : SampleTokens(size + (other.size - size) * t);

  @override
  bool operator ==(Object other) => other is SampleTokens && other.size == size;

  @override
  int get hashCode => size.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size));
  }
}
