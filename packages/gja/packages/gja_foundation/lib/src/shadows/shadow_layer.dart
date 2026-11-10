import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// Geometria de uma camada de sombra, sem cor.
///
/// Nível: primitivo.
///
/// O deslocamento é só vertical (luz vinda de cima). A cor vem do papel
/// `shadow` do tema, com a opacidade multiplicada por [opacity] (ver
/// `GjaShadowTokens.shadowsFor`).
@immutable
class GjaShadowLayer with Diagnosticable {
  /// Cria uma camada.
  const GjaShadowLayer({
    required this.offsetY,
    required this.blurRadius,
    this.spreadRadius = 0,
    this.opacity = 1,
  });

  /// Camada sem deslocamento, desfoque, expansão nem opacidade; usada para
  /// completar listas de tamanhos diferentes na interpolação.
  static const zero = GjaShadowLayer(offsetY: 0, blurRadius: 0, opacity: 0);

  /// Deslocamento vertical, em pixels lógicos.
  final double offsetY;

  /// Desfoque, em pixels lógicos.
  final double blurRadius;

  /// Expansão, em pixels lógicos.
  final double spreadRadius;

  /// Fator aplicado à opacidade da cor de sombra, entre 0 e 1.
  final double opacity;

  /// Se os valores são finitos, desfoque e expansão não negativos e
  /// [opacity] está entre 0 e 1.
  bool get isValid =>
      offsetY.isFinite &&
      blurRadius.isFinite &&
      spreadRadius.isFinite &&
      blurRadius >= 0 &&
      spreadRadius >= 0 &&
      opacity >= 0 &&
      opacity <= 1;

  /// Interpola cada valor de [a] até [b].
  static GjaShadowLayer lerp(
    GjaShadowLayer a,
    GjaShadowLayer b,
    double t,
  ) {
    double mix(double x, double y) => lerpDouble(x, y, t)!;
    return GjaShadowLayer(
      offsetY: mix(a.offsetY, b.offsetY),
      blurRadius: mix(a.blurRadius, b.blurRadius),
      spreadRadius: mix(a.spreadRadius, b.spreadRadius),
      opacity: mix(a.opacity, b.opacity),
    );
  }

  /// Interpola duas listas de camadas, completando a menor com [zero].
  ///
  /// Nos extremos retorna exatamente [a] (`t = 0`) ou [b] (`t = 1`), sem as
  /// camadas de preenchimento.
  static List<GjaShadowLayer> lerpList(
    List<GjaShadowLayer> a,
    List<GjaShadowLayer> b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    final length = a.length > b.length ? a.length : b.length;
    return [
      for (var i = 0; i < length; i++)
        lerp(i < a.length ? a[i] : zero, i < b.length ? b[i] : zero, t),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaShadowLayer &&
        other.offsetY == offsetY &&
        other.blurRadius == blurRadius &&
        other.spreadRadius == spreadRadius &&
        other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(offsetY, blurRadius, spreadRadius, opacity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('offsetY', offsetY))
      ..add(DoubleProperty('blurRadius', blurRadius))
      ..add(DoubleProperty('spreadRadius', spreadRadius))
      ..add(DoubleProperty('opacity', opacity));
  }
}
