/// Escala primitiva de espaçamento, em pixels lógicos.
///
/// Nível: primitivo.
///
/// Grade de 4 pixels, com o passo fino de 2. Os nomes seguem o valor. Widgets
/// não leem estes valores: eles usam os passos e papéis de
/// `GjaSpacingTokens`.
abstract final class GjaSpacingPrimitives {
  /// 0 px.
  static const space0 = 0.0;

  /// 2 px.
  static const space2 = 2.0;

  /// 4 px.
  static const space4 = 4.0;

  /// 8 px.
  static const space8 = 8.0;

  /// 12 px.
  static const space12 = 12.0;

  /// 16 px.
  static const space16 = 16.0;

  /// 20 px.
  static const space20 = 20.0;

  /// 24 px.
  static const space24 = 24.0;

  /// 32 px.
  static const space32 = 32.0;

  /// 40 px.
  static const space40 = 40.0;

  /// 48 px.
  static const space48 = 48.0;

  /// 64 px.
  static const space64 = 64.0;

  /// Escala completa, em ordem crescente.
  static const values = <String, double>{
    'space0': space0,
    'space2': space2,
    'space4': space4,
    'space8': space8,
    'space12': space12,
    'space16': space16,
    'space20': space20,
    'space24': space24,
    'space32': space32,
    'space40': space40,
    'space48': space48,
    'space64': space64,
  };
}
