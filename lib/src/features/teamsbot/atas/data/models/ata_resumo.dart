import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'ata_status.dart';
import 'index_status.dart';
import 'sharepoint_status.dart';

/// Item da listagem de ATAs (`GET /api/atas`).
class AtaResumo extends Equatable {
  final int id;
  final String transcriptId;
  final String meetingId;
  final String assunto;
  final AtaStatus status;
  final IndexStatus indexStatus;
  final SharePointStatus sharepointStatus;
  final DateTime? dataReuniao;
  final int versaoAta;
  final DateTime criadoEm;

  /// Custo de IA acumulado (US$). Pode vir `null` enquanto não há geração.
  final double? custoUsd;

  const AtaResumo({
    required this.id,
    required this.transcriptId,
    required this.meetingId,
    required this.assunto,
    required this.status,
    required this.indexStatus,
    required this.sharepointStatus,
    required this.versaoAta,
    required this.criadoEm,
    this.dataReuniao,
    this.custoUsd,
  });

  factory AtaResumo.fromJson(Map<String, dynamic> json) {
    return AtaResumo(
      id: (json['id'] as num).toInt(),
      transcriptId: json['transcriptId']?.toString() ?? '',
      meetingId: json['meetingId']?.toString() ?? '',
      assunto: json['assunto']?.toString() ?? '(sem assunto)',
      status: AtaStatus.fromApi(json['status']?.toString()),
      indexStatus: IndexStatus.fromApi(json['indexStatus']?.toString()),
      sharepointStatus:
          SharePointStatus.fromApi(json['sharepointStatus']?.toString()),
      dataReuniao: parseDateOnly(json['dataReuniao']),
      versaoAta: (json['versaoAta'] as num?)?.toInt() ?? 1,
      criadoEm: parseDateTime(json['criadoEm']) ?? DateTime.now(),
      custoUsd: (json['custoUsd'] as num?)?.toDouble(),
    );
  }

  /// `true` enquanto a indexação desta ATA ainda pode mudar sozinha.
  bool get indexEmAndamento => indexStatus.isTransitorio;

  @override
  List<Object?> get props => [
        id,
        transcriptId,
        meetingId,
        assunto,
        status,
        indexStatus,
        sharepointStatus,
        dataReuniao,
        versaoAta,
        criadoEm,
        custoUsd,
      ];
}
