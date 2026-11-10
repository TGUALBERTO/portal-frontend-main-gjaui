/// Situação de um item da NF-e dentro da conferência.
///
/// O rótulo é o que aparece na tag do card do item — [pendente] mostra a ação
/// ("Contar"), não o estado, porque é o que o conferente precisa fazer.
enum ContagemItemStatus {
  /// Ainda não contado.
  pendente('Contar'),

  /// Contado e batendo com a quantidade da NF.
  ok('OK'),

  /// Divergente depois de esgotadas as tentativas de recontagem.
  divergente('Divergente');

  const ContagemItemStatus(this.label);

  final String label;
}
