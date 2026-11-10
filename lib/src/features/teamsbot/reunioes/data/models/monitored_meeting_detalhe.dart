import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/ata_status.dart';
import 'package:gjamobile/src/features/teamsbot/fila/data/models/fila_item.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'participante.dart';
import 'reuniao_processamento_status.dart';
import 'transcricao_status.dart';

/// Detalhe de uma reunião monitorada (`GET /api/meetings/monitored/{id}`).
class MonitoredMeetingDetalhe extends Equatable {
  final int id;
  final String icalUid;
  final String? assunto;
  final String? organizador;
  final DateTime? inicio;
  final DateTime? fim;
  final bool online;
  final String? joinUrl;
  final List<Participante> participantes;
  final ReuniaoProcessamentoStatus statusProcessamento;
  final String? erroProcessamento;
  final int tentativasProcessamento;
  final DateTime? processadoEm;
  final TranscricaoStatus? transcricao;
  final FilaItem? fila;
  final int? ataId;
  final AtaStatus? statusAta;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  const MonitoredMeetingDetalhe({
    required this.id,
    required this.icalUid,
    required this.online,
    required this.participantes,
    required this.statusProcessamento,
    required this.tentativasProcessamento,
    this.assunto,
    this.organizador,
    this.inicio,
    this.fim,
    this.joinUrl,
    this.erroProcessamento,
    this.processadoEm,
    this.transcricao,
    this.fila,
    this.ataId,
    this.statusAta,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory MonitoredMeetingDetalhe.fromJson(Map<String, dynamic> json) {
    final participantesRaw =
        (json['participantes'] as List<dynamic>?) ?? const [];
    final statusAtaRaw = json['statusAta']?.toString();
    final transcricao = json['transcricao'];
    final fila = json['fila'];
    return MonitoredMeetingDetalhe(
      id: (json['id'] as num).toInt(),
      icalUid: json['icalUid']?.toString() ?? '',
      assunto: json['assunto']?.toString(),
      organizador: json['organizador']?.toString(),
      inicio: parseDateTime(json['inicio']),
      fim: parseDateTime(json['fim']),
      online: parseBool(json['online']),
      joinUrl: json['joinUrl']?.toString(),
      participantes: participantesRaw
          .map((e) => Participante.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusProcessamento: ReuniaoProcessamentoStatus.fromApi(
          json['statusProcessamento']?.toString()),
      erroProcessamento: json['erroProcessamento']?.toString(),
      tentativasProcessamento:
          parseIntOrNull(json['tentativasProcessamento']) ?? 0,
      processadoEm: parseDateTime(json['processadoEm']),
      transcricao: transcricao is Map
          ? TranscricaoStatus.fromJson(transcricao.cast<String, dynamic>())
          : null,
      fila: fila is Map ? FilaItem.fromJson(fila.cast<String, dynamic>()) : null,
      ataId: parseIntOrNull(json['ataId']),
      statusAta: statusAtaRaw == null ? null : AtaStatus.fromApi(statusAtaRaw),
      criadoEm: parseDateTime(json['criadoEm']),
      atualizadoEm: parseDateTime(json['atualizadoEm']),
    );
  }

  bool get emAndamento =>
      statusProcessamento.isTransitorio ||
      (fila?.status.isTransitorio ?? false);

  @override
  List<Object?> get props => [
        id,
        icalUid,
        assunto,
        organizador,
        inicio,
        fim,
        online,
        joinUrl,
        participantes,
        statusProcessamento,
        erroProcessamento,
        tentativasProcessamento,
        processadoEm,
        transcricao,
        fila,
        ataId,
        statusAta,
        criadoEm,
        atualizadoEm,
      ];
}
