import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/ata_status.dart';
import 'package:gjamobile/src/features/teamsbot/fila/data/models/fila_status.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'reuniao_processamento_status.dart';

/// Status consolidado da criação da ATA de uma reunião
/// (`GET /api/meeting-minutes/{meetingId}/status`).
class MeetingMinutesStatus extends Equatable {
  final int reuniaoId;
  final ReuniaoProcessamentoStatus statusProcessamento;
  final FilaStatus? statusFila;
  final int? ataId;
  final AtaStatus? statusAta;
  final String? erro;

  const MeetingMinutesStatus({
    required this.reuniaoId,
    required this.statusProcessamento,
    this.statusFila,
    this.ataId,
    this.statusAta,
    this.erro,
  });

  factory MeetingMinutesStatus.fromJson(Map<String, dynamic> json) {
    final statusFilaRaw = json['statusFila']?.toString();
    final statusAtaRaw = json['statusAta']?.toString();
    return MeetingMinutesStatus(
      reuniaoId: (json['reuniaoId'] as num).toInt(),
      statusProcessamento: ReuniaoProcessamentoStatus.fromApi(
          json['statusProcessamento']?.toString()),
      statusFila:
          statusFilaRaw == null ? null : FilaStatus.fromApi(statusFilaRaw),
      ataId: parseIntOrNull(json['ataId']),
      statusAta: statusAtaRaw == null ? null : AtaStatus.fromApi(statusAtaRaw),
      erro: json['erro']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [reuniaoId, statusProcessamento, statusFila, ataId, statusAta, erro];
}
