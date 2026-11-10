import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/teamsbot/shared/json_utils.dart';

import 'fonte.dart';

/// Resposta sintetizada do RAG (`POST /api/atas/consultar`).
class RagResposta extends Equatable {
  final String resposta;
  final List<Fonte> fontes;
  final List<String> responsaveis;
  final List<String> pontosAConfirmar;

  const RagResposta({
    required this.resposta,
    required this.fontes,
    required this.responsaveis,
    required this.pontosAConfirmar,
  });

  factory RagResposta.fromJson(Map<String, dynamic> json) {
    final rawFontes = (json['fontes'] as List<dynamic>?) ?? const [];
    final fontes = rawFontes
        .map((e) => Fonte.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return RagResposta(
      resposta: json['resposta']?.toString() ?? '',
      fontes: fontes,
      responsaveis: parseStringList(json['responsaveis']),
      pontosAConfirmar: parseStringList(json['pontosAConfirmar']),
    );
  }

  @override
  List<Object?> get props => [resposta, fontes, responsaveis, pontosAConfirmar];
}
