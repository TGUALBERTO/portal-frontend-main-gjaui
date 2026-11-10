import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'reuniao_processamento_status.dart';

/// Metadados da transcrição de uma reunião (NÃO traz o conteúdo).
class TranscricaoStatus extends Equatable {
  final int reuniaoId;
  final ReuniaoProcessamentoStatus status;
  final bool disponivel;
  final String? graphTranscriptId;
  final String? onlineMeetingId;
  final String? origem;
  final int? tamanhoBytes;
  final DateTime? capturadoEm;
  final String? erro;

  const TranscricaoStatus({
    required this.reuniaoId,
    required this.status,
    required this.disponivel,
    this.graphTranscriptId,
    this.onlineMeetingId,
    this.origem,
    this.tamanhoBytes,
    this.capturadoEm,
    this.erro,
  });

  factory TranscricaoStatus.fromJson(Map<String, dynamic> json) =>
      TranscricaoStatus(
        reuniaoId: (json['reuniaoId'] as num).toInt(),
        status: ReuniaoProcessamentoStatus.fromApi(json['status']?.toString()),
        disponivel: parseBool(json['disponivel']),
        graphTranscriptId: json['graphTranscriptId']?.toString(),
        onlineMeetingId: json['onlineMeetingId']?.toString(),
        origem: json['origem']?.toString(),
        tamanhoBytes: parseIntOrNull(json['tamanhoBytes']),
        capturadoEm: parseDateTime(json['capturadoEm']),
        erro: json['erro']?.toString(),
      );

  @override
  List<Object?> get props => [
        reuniaoId,
        status,
        disponivel,
        graphTranscriptId,
        onlineMeetingId,
        origem,
        tamanhoBytes,
        capturadoEm,
        erro,
      ];
}
