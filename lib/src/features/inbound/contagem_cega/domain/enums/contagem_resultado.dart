/// Desfecho de uma tentativa de contagem, devolvido pelo controller para a tela
/// decidir se navega de volta para a lista de itens ou permanece para a
/// recontagem.
enum ContagemResultado {
  /// Lote ou quantidade não informados — nada foi gravado.
  invalido,

  /// Quantidade bateu: item conferido.
  conferido,

  /// Divergiu e ainda há tentativa disponível.
  reconte,

  /// Divergiu na última tentativa: a NF-e foi marcada para devolução.
  divergenciaConfirmada,

  /// O SAP recusou a gravação — **nada mudou**: a tentativa não foi consumida e
  /// o item continua como estava.
  ///
  /// É um desfecho e não uma exceção porque a tela trata igual aos demais: fica
  /// aberta, com a faixa explicando. Devolver `AppResult` aqui misturaria erro
  /// técnico com [reconte], que é regra de negócio.
  falhaGravacao,
}
