import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

import '../tokens/token_set.dart';
import 'interaction_state.dart';
import 'primitives/interaction_primitives.dart';

typedef _P = GjaInteractionPrimitives;

/// Valores de interação que não são cor: opacidade de desabilitado e foco.
///
/// Nível: semântico.
///
/// As cores de cada estado vêm das famílias de controle
/// (`GjaControlColors.of`), derivadas dos papéis de cor, no modelo Fiori.
/// Um controle desabilitado mantém as cores do normal e é exibido com
/// [disabledOpacity] (como `sapContent_DisabledOpacity`). O contorno de foco
/// usa a cor `focus` do tema, com [focusWidth] e [focusOffset].
@immutable
class GjaInteractionStateTokens
    extends GjaTokenSet<GjaInteractionStateTokens> {
  /// Cria um mapeamento de interação.
  const GjaInteractionStateTokens({
    required this.disabledOpacity,
    required this.focusWidth,
    required this.focusOffset,
  });

  /// Mapeamento de referência: desabilitado 0,4, foco de 2 px afastado 1 px.
  const GjaInteractionStateTokens.fallback()
    : this(
        disabledOpacity: _P.opacity40,
        focusWidth: _P.stroke2,
        focusOffset: _P.stroke1,
      );

  /// Menor espessura permitida para o contorno de foco.
  static const minFocusWidth = 2.0;

  /// Opacidade do controle inteiro quando desabilitado.
  final double disabledOpacity;

  /// Espessura do contorno de foco, em pixels lógicos.
  final double focusWidth;

  /// Afastamento do contorno de foco em relação à borda do controle.
  final double focusOffset;

  /// Opacidade do controle para [states]: [disabledOpacity] com `disabled`,
  /// senão 1.
  double opacity(Set<GjaInteractionState> states) =>
      states.contains(GjaInteractionState.disabled) ? disabledOpacity : 1;

  /// Se o contorno de foco aparece: `focused` ativo e `disabled` não.
  bool showsFocusRing(Set<GjaInteractionState> states) =>
      states.contains(GjaInteractionState.focused) &&
      !states.contains(GjaInteractionState.disabled);

  @override
  GjaInteractionStateTokens copyWith({
    double? disabledOpacity,
    double? focusWidth,
    double? focusOffset,
  }) {
    final result = GjaInteractionStateTokens(
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      focusWidth: focusWidth ?? this.focusWidth,
      focusOffset: focusOffset ?? this.focusOffset,
    );
    assert(() {
      if (!(result.disabledOpacity > 0 && result.disabledOpacity <= 1)) {
        throw AssertionError(
          '"disabledOpacity" deve estar entre 0 (exclusive) e 1: '
          '${result.disabledOpacity}',
        );
      }
      if (!result.focusWidth.isFinite || result.focusWidth < minFocusWidth) {
        throw AssertionError(
          '"focusWidth" deve ser ≥ $minFocusWidth: ${result.focusWidth}',
        );
      }
      if (!result.focusOffset.isFinite || result.focusOffset < 0) {
        throw AssertionError(
          '"focusOffset" deve ser finito e ≥ 0: ${result.focusOffset}',
        );
      }
      return true;
    }());
    return result;
  }

  @override
  GjaInteractionStateTokens lerp(
    GjaInteractionStateTokens? other,
    double t,
  ) {
    if (other == null) return this;
    double mix(double a, double b) => lerpDouble(a, b, t)!;
    return GjaInteractionStateTokens(
      disabledOpacity: mix(disabledOpacity, other.disabledOpacity),
      focusWidth: mix(focusWidth, other.focusWidth),
      focusOffset: mix(focusOffset, other.focusOffset),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaInteractionStateTokens &&
        other.disabledOpacity == disabledOpacity &&
        other.focusWidth == focusWidth &&
        other.focusOffset == focusOffset;
  }

  @override
  int get hashCode => Object.hash(disabledOpacity, focusWidth, focusOffset);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('disabledOpacity', disabledOpacity))
      ..add(DoubleProperty('focusWidth', focusWidth))
      ..add(DoubleProperty('focusOffset', focusOffset));
  }
}
