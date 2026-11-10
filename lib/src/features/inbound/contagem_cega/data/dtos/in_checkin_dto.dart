import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';

/// `INCheckin` do serviço `ZGJAAUTO_SB_GENERIC`, com `$expand=to_Items`.
///
/// É o cabeçalho do check-in mais a lista de NF-es que vieram no caminhão — a
/// única navegação útil do serviço, e o que permite abrir a contagem com **uma**
/// chamada em vez de duas.
class InCheckinDto {
  const InCheckinDto({
    required this.checkin,
    required this.status,
    required this.motorista,
    required this.cpf,
    required this.placa,
    required this.itens,
  });

  /// NUMC(10) zero-padded, como o SAP devolve (`'0000000003'`).
  final String checkin;

  /// CHAR(1) — ver `CheckinStatus`.
  final String status;

  final String motorista;
  final String cpf;
  final String placa;
  final List<InCheckinItemDto> itens;

  factory InCheckinDto.fromJson(Map<String, dynamic> json) => InCheckinDto(
        checkin: odataString(json['Checkin']),
        status: odataString(json['Status']),
        motorista: odataString(json['Motorista']),
        cpf: odataString(json['Cpf']),
        placa: odataString(json['Placa']),
        itens: odataChildren(json['to_Items'])
            .map(InCheckinItemDto.fromJson)
            .toList(growable: false),
      );
}

/// `INCheckinItems` — a NF-e vinculada ao check-in.
///
/// Traz só as chaves e um status; nada exibível. Todo o resto (número da nota,
/// fornecedor, itens) vem de outros entity sets, cruzados pelo par
/// `(Chave, Accesskey)`.
class InCheckinItemDto {
  const InCheckinItemDto({
    required this.checkin,
    required this.chave,
    required this.accesskey,
    required this.status,
  });

  final String checkin;
  final String chave;
  final String accesskey;
  final String status;

  factory InCheckinItemDto.fromJson(Map<String, dynamic> json) =>
      InCheckinItemDto(
        checkin: odataString(json['Checkin']),
        chave: odataString(json['Chave']),
        accesskey: odataString(json['Accesskey']),
        status: odataString(json['Status']),
      );
}
