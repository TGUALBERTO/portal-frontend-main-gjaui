import 'package:equatable/equatable.dart';

/// Trecho de ATA citado como fonte de uma resposta do RAG.
class Fonte extends Equatable {
  final int ataId;
  final String tituloReuniao;
  final String dataReuniao;
  final String secao;
  final String trecho;
  final double score;
  final String linkAta;

  const Fonte({
    required this.ataId,
    required this.tituloReuniao,
    required this.dataReuniao,
    required this.secao,
    required this.trecho,
    required this.score,
    required this.linkAta,
  });

  factory Fonte.fromJson(Map<String, dynamic> json) {
    return Fonte(
      ataId: (json['ataId'] as num).toInt(),
      tituloReuniao: json['tituloReuniao']?.toString() ?? '',
      dataReuniao: json['dataReuniao']?.toString() ?? '',
      secao: json['secao']?.toString() ?? '',
      trecho: json['trecho']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      linkAta: json['linkAta']?.toString() ?? '',
    );
  }

  /// Score como percentual (0–100) para exibição.
  int get scorePercent => (score.clamp(0, 1) * 100).round();

  @override
  List<Object?> get props =>
      [ataId, tituloReuniao, dataReuniao, secao, trecho, score, linkAta];
}
