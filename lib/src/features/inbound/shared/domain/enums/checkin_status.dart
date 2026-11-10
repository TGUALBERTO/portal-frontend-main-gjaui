/// Status do check-in no SAP.
///
/// Compartilhado pelos submódulos do inbound: a portaria lê o campo `STATUS` de
/// `IN100_CHECKIN_MOTISTA` (serviço `ZGJAAUTO_GENERIC_SRV`) e a contagem cega lê
/// `INCheckin.Status` (serviço `ZGJAAUTO_SB_GENERIC`) — mesmo domínio de 1 letra
/// nos dois.
///
/// A regra que depende do modo da tela de veículos (`permitePara`) vive na
/// extension de `CheckinCheckoutVeiculoMode`, no próprio submódulo — este enum
/// não pode conhecer a tela que o consome.
///
/// O ciclo de vida normal é `R` → `L` → `E` → `C` → `F`, com `P` (pendências) e
/// `X` (cancelado) como desvios.
enum CheckinStatus {
  /// Check-in criado pelo motorista, ainda não liberado na portaria.
  realizado('R', 'Check-in realizado'),

  /// Entrada já liberada na portaria — o veículo está dentro da empresa.
  entradaLiberada('L', 'Entrada liberada'),

  /// Em entrega: a contagem às cegas foi iniciada.
  emEntrega('E', 'Em entrega'),

  /// Finalizado: o veículo já saiu da empresa.
  finalizado('F', 'Finalizado'),

  /// Cancelado.
  cancelado('X', 'Cancelado'),

  /// Check-in com pendências — saída temporária liberada.
  comPendencias('P', 'Check-in com pendências'),

  /// Entrega concluída: contagem às cegas finalizada.
  entregaConcluida('C', 'Entrega concluída'),

  /// Código ausente ou não mapeado. Nunca autoriza movimento.
  desconhecido('', 'Status desconhecido');

  const CheckinStatus(this.codigo, this.label);

  /// Código de 1 letra que trafega na API.
  final String codigo;

  /// Descrição legível, exibida na tela.
  final String label;

  /// Resolve o enum pelo código do SAP. Tolerante: valor nulo, vazio ou
  /// desconhecido vira [desconhecido] em vez de quebrar a tela.
  static CheckinStatus fromApi(String? value) {
    final codigo = value?.trim().toUpperCase();
    if (codigo == null || codigo.isEmpty) return desconhecido;
    for (final status in CheckinStatus.values) {
      if (status != desconhecido && status.codigo == codigo) return status;
    }
    return desconhecido;
  }

  /// Entrada permitida apenas em `{R, P}`.
  bool get permiteEntrada => this == realizado || this == comPendencias;

  /// Saída permitida apenas em `{C, P}`.
  bool get permiteSaida => this == entregaConcluida || this == comPendencias;

  /// Contagem cega permitida em `{L, E}`.
  ///
  /// `L` **inicia** a contagem (e o status vira `E`); `E` **retoma** uma
  /// contagem já aberta. Aceitar `E` é o que impede o check-in de ficar preso
  /// quando o coletor cai no meio da conferência — sem isso o caminhão fica
  /// parado na doca esperando alguém destravar o status no SAP.
  bool get permiteContagem => this == entradaLiberada || this == emEntrega;

  /// Onde o veículo está, em uma frase. Repetir só o [label] confunde na
  /// portaria — "Entrada liberada" somado a "não autorizado" se lê como
  /// contradição, quando na verdade significa que o veículo já entrou.
  String get situacao => switch (this) {
        realizado => 'O veículo ainda não entrou na empresa.',
        entradaLiberada =>
          'O veículo já está na empresa — a entrada já foi liberada.',
        emEntrega => 'O veículo está na empresa, com a entrega em andamento.',
        entregaConcluida =>
          'O veículo está na empresa, com a entrega concluída.',
        finalizado => 'O veículo já saiu da empresa — o check-in foi '
            'finalizado.',
        cancelado => 'O check-in foi cancelado.',
        comPendencias => 'O check-in está com pendências.',
        desconhecido => 'O status deste check-in não foi reconhecido.',
      };
}
