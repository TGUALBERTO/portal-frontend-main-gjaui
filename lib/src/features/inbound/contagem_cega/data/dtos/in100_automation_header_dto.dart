import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';

/// `IN100AutomationHeader` — o cabeçalho fiscal da NF-e.
///
/// Só é chamado pelo número da nota: `Serie` e `Mod` vêm de carona porque duas
/// notas de séries diferentes podem ter o mesmo `NNf` no mesmo check-in, e o
/// conferente precisa saber qual DANFE está na mão.
class In100AutomationHeaderDto {
  const In100AutomationHeaderDto({
    required this.chave,
    required this.accesskey,
    required this.numero,
    required this.serie,
    required this.modelo,
  });

  final String chave;
  final String accesskey;

  /// `NNf` — número da NF-e, CHAR(9), pode vir com zeros à esquerda.
  final String numero;

  final String serie;
  final String modelo;

  factory In100AutomationHeaderDto.fromJson(Map<String, dynamic> json) =>
      In100AutomationHeaderDto(
        chave: odataString(json['Chave']),
        accesskey: odataString(json['Accesskey']),
        numero: odataString(json['NNf']),
        serie: odataString(json['Serie']),
        modelo: odataString(json['Mod']),
      );

  /// Número sem os zeros à esquerda — é assim que o fornecedor imprime.
  String get numeroLabel {
    final semZeros = numero.replaceFirst(RegExp(r'^0+'), '');
    return semZeros.isEmpty ? numero : semZeros;
  }
}
