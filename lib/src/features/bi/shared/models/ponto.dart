import 'package:equatable/equatable.dart';

import 'json_utils.dart';

/// Par rótulo→valor, primitivo de gráficos (barras, rosca) e séries. Espelha os
/// records `PontoSerie` e `Fatia` do backend (mesmo shape JSON: rotulo/valor).
class Ponto extends Equatable {
  final String rotulo;
  final double valor;

  const Ponto({required this.rotulo, required this.valor});

  factory Ponto.fromJson(Map<String, dynamic> j) =>
      Ponto(rotulo: parseStr(j['rotulo']), valor: parseDouble(j['valor']));

  @override
  List<Object?> get props => [rotulo, valor];
}
