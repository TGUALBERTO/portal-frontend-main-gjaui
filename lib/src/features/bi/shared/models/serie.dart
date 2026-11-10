import 'package:equatable/equatable.dart';

import 'json_utils.dart';
import 'ponto.dart';

/// Série nomeada de um gráfico de linhas/barras (ex.: "Abertos", "Fechados").
/// Espelha o record `Serie` do backend.
class Serie extends Equatable {
  final String nome;
  final List<Ponto> pontos;

  const Serie({required this.nome, required this.pontos});

  factory Serie.fromJson(Map<String, dynamic> j) => Serie(
        nome: parseStr(j['nome']),
        pontos: parseList(j['pontos'], Ponto.fromJson),
      );

  @override
  List<Object?> get props => [nome, pontos];
}
