import 'package:equatable/equatable.dart';

/// Referência leve a uma fonte usada numa consulta do histórico
/// (a ATA pode ser aberta pelo [ataId]).
class ConsultaHistoricoFonte extends Equatable {
  final int? ataId;
  final String secao;
  final double? score;

  const ConsultaHistoricoFonte({
    required this.ataId,
    required this.secao,
    required this.score,
  });

  factory ConsultaHistoricoFonte.fromJson(Map<String, dynamic> json) {
    return ConsultaHistoricoFonte(
      ataId: (json['ataId'] as num?)?.toInt(),
      secao: json['secao']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [ataId, secao, score];
}

/// Item do histórico de consultas RAG do usuário (`GET /api/atas/consultas`).
class ConsultaHistoricoItem extends Equatable {
  final int id;
  final String pergunta;
  final String resposta;
  final List<ConsultaHistoricoFonte> fontes;
  final Map<String, dynamic> filtros;
  final DateTime? criadoEm;

  const ConsultaHistoricoItem({
    required this.id,
    required this.pergunta,
    required this.resposta,
    required this.fontes,
    required this.filtros,
    required this.criadoEm,
  });

  factory ConsultaHistoricoItem.fromJson(Map<String, dynamic> json) {
    return ConsultaHistoricoItem(
      id: (json['id'] as num).toInt(),
      pergunta: json['pergunta']?.toString() ?? '',
      resposta: json['resposta']?.toString() ?? '',
      fontes: (json['fontes'] as List<dynamic>? ?? const [])
          .map((e) => ConsultaHistoricoFonte.fromJson(e as Map<String, dynamic>))
          .toList(),
      filtros: (json['filtros'] as Map<String, dynamic>?) ?? const {},
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? '')?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, pergunta, resposta, fontes, filtros, criadoEm];
}
