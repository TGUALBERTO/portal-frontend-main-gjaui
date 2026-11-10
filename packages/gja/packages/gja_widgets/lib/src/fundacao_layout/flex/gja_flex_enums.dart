/// Alinhamento no eixo principal de `GjaHBox` e `GjaVBox`, como o
/// `sap.m.FlexJustifyContent`.
enum GjaFlexJustifyContent {
  /// Junto ao início (esquerda em LTR, topo na caixa vertical).
  start,

  /// Centralizado.
  center,

  /// Junto ao fim.
  end,

  /// Espaço livre distribuído entre os itens, além do `gap`.
  spaceBetween,

  /// Espaço livre distribuído em volta dos itens, metade antes e metade
  /// depois de cada um, além do `gap`.
  spaceAround,
}

/// Alinhamento no eixo cruzado de `GjaHBox` e `GjaVBox`, como o
/// `sap.m.FlexAlignItems`.
enum GjaFlexAlignItems {
  /// Junto ao início (topo na caixa horizontal, início do texto na vertical).
  start,

  /// Centralizado.
  center,

  /// Junto ao fim.
  end,

  /// Pela linha de base alfabética do texto. Na caixa vertical vale como
  /// [start], como no CSS de uma coluna.
  baseline,

  /// Ocupa toda a extensão do eixo cruzado.
  stretch,
}

/// Quebra de linha de `GjaHBox`, como o `sap.m.FlexWrap`.
enum GjaFlexWrap {
  /// Todos os itens numa só linha.
  noWrap,

  /// Os itens que não cabem vão para a linha seguinte.
  wrap,
}
