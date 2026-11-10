import 'package:gjamobile/src/shared/widgets/status_pill.dart';

/// Estado de uma execucao de rotina de integracao, espelhando o enum do
/// backend (`StatusExecucao`).
///
/// Independente do `FilaStatus` do TeamsBot de proposito: sao dominios
/// diferentes e o vocabulario aqui e o da integracao — o processo *executa*.
/// `fromApi` cai em [desconhecido] para nao quebrar a tela quando o backend
/// ganhar um estado novo.
enum StatusExecucao {
  aguardando('AGUARDANDO', 'Aguardando'),
  executando('EXECUTANDO', 'Executando'),
  concluido('CONCLUIDO', 'Concluído'),
  erro('ERRO', 'Erro'),
  desconhecido('DESCONHECIDO', 'Desconhecido');

  const StatusExecucao(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static StatusExecucao fromApi(String? value) {
    if (value == null) return StatusExecucao.desconhecido;
    return StatusExecucao.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => StatusExecucao.desconhecido,
    );
  }

  bool get isErro => this == StatusExecucao.erro;

  /// Estados vivos: e o que liga o polling da tela.
  bool get isTransitorio =>
      this == StatusExecucao.aguardando || this == StatusExecucao.executando;

  BadgeTone get tone => switch (this) {
        StatusExecucao.concluido => BadgeTone.success,
        StatusExecucao.erro => BadgeTone.error,
        StatusExecucao.executando => BadgeTone.info,
        StatusExecucao.aguardando => BadgeTone.warning,
        StatusExecucao.desconhecido => BadgeTone.neutral,
      };
}
