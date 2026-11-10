import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show TextLeadingDistribution, TextStyle;

import '../tokens/token_set.dart';
import 'primitives/typography_primitives.dart';

typedef _P = GjaTypographyPrimitives;

const _header1 = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size48,
  height: _P.lineHeight60 / _P.size48,
  fontWeight: _P.bold,
);

const _header2 = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size32,
  height: _P.lineHeight40 / _P.size32,
  fontWeight: _P.bold,
);

const _header3 = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size24,
  height: _P.lineHeight32 / _P.size24,
  fontWeight: _P.bold,
);

const _header4 = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size20,
  height: _P.lineHeight24 / _P.size20,
  fontWeight: _P.bold,
);

const _header5 = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size16,
  height: _P.lineHeight20 / _P.size16,
  fontWeight: _P.bold,
);

const _header6 = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size14,
  height: _P.lineHeight20 / _P.size14,
  fontWeight: _P.bold,
);

const _large = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size16,
  height: _P.lineHeight24 / _P.size16,
  fontWeight: _P.regular,
);

const _base = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size14,
  height: _P.lineHeight20 / _P.size14,
  fontWeight: _P.regular,
);

const _baseSemibold = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size14,
  height: _P.lineHeight20 / _P.size14,
  fontWeight: _P.semibold,
);

const _baseBold = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size14,
  height: _P.lineHeight20 / _P.size14,
  fontWeight: _P.bold,
);

const _small = TextStyle(
  fontFamily: _P.fontFamily,
  fontFamilyFallback: _P.fontFamilyFallback,
  leadingDistribution: TextLeadingDistribution.even,
  fontSize: _P.size12,
  height: _P.lineHeight16 / _P.size12,
  fontWeight: _P.regular,
);

/// Estilos semânticos de texto, nomeados pelos parâmetros de tema Fiori.
///
/// Nível: semântico.
///
/// Widgets usam somente estes estilos (ou tokens de componente derivados),
/// combinados com uma cor dos papéis de cor (ex.:
/// `typography.base.copyWith(color: colors.text)`). Nenhum estilo define
/// cor ou fundo. Os títulos `header1`…`header6` são negritos; `large`, `base`
/// e `small` são regulares, e rótulos se distinguem pela cor
/// `colors.label`, como no `sap.m.Label`. Tamanhos e alturas são pixels
/// lógicos antes da escala de texto do sistema.
@immutable
class GjaTypographyTokens extends GjaTokenSet<GjaTypographyTokens> {
  /// Cria um mapeamento tipográfico.
  const GjaTypographyTokens({
    required this.header1,
    required this.header2,
    required this.header3,
    required this.header4,
    required this.header5,
    required this.header6,
    required this.large,
    required this.base,
    required this.baseSemibold,
    required this.baseBold,
    required this.small,
  });

  /// Mapeamento de referência, com a Inter empacotada.
  const GjaTypographyTokens.fallback()
    : this(
        header1: _header1,
        header2: _header2,
        header3: _header3,
        header4: _header4,
        header5: _header5,
        header6: _header6,
        large: _large,
        base: _base,
        baseSemibold: _baseSemibold,
        baseBold: _baseBold,
        small: _small,
      );

  /// Título de nível 1 (`sapFontHeader1Size`, 3rem).
  final TextStyle header1;

  /// Título de nível 2 (`sapFontHeader2Size`, 2rem): título de página.
  final TextStyle header2;

  /// Título de nível 3 (`sapFontHeader3Size`, 1,5rem).
  final TextStyle header3;

  /// Título de nível 4 (`sapFontHeader4Size`, 1,25rem): título de cartão ou de popover.
  final TextStyle header4;

  /// Título de nível 5 (`sapFontHeader5Size`, 1rem).
  final TextStyle header5;

  /// Título de nível 6 (`sapFontHeader6Size`, 0,875rem).
  final TextStyle header6;

  /// Texto grande (`sapFontLargeSize`, 1rem).
  final TextStyle large;

  /// Texto base (`sapFontSize`, 0,875rem): texto corrido e rótulos.
  final TextStyle base;

  /// Texto base em semibold (`sapFontSize` com a família semibold): texto de botões.
  final TextStyle baseSemibold;

  /// Texto base em negrito (`sapFontSize` com `sapFontBoldFamily`): texto enfatizado.
  final TextStyle baseBold;

  /// Texto pequeno (`sapFontSmallSize`, 0,75rem): legendas e contadores.
  final TextStyle small;

  /// Estilos por nome, na ordem de declaração.
  Map<String, TextStyle> get styles => {
    'header1': header1,
    'header2': header2,
    'header3': header3,
    'header4': header4,
    'header5': header5,
    'header6': header6,
    'large': large,
    'base': base,
    'baseSemibold': baseSemibold,
    'baseBold': baseBold,
    'small': small,
  };

  @override
  GjaTypographyTokens copyWith({
    TextStyle? header1,
    TextStyle? header2,
    TextStyle? header3,
    TextStyle? header4,
    TextStyle? header5,
    TextStyle? header6,
    TextStyle? large,
    TextStyle? base,
    TextStyle? baseSemibold,
    TextStyle? baseBold,
    TextStyle? small,
  }) {
    return GjaTypographyTokens(
      header1: header1 ?? this.header1,
      header2: header2 ?? this.header2,
      header3: header3 ?? this.header3,
      header4: header4 ?? this.header4,
      header5: header5 ?? this.header5,
      header6: header6 ?? this.header6,
      large: large ?? this.large,
      base: base ?? this.base,
      baseSemibold: baseSemibold ?? this.baseSemibold,
      baseBold: baseBold ?? this.baseBold,
      small: small ?? this.small,
    );
  }

  @override
  GjaTypographyTokens lerp(GjaTypographyTokens? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return GjaTypographyTokens(
      header1: mix(header1, other.header1),
      header2: mix(header2, other.header2),
      header3: mix(header3, other.header3),
      header4: mix(header4, other.header4),
      header5: mix(header5, other.header5),
      header6: mix(header6, other.header6),
      large: mix(large, other.large),
      base: mix(base, other.base),
      baseSemibold: mix(baseSemibold, other.baseSemibold),
      baseBold: mix(baseBold, other.baseBold),
      small: mix(small, other.small),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaTypographyTokens &&
        other.header1 == header1 &&
        other.header2 == header2 &&
        other.header3 == header3 &&
        other.header4 == header4 &&
        other.header5 == header5 &&
        other.header6 == header6 &&
        other.large == large &&
        other.base == base &&
        other.baseSemibold == baseSemibold &&
        other.baseBold == baseBold &&
        other.small == small;
  }

  @override
  int get hashCode => Object.hash(
    header1,
    header2,
    header3,
    header4,
    header5,
    header6,
    large,
    base,
    baseSemibold,
    baseBold,
    small,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final MapEntry(key: name, value: style) in styles.entries) {
      properties.add(DiagnosticsProperty<TextStyle>(name, style));
    }
  }
}
