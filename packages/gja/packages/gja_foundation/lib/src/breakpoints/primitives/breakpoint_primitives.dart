/// Escala primitiva de larguras de tela, em pixels lógicos.
///
/// Nível: primitivo.
///
/// Os limites das faixas do SAPUI5 (`sap.ui.Device.media`, conjunto
/// `SAP_STANDARD_EXTENDED`): Phone < 600 ≤ Tablet < 1024 ≤ Desktop < 1440 ≤
/// LargeDesktop. Os nomes seguem o valor. Widgets não leem estes valores: eles
/// usam os limiares de `GjaBreakpointTokens`.
abstract final class GjaBreakpointPrimitives {
  /// 600 px, início da faixa Tablet (M).
  static const width600 = 600.0;

  /// 1024 px, início da faixa Desktop (L).
  static const width1024 = 1024.0;

  /// 1440 px, início da faixa LargeDesktop (XL).
  static const width1440 = 1440.0;

  /// Escala completa, em ordem crescente.
  static const values = <String, double>{
    'width600': width600,
    'width1024': width1024,
    'width1440': width1440,
  };
}
