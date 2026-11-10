import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/ata_status.dart';
import 'package:gjamobile/src/features/teamsbot/fila/data/models/fila_status.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'reuniao_processamento_status.dart';

/// Item da listagem de reuniões monitoradas (`GET /api/meetings/monitored`).
class MonitoredMeetingResumo extends Equatable {
  final int id;
  final String? assunto;
  final String? organizador;
  final DateTime? inicio;
  final DateTime? fim;
  final bool online;
  final int totalParticipantes;
  final ReuniaoProcessamentoStatus statusProcessamento;
  final bool temTranscricao;
  final FilaStatus? statusFila;
  final int? ataId;
  final AtaStatus? statusAta;
  final DateTime? criadoEm;

  const MonitoredMeetingResumo({
    required this.id,
    required this.online,
    required this.totalParticipantes,
    required this.statusProcessamento,
    required this.temTranscricao,
    this.assunto,
    this.organizador,
    this.inicio,
    this.fim,
    this.statusFila,
    this.ataId,
    this.statusAta,
    this.criadoEm,
  });

  factory MonitoredMeetingResumo.fromJson(Map<String, dynamic> json) {
    final statusAtaRaw = json['statusAta']?.toString();
    final statusFilaRaw = json['statusFila']?.toString();
    return MonitoredMeetingResumo(
      id: (json['id'] as num).toInt(),
      assunto: json['assunto']?.toString(),
      organizador: json['organizador']?.toString(),
      inicio: parseDateTime(json['inicio']),
      fim: parseDateTime(json['fim']),
      online: parseBool(json['online']),
      totalParticipantes: parseIntOrNull(json['totalParticipantes']) ?? 0,
      statusProcessamento: ReuniaoProcessamentoStatus.fromApi(
          json['statusProcessamento']?.toString()),
      temTranscricao: parseBool(json['temTranscricao']),
      statusFila:
          statusFilaRaw == null ? null : FilaStatus.fromApi(statusFilaRaw),
      ataId: parseIntOrNull(json['ataId']),
      statusAta: statusAtaRaw == null ? null : AtaStatus.fromApi(statusAtaRaw),
      criadoEm: parseDateTime(json['criadoEm']),
    );
  }

  /// `true` enquanto o pipeline ainda pode avançar → justifica auto-refresh.
  bool get emAndamento =>
      statusProcessamento.isTransitorio || (statusFila?.isTransitorio ?? false);

  @override
  List<Object?> get props => [
        id,
        assunto,
        organizador,
        inicio,
        fim,
        online,
        totalParticipantes,
        statusProcessamento,
        temTranscricao,
        statusFila,
        ataId,
        statusAta,
        criadoEm,
      ];
}
