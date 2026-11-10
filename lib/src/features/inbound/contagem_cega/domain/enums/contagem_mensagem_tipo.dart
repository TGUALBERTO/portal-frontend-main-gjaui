/// Natureza do aviso exibido ao conferente depois de uma contagem.
enum ContagemMensagemTipo {
  /// Item conferido — quantidade bateu com a NF.
  sucesso,

  /// Divergência confirmada: a NF-e foi marcada para devolução.
  devolucao,

  /// Divergiu mas ainda há tentativa — o material precisa ser recontado.
  reconte,

  /// Falha técnica: a contagem não chegou ao SAP.
  ///
  /// Separado de [devolucao] porque são coisas diferentes para quem está na
  /// doca: devolução é um desfecho do processo, isto é um problema de sistema
  /// que se resolve tocando "Confirmar" de novo.
  erro,
}
