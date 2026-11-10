/// Escala primitiva de raios de borda, em pixels lógicos.
///
/// Nível: primitivo.
///
/// Os nomes seguem o valor. [radiusFull] produz o formato de pílula: o
/// Flutter reduz raios maiores que a caixa para a metade da menor dimensão.
/// Widgets não leem estes valores: eles usam os passos e papéis de
/// `GjaRadiusTokens`.
abstract final class GjaRadiusPrimitives {
  /// 0 px (cantos retos).
  static const radius0 = 0.0;

  /// 2 px.
  static const radius2 = 2.0;

  /// 4 px.
  static const radius4 = 4.0;

  /// 6 px.
  static const radius6 = 6.0;

  /// 8 px.
  static const radius8 = 8.0;

  /// 12 px.
  static const radius12 = 12.0;

  /// 16 px.
  static const radius16 = 16.0;

  /// Pílula: grande e finito, para que a redução do `RRect` resulte em
  /// cantos completamente arredondados (`double.infinity` gera `NaN`).
  static const radiusFull = 9999.0;

  /// Escala numerada, em ordem crescente (sem [radiusFull]).
  static const values = <String, double>{
    'radius0': radius0,
    'radius2': radius2,
    'radius4': radius4,
    'radius6': radius6,
    'radius8': radius8,
    'radius12': radius12,
    'radius16': radius16,
  };
}
