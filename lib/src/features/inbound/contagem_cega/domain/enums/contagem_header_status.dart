/// `Status` do `INCContagemACegaHeader` — o estado da conferência do **caminhão
/// inteiro**, não de uma NF-e.
///
/// Não confundir com [ContagemNfStatus] (desfecho por nota, derivado dos itens)
/// nem com `CheckinStatus` (ciclo de vida do check-in de veículo). Os três usam
/// letras e duas delas coincidem em `'E'` por acaso, em entidades diferentes.
///
/// Existe como enum próprio porque a única pergunta que a tela faz sobre este
/// campo é [finalizado] — e comparar string solta em três lugares é como uma
/// delas fica para trás quando o SAP ganhar um status novo.
enum ContagemHeaderStatus {
  /// Nenhum cabeçalho no SAP: o check-in nunca teve contagem aberta.
  ///
  /// Distinto de [aberto] de propósito. A tela trata os dois igual hoje, mas
  /// colapsá-los faria "não existe" virar "existe em `'E'`", e é
  /// `garantirCabecalhoContagem` quem decide criar.
  inexistente,

  /// `'E'` — conferência aberta, é o estado normal durante a contagem.
  aberto,

  /// `'C'` — finalizado com todas as NF-e conferidas.
  finalizadoConforme,

  /// `'D'` — finalizado com ao menos uma NF-e condenada à devolução.
  finalizadoDivergente,

  /// Letra que o app não conhece.
  ///
  /// **Não** bloqueia: só `'C'`/`'D'` significam "já finalizado", e tratar o
  /// desconhecido como fechado travaria a doca se o SAP passar a gravar um
  /// status intermediário.
  desconhecido;

  /// O SAP já processou o fecho deste check-in.
  bool get finalizado =>
      this == finalizadoConforme || this == finalizadoDivergente;

  /// Frase para a tela explicar por que o botão de finalizar está travado.
  String get situacao => switch (this) {
        finalizadoConforme =>
          'Este check-in já foi finalizado com todas as notas conferidas.',
        finalizadoDivergente =>
          'Este check-in já foi finalizado com nota(s) para devolução.',
        _ => '',
      };
}
