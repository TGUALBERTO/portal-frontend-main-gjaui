import 'dart:ui' show FontWeight;

/// Escalas tipográficas primitivas: família, tamanhos, alturas de linha e pesos.
///
/// Nível: primitivo.
///
/// A família Inter (SIL Open Font License 1.1) é empacotada em
/// `gja_foundation`; tamanhos e alturas de linha são pixels lógicos antes
/// da escala de texto do sistema. Widgets não leem estes valores: eles usam os
/// estilos de `GjaTypographyTokens`.
abstract final class GjaTypographyPrimitives {
  /// Nome curto da família empacotada.
  static const familyName = 'Inter';

  /// Família com o prefixo do pacote, para uso em `TextStyle.fontFamily`.
  ///
  /// O prefixo é explícito (em vez de `TextStyle.package`) para que
  /// [fontFamilyFallback] continue apontando para fontes do sistema.
  static const fontFamily = 'packages/gja_foundation/$familyName';

  /// Fontes do sistema usadas para glifos que a Inter não cobre.
  static const fontFamilyFallback = <String>[
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  /// 12 px.
  static const size12 = 12.0;

  /// 14 px.
  static const size14 = 14.0;

  /// 16 px.
  static const size16 = 16.0;

  /// 18 px.
  static const size18 = 18.0;

  /// 20 px.
  static const size20 = 20.0;

  /// 24 px.
  static const size24 = 24.0;

  /// 28 px.
  static const size28 = 28.0;

  /// 32 px.
  static const size32 = 32.0;

  /// 40 px.
  static const size40 = 40.0;

  /// 48 px.
  static const size48 = 48.0;

  /// Escala de tamanhos, em ordem crescente.
  static const sizes = <String, double>{
    'size12': size12,
    'size14': size14,
    'size16': size16,
    'size18': size18,
    'size20': size20,
    'size24': size24,
    'size28': size28,
    'size32': size32,
    'size40': size40,
    'size48': size48,
  };

  /// Altura de linha de 16 px.
  static const lineHeight16 = 16.0;

  /// Altura de linha de 20 px.
  static const lineHeight20 = 20.0;

  /// Altura de linha de 24 px.
  static const lineHeight24 = 24.0;

  /// Altura de linha de 28 px.
  static const lineHeight28 = 28.0;

  /// Altura de linha de 32 px.
  static const lineHeight32 = 32.0;

  /// Altura de linha de 36 px.
  static const lineHeight36 = 36.0;

  /// Altura de linha de 40 px.
  static const lineHeight40 = 40.0;

  /// Altura de linha de 48 px.
  static const lineHeight48 = 48.0;

  /// Altura de linha de 60 px.
  static const lineHeight60 = 60.0;

  /// Escala de alturas de linha, em ordem crescente.
  static const lineHeights = <String, double>{
    'lineHeight16': lineHeight16,
    'lineHeight20': lineHeight20,
    'lineHeight24': lineHeight24,
    'lineHeight28': lineHeight28,
    'lineHeight32': lineHeight32,
    'lineHeight36': lineHeight36,
    'lineHeight40': lineHeight40,
    'lineHeight48': lineHeight48,
    'lineHeight60': lineHeight60,
  };

  /// Peso 400.
  static const regular = FontWeight.w400;

  /// Peso 500.
  static const medium = FontWeight.w500;

  /// Peso 600.
  static const semibold = FontWeight.w600;

  /// Peso 700.
  static const bold = FontWeight.w700;

  /// Pesos empacotados, em ordem crescente.
  static const weights = <String, FontWeight>{
    'regular': regular,
    'medium': medium,
    'semibold': semibold,
    'bold': bold,
  };
}
