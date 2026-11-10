import 'package:equatable/equatable.dart';

import 'json_utils.dart';

/// Recomendação/insight determinístico. Espelha o record `Insight` do backend.
/// `severidade` é info/warning/critical.
class Insight extends Equatable {
  final String severidade;
  final String titulo;
  final String descricao;

  const Insight({
    required this.severidade,
    required this.titulo,
    required this.descricao,
  });

  factory Insight.fromJson(Map<String, dynamic> j) {
    final sev = parseStr(j['severidade']);
    return Insight(
      severidade: sev.isEmpty ? 'info' : sev,
      titulo: parseStr(j['titulo']),
      descricao: parseStr(j['descricao']),
    );
  }

  @override
  List<Object?> get props => [severidade, titulo, descricao];
}
