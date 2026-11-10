import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';

/// Check-in do motorista lido do SAP
/// (`ZGJAAUTO_GENERIC_SRV/IN100_CHECKIN_MOTISTA`).
///
/// Entity separada de `CheckIn`: aquela mapeia outro entity set do mesmo
/// serviço (`Credat/Cretim/Chadat/...` + deep-expand `to_Items` com as chaves de
/// NF-e), consumido pela futura tela de consulta de check-in.
class CheckinMotorista extends Equatable {
  const CheckinMotorista({
    required this.checkin,
    required this.status,
    required this.motorista,
    required this.placa,
    required this.cpf,
    required this.tipo,
    required this.data,
    required this.hora,
  });

  /// Número do check-in. NUMC(10) no SAP, que devolve zero-padded
  /// (`'0000000009'`) — **sempre String**, um `int` perderia os zeros.
  final String checkin;

  final CheckinStatus status;
  final String motorista;
  final String placa;
  final String cpf;

  /// Último movimento registrado: `''` (nenhum), `'IN'` ou `'OUT'`.
  final String tipo;

  /// `yyyyMMdd` cru, como o SAP devolve.
  final String data;

  /// `HHmmss` cru, como o SAP devolve.
  final String hora;

  /// Desserializa o objeto de dentro do envelope OData V2 — o chamador passa
  /// `json['d']`.
  factory CheckinMotorista.fromJson(Map<String, dynamic> json) =>
      CheckinMotorista(
        checkin: _string(json['CHECKIN']),
        status: CheckinStatus.fromApi(json['STATUS'] as String?),
        motorista: _string(json['MOTORISTA']),
        placa: _string(json['PLACA']),
        cpf: _string(json['CPF']),
        tipo: _string(json['TIPO']),
        data: _string(json['DATA']),
        hora: _string(json['HORA']),
      );

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  /// `DATA` + `HORA` combinados. Nulo quando o SAP devolve campo vazio ou
  /// malformado — a UI cai no placeholder em vez de quebrar.
  DateTime? get dataHora {
    if (data.length != 8) return null;
    final ano = int.tryParse(data.substring(0, 4));
    final mes = int.tryParse(data.substring(4, 6));
    final dia = int.tryParse(data.substring(6, 8));
    if (ano == null || mes == null || dia == null) return null;

    var horas = 0;
    var minutos = 0;
    var segundos = 0;
    if (hora.length == 6) {
      horas = int.tryParse(hora.substring(0, 2)) ?? 0;
      minutos = int.tryParse(hora.substring(2, 4)) ?? 0;
      segundos = int.tryParse(hora.substring(4, 6)) ?? 0;
    }

    try {
      return DateTime(ano, mes, dia, horas, minutos, segundos);
    } catch (_) {
      return null;
    }
  }

  /// `dd/MM/yyyy HH:mm:ss`, ou `—` quando não há data utilizável.
  String get dataHoraFormatada {
    final dt = dataHora;
    if (dt == null) return '—';
    String p(int v) => v.toString().padLeft(2, '0');
    return '${p(dt.day)}/${p(dt.month)}/${dt.year} '
        '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';
  }

  /// `000.000.000-00`. Devolve o valor cru quando não tem 11 dígitos.
  String get cpfFormatado {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 11) return cpf.isEmpty ? '—' : cpf;
    return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}'
        '.${digitos.substring(6, 9)}-${digitos.substring(9)}';
  }

  @override
  List<Object?> get props =>
      [checkin, status, motorista, placa, cpf, tipo, data, hora];
}
