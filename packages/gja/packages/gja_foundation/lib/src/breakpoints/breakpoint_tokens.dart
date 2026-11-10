import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

import '../tokens/token_set.dart';
import 'primitives/breakpoint_primitives.dart';
import 'size_class.dart';

/// Limiares semânticos de largura e a classificação de uma largura.
///
/// Nível: semântico.
///
/// Cada campo é a largura mínima, em pixels lógicos, da classe de mesmo nome;
/// abaixo de [medium] a classe é `small`. Os limiares devem ser finitos,
/// positivos e estritamente crescentes; [copyWith] verifica com `assert` em
/// modo debug.
@immutable
class GjaBreakpointTokens extends GjaTokenSet<GjaBreakpointTokens> {
  /// Cria um mapeamento de limiares.
  const GjaBreakpointTokens({
    required this.medium,
    required this.large,
    required this.extraLarge,
  });

  /// Mapeamento de referência: 600, 1024 e 1440, os limites das faixas do
  /// SAPUI5 (`SAP_STANDARD_EXTENDED`).
  const GjaBreakpointTokens.fallback()
    : this(
        medium: GjaBreakpointPrimitives.width600,
        large: GjaBreakpointPrimitives.width1024,
        extraLarge: GjaBreakpointPrimitives.width1440,
      );

  /// Largura mínima da classe `medium`.
  final double medium;

  /// Largura mínima da classe `large`.
  final double large;

  /// Largura mínima da classe `extraLarge`.
  final double extraLarge;

  /// Classe de tamanho de [width], em pixels lógicos.
  ///
  /// É a maior classe cujo limiar é menor ou igual a [width] (limiar
  /// inclusivo). Zero é `small`; `double.infinity` é `extraLarge`.
  ///
  /// Lança [ArgumentError] para largura negativa ou `NaN`.
  GjaSizeClass classify(double width) {
    if (width.isNaN || width < 0) {
      throw ArgumentError.value(width, 'width', 'largura inválida');
    }
    if (width >= extraLarge) return GjaSizeClass.extraLarge;
    if (width >= large) return GjaSizeClass.large;
    if (width >= medium) return GjaSizeClass.medium;
    return GjaSizeClass.small;
  }

  /// Largura mínima de [sizeClass]; `small` começa em zero.
  double minWidthOf(GjaSizeClass sizeClass) {
    return switch (sizeClass) {
      GjaSizeClass.small => 0,
      GjaSizeClass.medium => medium,
      GjaSizeClass.large => large,
      GjaSizeClass.extraLarge => extraLarge,
    };
  }

  @override
  GjaBreakpointTokens copyWith({
    double? medium,
    double? large,
    double? extraLarge,
  }) {
    final result = GjaBreakpointTokens(
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
    );
    assert(
      result._isValid,
      'limiares devem ser finitos, positivos e crescentes '
      '(medium < large < extraLarge): ${result.medium}, ${result.large}, '
      '${result.extraLarge}',
    );
    return result;
  }

  bool get _isValid =>
      extraLarge.isFinite && medium > 0 && medium < large && large < extraLarge;

  @override
  GjaBreakpointTokens lerp(GjaBreakpointTokens? other, double t) {
    if (other == null) return this;
    return GjaBreakpointTokens(
      medium: lerpDouble(medium, other.medium, t)!,
      large: lerpDouble(large, other.large, t)!,
      extraLarge: lerpDouble(extraLarge, other.extraLarge, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaBreakpointTokens &&
        other.medium == medium &&
        other.large == large &&
        other.extraLarge == extraLarge;
  }

  @override
  int get hashCode => Object.hash(medium, large, extraLarge);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('medium', medium))
      ..add(DoubleProperty('large', large))
      ..add(DoubleProperty('extraLarge', extraLarge));
  }
}
