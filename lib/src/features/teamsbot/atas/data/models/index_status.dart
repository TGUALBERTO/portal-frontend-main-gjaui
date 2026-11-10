/// Situação de indexação de uma ATA no RAG.
///
/// Viaja na API como string em MAIÚSCULAS_COM_UNDERSCORE. Valores desconhecidos
/// caem em [IndexStatus.desconhecido].
enum IndexStatus {
  pendenteIndexacao('PENDENTE_INDEXACAO', 'Aguardando indexação'),
  ataIndexando('ATA_INDEXANDO', 'Indexando'),
  ataIndexada('ATA_INDEXADA', 'Indexada'),
  erroIndexacao('ERRO_INDEXACAO', 'Erro na indexação'),
  desconhecido('DESCONHECIDO', 'Desconhecido');

  const IndexStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static IndexStatus fromApi(String? value) {
    if (value == null) return IndexStatus.desconhecido;
    return IndexStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => IndexStatus.desconhecido,
    );
  }

  bool get isIndexando => this == IndexStatus.ataIndexando;

  bool get isErro => this == IndexStatus.erroIndexacao;

  /// `true` quando a indexação ainda pode mudar de estado por conta própria —
  /// justifica polling do detalhe e auto-refresh da lista.
  bool get isTransitorio =>
      this == IndexStatus.pendenteIndexacao || this == IndexStatus.ataIndexando;

  /// Estado final estável: indexada com sucesso ou com erro.
  bool get isEstavel =>
      this == IndexStatus.ataIndexada || this == IndexStatus.erroIndexacao;
}
