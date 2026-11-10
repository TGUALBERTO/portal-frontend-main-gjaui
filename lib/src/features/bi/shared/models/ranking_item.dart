import 'package:equatable/equatable.dart';

import 'json_utils.dart';

/// Item de um ranking (ex.: "Sistemas mais ofensores"). Espelha o record
/// `RankingItem` do backend.
class RankingItem extends Equatable {
  final int posicao;
  final String rotulo;
  final double valor;
  final double percentual;

  const RankingItem({
    required this.posicao,
    required this.rotulo,
    required this.valor,
    required this.percentual,
  });

  factory RankingItem.fromJson(Map<String, dynamic> j) => RankingItem(
        posicao: parseInt(j['posicao']),
        rotulo: parseStr(j['rotulo']),
        valor: parseDouble(j['valor']),
        percentual: parseDouble(j['percentual']),
      );

  @override
  List<Object?> get props => [posicao, rotulo, valor, percentual];
}
