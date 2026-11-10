import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'ata_status.dart';
import 'index_status.dart';
import 'sharepoint_status.dart';

/// Detalhe completo de uma ATA (`GET /api/atas/{id}`).
class AtaDetalhe extends Equatable {
  final int id;
  final String transcriptId;
  final String meetingId;
  final String userId;
  final String assunto;
  final String organizador;
  final String joinUrl;
  final DateTime? inicio;
  final DateTime? fim;
  final String? empresa;
  final DateTime? dataReuniao;
  final List<String> participantes;
  final AtaStatus status;
  final IndexStatus indexStatus;

  /// Erro do último reprocessamento manual (nulo quando não houve falha).
  final String? erroProcessamento;
  final DateTime? erroProcessamentoEm;

  final int versaoAta;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String markdown;

  /// Custo de IA acumulado (US$): sanitização + geração + indexação.
  final double? custoUsd;

  // --- Publicação no SharePoint (.docx) ---
  final SharePointStatus sharepointStatus;

  /// URL do arquivo no SharePoint quando já enviado (nulo caso contrário).
  final String? sharepointWebUrl;
  final DateTime? sharepointEnviadoEm;
  final int sharepointTentativas;

  /// Motivo da última falha de envio (nulo quando não houve falha).
  final String? sharepointErro;

  const AtaDetalhe({
    required this.id,
    required this.transcriptId,
    required this.meetingId,
    required this.userId,
    required this.assunto,
    required this.organizador,
    required this.joinUrl,
    required this.participantes,
    required this.status,
    required this.indexStatus,
    required this.versaoAta,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.markdown,
    required this.sharepointStatus,
    required this.sharepointTentativas,
    this.inicio,
    this.fim,
    this.empresa,
    this.dataReuniao,
    this.erroProcessamento,
    this.erroProcessamentoEm,
    this.custoUsd,
    this.sharepointWebUrl,
    this.sharepointEnviadoEm,
    this.sharepointErro,
  });

  factory AtaDetalhe.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return AtaDetalhe(
      id: (json['id'] as num).toInt(),
      transcriptId: json['transcriptId']?.toString() ?? '',
      meetingId: json['meetingId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      assunto: json['assunto']?.toString() ?? '(sem assunto)',
      organizador: json['organizador']?.toString() ?? '',
      joinUrl: json['joinUrl']?.toString() ?? '',
      inicio: parseDateTime(json['inicio']),
      fim: parseDateTime(json['fim']),
      empresa: json['empresa']?.toString(),
      dataReuniao: parseDateOnly(json['dataReuniao']),
      participantes: parseStringList(json['participantes']),
      status: AtaStatus.fromApi(json['status']?.toString()),
      indexStatus: IndexStatus.fromApi(json['indexStatus']?.toString()),
      erroProcessamento: json['erroProcessamento']?.toString(),
      erroProcessamentoEm: parseDateTime(json['erroProcessamentoEm']),
      versaoAta: (json['versaoAta'] as num?)?.toInt() ?? 1,
      criadoEm: parseDateTime(json['criadoEm']) ?? now,
      atualizadoEm: parseDateTime(json['atualizadoEm']) ?? now,
      markdown: json['markdown']?.toString() ?? '',
      custoUsd: (json['custoUsd'] as num?)?.toDouble(),
      sharepointStatus:
          SharePointStatus.fromApi(json['sharepointStatus']?.toString()),
      sharepointWebUrl: json['sharepointWebUrl']?.toString(),
      sharepointEnviadoEm: parseDateTime(json['sharepointEnviadoEm']),
      sharepointTentativas: (json['sharepointTentativas'] as num?)?.toInt() ?? 0,
      sharepointErro: json['sharepointErro']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        transcriptId,
        meetingId,
        userId,
        assunto,
        organizador,
        joinUrl,
        inicio,
        fim,
        empresa,
        dataReuniao,
        participantes,
        status,
        indexStatus,
        erroProcessamento,
        erroProcessamentoEm,
        versaoAta,
        criadoEm,
        atualizadoEm,
        markdown,
        custoUsd,
        sharepointStatus,
        sharepointWebUrl,
        sharepointEnviadoEm,
        sharepointTentativas,
        sharepointErro,
      ];
}
