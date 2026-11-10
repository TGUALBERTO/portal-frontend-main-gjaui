/// Status de um item na fila FIFO de criação de ATAs.
enum FilaStatus {
  aguardando('AGUARDANDO', 'Aguardando'),
  processando('PROCESSANDO', 'Processando'),
  concluido('CONCLUIDO', 'Concluído'),
  erro('ERRO', 'Erro'),
  desconhecido('DESCONHECIDO', 'Desconhecido');

  const FilaStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FilaStatus fromApi(String? value) {
    if (value == null) return FilaStatus.desconhecido;
    return FilaStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => FilaStatus.desconhecido,
    );
  }

  bool get isErro => this == FilaStatus.erro;

  bool get isTransitorio =>
      this == FilaStatus.aguardando || this == FilaStatus.processando;
}
