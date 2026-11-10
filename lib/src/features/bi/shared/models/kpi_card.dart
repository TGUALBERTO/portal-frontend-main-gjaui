import 'package:equatable/equatable.dart';

import 'json_utils.dart';

/// Cartão de KPI da faixa superior de um dashboard. O `valor` já vem formatado
/// do backend (ex.: "84,7%"); `tom` é neutral/success/warning/error.
class KpiCard extends Equatable {
  final String chave;
  final String rotulo;
  final String valor;
  final String? unidade;
  final String tom;

  const KpiCard({
    required this.chave,
    required this.rotulo,
    required this.valor,
    required this.tom,
    this.unidade,
  });

  factory KpiCard.fromJson(Map<String, dynamic> j) {
    final tom = parseStr(j['tom']);
    return KpiCard(
      chave: parseStr(j['chave']),
      rotulo: parseStr(j['rotulo']),
      valor: parseStr(j['valor']),
      unidade: j['unidade']?.toString(),
      tom: tom.isEmpty ? 'neutral' : tom,
    );
  }

  @override
  List<Object?> get props => [chave, rotulo, valor, unidade, tom];
}
