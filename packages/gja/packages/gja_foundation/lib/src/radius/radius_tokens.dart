import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

import '../tokens/token_set.dart';
import 'primitives/radius_primitives.dart';

/// Passos e papéis semânticos de raio de borda, em pixels lógicos.
///
/// Nível: semântico.
///
/// Widgets expressam raios somente com estes valores (ex.:
/// `BorderRadius.circular(radius.button)`). [full] produz o formato de
/// pílula. Os papéis ([button], [field], [popover], [element], [tile]) são os
/// raios por tipo de controle do Fiori (`sap*_BorderCornerRadius`) e podem ser
/// ajustados sem mexer na escala. Todos os valores devem ser finitos e não
/// negativos; [copyWith] verifica com `assert` em modo debug.
@immutable
class GjaRadiusTokens extends GjaTokenSet<GjaRadiusTokens> {
  /// Cria um mapeamento de raios.
  const GjaRadiusTokens({
    required this.none,
    required this.xs,
    required this.s,
    required this.m,
    required this.l,
    required this.xl,
    required this.full,
    required this.button,
    required this.field,
    required this.popover,
    required this.element,
    required this.tile,
  });

  /// Mapeamento de referência, com os raios do Horizon (valores provisórios,
  /// ADR 0009).
  const GjaRadiusTokens.fallback()
    : this(
        none: GjaRadiusPrimitives.radius0,
        xs: GjaRadiusPrimitives.radius2,
        s: GjaRadiusPrimitives.radius4,
        m: GjaRadiusPrimitives.radius8,
        l: GjaRadiusPrimitives.radius12,
        xl: GjaRadiusPrimitives.radius16,
        full: GjaRadiusPrimitives.radiusFull,
        button: GjaRadiusPrimitives.radius8,
        field: GjaRadiusPrimitives.radius4,
        popover: GjaRadiusPrimitives.radius8,
        element: GjaRadiusPrimitives.radius12,
        tile: GjaRadiusPrimitives.radius16,
      );

  /// Cantos retos.
  final double none;

  /// Arredondamento mínimo (indicadores pequenos).
  final double xs;

  /// Arredondamento pequeno.
  final double s;

  /// Arredondamento médio.
  final double m;

  /// Arredondamento grande.
  final double l;

  /// Arredondamento muito grande.
  final double xl;

  /// Pílula: extremidades em semicírculo.
  final double full;

  /// Botões e botões de ícone (`sapButton_BorderCornerRadius`).
  final double button;

  /// Campos de entrada (`sapField_BorderCornerRadius`).
  final double field;

  /// Popovers, menus e listas suspensas (`sapPopover_BorderCornerRadius`).
  final double popover;

  /// Diálogos e painéis (`sapElement_BorderCornerRadius`).
  final double element;

  /// Cartões e blocos (`sapTile_BorderCornerRadius`).
  final double tile;

  /// Valores por nome, na ordem de declaração.
  Map<String, double> get values => {
    'none': none,
    'xs': xs,
    's': s,
    'm': m,
    'l': l,
    'xl': xl,
    'full': full,
    'button': button,
    'field': field,
    'popover': popover,
    'element': element,
    'tile': tile,
  };

  @override
  GjaRadiusTokens copyWith({
    double? none,
    double? xs,
    double? s,
    double? m,
    double? l,
    double? xl,
    double? full,
    double? button,
    double? field,
    double? popover,
    double? element,
    double? tile,
  }) {
    final result = GjaRadiusTokens(
      none: none ?? this.none,
      xs: xs ?? this.xs,
      s: s ?? this.s,
      m: m ?? this.m,
      l: l ?? this.l,
      xl: xl ?? this.xl,
      full: full ?? this.full,
      button: button ?? this.button,
      field: field ?? this.field,
      popover: popover ?? this.popover,
      element: element ?? this.element,
      tile: tile ?? this.tile,
    );
    assert(() {
      for (final MapEntry(key: name, value: value) in result.values.entries) {
        if (!value.isFinite || value < 0) {
          throw AssertionError(
            'raio "$name" deve ser finito e não negativo: $value',
          );
        }
      }
      return true;
    }());
    return result;
  }

  @override
  GjaRadiusTokens lerp(GjaRadiusTokens? other, double t) {
    if (other == null) return this;
    double mix(double a, double b) => lerpDouble(a, b, t)!;
    return GjaRadiusTokens(
      none: mix(none, other.none),
      xs: mix(xs, other.xs),
      s: mix(s, other.s),
      m: mix(m, other.m),
      l: mix(l, other.l),
      xl: mix(xl, other.xl),
      full: mix(full, other.full),
      button: mix(button, other.button),
      field: mix(field, other.field),
      popover: mix(popover, other.popover),
      element: mix(element, other.element),
      tile: mix(tile, other.tile),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaRadiusTokens &&
        other.none == none &&
        other.xs == xs &&
        other.s == s &&
        other.m == m &&
        other.l == l &&
        other.xl == xl &&
        other.full == full &&
        other.button == button &&
        other.field == field &&
        other.popover == popover &&
        other.element == element &&
        other.tile == tile;
  }

  @override
  int get hashCode => Object.hash(
    none,
    xs,
    s,
    m,
    l,
    xl,
    full,
    button,
    field,
    popover,
    element,
    tile,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final MapEntry(key: name, value: value) in values.entries) {
      properties.add(DoubleProperty(name, value));
    }
  }
}
