/// Estado de interação de um componente, como os estados de controle do Fiori.
///
/// Nível: semântico.
///
/// Não há estado de arraste: no Fiori, o item arrastado usa a sombra `dragged`
/// de `GjaShadowTokens` e as cores de [pressed].
///
/// Um componente pode estar em vários estados ao mesmo tempo; as regras de
/// `GjaInteractionStateTokens` recebem o conjunto de estados ativos, e o
/// conjunto vazio representa o estado normal.
enum GjaInteractionState {
  /// Ponteiro sobre o componente.
  hovered,

  /// Foco de teclado no componente.
  focused,

  /// Componente sendo pressionado.
  pressed,

  /// Componente selecionado ou marcado.
  selected,

  /// Componente desabilitado.
  disabled,
}
