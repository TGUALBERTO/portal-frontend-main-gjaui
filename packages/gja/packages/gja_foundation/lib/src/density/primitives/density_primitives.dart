/// Escala primitiva de densidade: alturas de elemento e de linha do Fiori.
///
/// Nível: primitivo.
///
/// Nomeadas pelo valor em pixels lógicos, como os parâmetros
/// `sapElement_Height`, `sapElement_LineHeight` e as variantes `_Compact_` do
/// Horizon. Ficam fora da escala de espaçamento porque 26, 36 e 44 não estão
/// na grade de 4 px. Widgets não leem estes valores: eles usam
/// `GjaDensityTokens`.
abstract final class GjaDensityPrimitives {
  /// 24, altura do separador vertical compacto (`sap.m.ToolbarSeparator`,
  /// 1.5rem).
  static const size24 = 24.0;

  /// 26, altura de elemento compacta (`sapElement_Compact_Height`, 1.625rem).
  static const size26 = 26.0;

  /// 32, altura de linha compacta (`sapElement_Compact_LineHeight`, 2rem) e
  /// do separador vertical cozy.
  static const size32 = 32.0;

  /// 36, altura de elemento cozy (`sapElement_Height`, 2.25rem).
  static const size36 = 36.0;

  /// 44, altura de linha cozy (`sapElement_LineHeight`, 2.75rem).
  static const size44 = 44.0;

  /// 48, altura de barra cozy (`sap.m.Bar`, 3rem).
  static const size48 = 48.0;

  /// Escala completa, em ordem crescente.
  static const sizes = <String, double>{
    'size24': size24,
    'size26': size26,
    'size32': size32,
    'size36': size36,
    'size44': size44,
    'size48': size48,
  };
}
