/// Situação da NF-e, derivada dos itens (ver `ContagemNotaFiscal.status`).
enum ContagemNfStatus {
  /// Ainda há item por contar.
  pendente('Pendente', 'Pendente'),

  /// Todos os itens conferidos e batendo — a nota pode ser recebida.
  ok('Conferida', 'OK · Receber'),

  /// Algum item divergiu após o limite de tentativas: a nota inteira volta ao
  /// fornecedor.
  devolver('Devolver', 'Devolver');

  const ContagemNfStatus(this.label, this.labelResumo);

  /// Rótulo curto, usado na listagem de notas.
  final String label;

  /// Rótulo do resumo do check-in, que explica a consequência da situação.
  final String labelResumo;
}
