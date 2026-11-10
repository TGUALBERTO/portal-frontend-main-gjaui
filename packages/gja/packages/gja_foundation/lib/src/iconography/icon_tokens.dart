import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

import '../tokens/token_set.dart';
import 'primitives/icon_primitives.dart';

/// Passos e papéis semânticos de tamanho de ícone, em pixels lógicos.
///
/// Nível: semântico.
///
/// Widgets dimensionam ícones somente com estes valores. Os papéis [inline]
/// (junto ao texto corrido) e [control] (dentro de botões e campos, `sapContent_IconHeight`) podem ser
/// ajustados sem mexer na escala. Todos os valores devem ser finitos e
/// positivos; [copyWith] verifica com `assert` em modo debug.
@immutable
class GjaIconTokens extends GjaTokenSet<GjaIconTokens> {
  /// Cria um mapeamento de tamanhos de ícone.
  const GjaIconTokens({
    required this.small,
    required this.medium,
    required this.large,
    required this.xLarge,
    required this.inline,
    required this.control,
  });

  /// Mapeamento de referência.
  const GjaIconTokens.fallback()
    : this(
        small: GjaIconPrimitives.size16,
        medium: GjaIconPrimitives.size20,
        large: GjaIconPrimitives.size24,
        xLarge: GjaIconPrimitives.size32,
        inline: GjaIconPrimitives.size16,
        control: GjaIconPrimitives.size16,
      );

  /// Ícone pequeno.
  final double small;

  /// Ícone médio.
  final double medium;

  /// Ícone grande (navegação).
  final double large;

  /// Ícone extragrande (destaques).
  final double xLarge;

  /// Junto ao texto corrido.
  final double inline;

  /// Dentro de botões e campos (`sapContent_IconHeight`, 1rem).
  final double control;

  /// Valores por nome, na ordem de declaração.
  Map<String, double> get values => {
    'small': small,
    'medium': medium,
    'large': large,
    'xLarge': xLarge,
    'inline': inline,
    'control': control,
  };

  @override
  GjaIconTokens copyWith({
    double? small,
    double? medium,
    double? large,
    double? xLarge,
    double? inline,
    double? control,
  }) {
    final result = GjaIconTokens(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      xLarge: xLarge ?? this.xLarge,
      inline: inline ?? this.inline,
      control: control ?? this.control,
    );
    assert(() {
      for (final MapEntry(key: name, value: value) in result.values.entries) {
        if (!value.isFinite || value <= 0) {
          throw AssertionError(
            'tamanho de ícone "$name" deve ser finito e positivo: $value',
          );
        }
      }
      return true;
    }());
    return result;
  }

  @override
  GjaIconTokens lerp(GjaIconTokens? other, double t) {
    if (other == null) return this;
    double mix(double a, double b) => lerpDouble(a, b, t)!;
    return GjaIconTokens(
      small: mix(small, other.small),
      medium: mix(medium, other.medium),
      large: mix(large, other.large),
      xLarge: mix(xLarge, other.xLarge),
      inline: mix(inline, other.inline),
      control: mix(control, other.control),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaIconTokens &&
        other.small == small &&
        other.medium == medium &&
        other.large == large &&
        other.xLarge == xLarge &&
        other.inline == inline &&
        other.control == control;
  }

  @override
  int get hashCode =>
      Object.hash(small, medium, large, xLarge, inline, control);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final MapEntry(key: name, value: value) in values.entries) {
      properties.add(DoubleProperty(name, value));
    }
  }
}
