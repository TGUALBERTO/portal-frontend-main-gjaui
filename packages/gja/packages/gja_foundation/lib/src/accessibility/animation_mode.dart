/// Modo de animação, como `sap.ui.core.AnimationMode` do SAPUI5.
///
/// Nível: semântico.
///
/// O tema define o modo pedido pela aplicação; o modo efetivo combina esse
/// pedido com o da plataforma ([effective]). Com [minimal] ou [none], o
/// movimento é reduzido: as durações de movimento valem zero
/// (`GjaAccessibility.resolveMotion`).
///
/// Por ora, [basic] se comporta como [full] e [minimal] como [none] (valores
/// provisórios, ADR 0009): o GJA ainda não tem efeitos decorativos caros, e
/// o indicador de progresso indeterminado fica parado com movimento reduzido.
enum GjaAnimationMode {
  /// Todas as animações.
  full,

  /// Animações básicas, sem efeitos decorativos caros.
  basic,

  /// Só animações essenciais para indicar estado.
  minimal,

  /// Sem animações.
  none;

  /// Se este modo reduz o movimento: [minimal] ou [none].
  bool get reducesMotion => this == minimal || this == none;

  /// Modo efetivo: [none] quando a plataforma pede animações desligadas
  /// ([disableAnimations], ex.: `MediaQuery.disableAnimationsOf`); senão,
  /// este modo.
  GjaAnimationMode effective({required bool disableAnimations}) =>
      disableAnimations ? none : this;
}
