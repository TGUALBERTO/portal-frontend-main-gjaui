/// Classe de tamanho de uma largura disponível, em ordem crescente, como as
/// faixas S, M, L e XL do SAPUI5 (`sap.ui.Device.media`,
/// `SAP_STANDARD_EXTENDED`).
///
/// Nível: semântico.
///
/// Obtida com `GjaBreakpointTokens.classify`. Layouts comparam classes com
/// [isAtLeast] e [isAtMost], nunca com larguras literais.
enum GjaSizeClass {
  /// S, faixa Phone: celulares e janelas estreitas (< 600).
  small,

  /// M, faixa Tablet: tablets e janelas médias (600–1023).
  medium,

  /// L, faixa Desktop: notebooks e desktops (1024–1439).
  large,

  /// XL, faixa LargeDesktop: desktops largos (≥ 1440).
  extraLarge;

  /// Se esta classe é igual a [other] ou maior.
  bool isAtLeast(GjaSizeClass other) => index >= other.index;

  /// Se esta classe é igual a [other] ou menor.
  bool isAtMost(GjaSizeClass other) => index <= other.index;
}
