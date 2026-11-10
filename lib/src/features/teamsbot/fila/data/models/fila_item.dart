import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'fila_status.dart';

/// Item da fila FIFO de criação de ATAs.
class FilaItem extends Equatable {
  final int id;
  final int reuniaoId;
  final String? transcriptId;
  final FilaStatus status;
  final int? ataId;
  final int tentativas;
  final String? erro;
  final DateTime? criadoEm;
  final DateTime? iniciadoEm;
  final DateTime? concluidoEm;

  const FilaItem({
    required this.id,
    required this.reuniaoId,
    required this.status,
    required this.tentativas,
    this.transcriptId,
    this.ataId,
    this.erro,
    this.criadoEm,
    this.iniciadoEm,
    this.concluidoEm,
  });

  factory FilaItem.fromJson(Map<String, dynamic> json) => FilaItem(
        id: (json['id'] as num).toInt(),
        reuniaoId: (json['reuniaoId'] as num).toInt(),
        transcriptId: json['transcriptId']?.toString(),
        status: FilaStatus.fromApi(json['status']?.toString()),
        ataId: parseIntOrNull(json['ataId']),
        tentativas: parseIntOrNull(json['tentativas']) ?? 0,
        erro: json['erro']?.toString(),
        criadoEm: parseDateTime(json['criadoEm']),
        iniciadoEm: parseDateTime(json['iniciadoEm']),
        concluidoEm: parseDateTime(json['concluidoEm']),
      );

  @override
  List<Object?> get props => [
        id,
        reuniaoId,
        transcriptId,
        status,
        ataId,
        tentativas,
        erro,
        criadoEm,
        iniciadoEm,
        concluidoEm,
      ];
}
