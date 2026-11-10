/// Escalas primitivas de interação: opacidade de desabilitado e espessuras de
/// traço.
///
/// Nível: primitivo.
///
/// Opacidades são nomeadas pela porcentagem (`opacity40` = 0,4); espessuras,
/// pelo valor em pixels lógicos. Não há opacidades de sobreposição por estado:
/// no Fiori, cada estado tem cores explícitas. Widgets não leem estes valores: eles usam
/// `GjaInteractionStateTokens`.
abstract final class GjaInteractionPrimitives {
  /// 40%, a opacidade de desabilitado (como `sapContent_DisabledOpacity`).
  static const opacity40 = 0.4;

  /// Escala de opacidades, em ordem crescente.
  static const opacities = <String, double>{'opacity40': opacity40};

  /// Traço de 1 px.
  static const stroke1 = 1.0;

  /// Traço de 2 px.
  static const stroke2 = 2.0;

  /// Traço de 3 px.
  static const stroke3 = 3.0;

  /// Escala de espessuras de traço, em ordem crescente.
  static const strokes = <String, double>{
    'stroke1': stroke1,
    'stroke2': stroke2,
    'stroke3': stroke3,
  };
}
