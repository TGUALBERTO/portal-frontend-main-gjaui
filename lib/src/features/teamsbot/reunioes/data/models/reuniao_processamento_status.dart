/// Status de processamento de uma reunião, da captura no Microsoft Graph até a
/// criação da ATA. Viaja na API como MAIÚSCULAS_COM_UNDERSCORE.
enum ReuniaoProcessamentoStatus {
  meetingFound('MEETING_FOUND', 'Reunião encontrada'),
  meetingCancelled('MEETING_CANCELLED', 'Reunião cancelada'),
  meetingNotFinished('MEETING_NOT_FINISHED', 'Ainda não realizada'),
  meetingFinished('MEETING_FINISHED', 'Reunião realizada'),
  notOnlineMeeting('NOT_ONLINE_MEETING', 'Não é reunião online'),
  transcriptionNotFound('TRANSCRIPTION_NOT_FOUND', 'Sem transcrição'),
  transcriptionFound('TRANSCRIPTION_FOUND', 'Transcrição encontrada'),
  transcriptionDownloaded('TRANSCRIPTION_DOWNLOADED', 'Transcrição baixada'),
  transcriptionSaveError('TRANSCRIPTION_SAVE_ERROR', 'Erro ao salvar transcrição'),
  queuedForMinutesCreation('QUEUED_FOR_MINUTES_CREATION', 'Na fila para gerar ATA'),
  minutesProcessing('MINUTES_PROCESSING', 'Gerando ATA'),
  minutesCreated('MINUTES_CREATED', 'ATA criada'),
  minutesCreationError('MINUTES_CREATION_ERROR', 'Erro ao criar ATA'),
  desconhecido('DESCONHECIDO', 'Desconhecido');

  const ReuniaoProcessamentoStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReuniaoProcessamentoStatus fromApi(String? value) {
    if (value == null) return ReuniaoProcessamentoStatus.desconhecido;
    return ReuniaoProcessamentoStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => ReuniaoProcessamentoStatus.desconhecido,
    );
  }

  /// `true` enquanto o pipeline pode avançar sozinho em MINUTOS (item na fila
  /// de ATAs, que drena 1/min, ou ATA sendo gerada) → justifica polling.
  ///
  /// Os demais estados intermediários (reunião coletada, realizada, transcrição
  /// encontrada/baixada…) só avançam no processamento noturno (22h/23h) —
  /// mantê-los aqui fazia a tela chamar o backend a cada 8s indefinidamente.
  bool get isTransitorio => const {
        ReuniaoProcessamentoStatus.queuedForMinutesCreation,
        ReuniaoProcessamentoStatus.minutesProcessing,
      }.contains(this);
}
