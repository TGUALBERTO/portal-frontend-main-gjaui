import 'package:equatable/equatable.dart';

/// Ponto diário do funcionário — primeira e última marcação do relógio de
/// ponto no dia, agregadas no backend a partir de `NEWPONTO.I9MARCACOESPONTO`
/// e retornadas por `GET /pontos/search/findByMatriculaAndDataBetween` (HAL).
class PontoDia extends Equatable {
  final String matricula;

  /// Dia da marcação (sem componente de hora).
  final DateTime data;

  /// Primeira marcação do dia (dia + hora).
  final DateTime entrada;

  /// Última marcação do dia (dia + hora); nula quando o dia tem uma única
  /// marcação (jornada ainda aberta ou uma só batida).
  final DateTime? saida;

  const PontoDia({
    required this.matricula,
    required this.data,
    required this.entrada,
    required this.saida,
  });

  factory PontoDia.fromJson(Map<String, dynamic> json) {
    // `data` vem como ISO date ('2026-06-29') e as horas como 'HH:mm:ss'.
    final day = DateTime.parse(json['data'] as String);
    final entrada = _atDay(day, json['entrada'] as String?);
    if (entrada == null) {
      throw const FormatException('PontoDia sem hora de entrada');
    }
    return PontoDia(
      matricula: (json['matricula'] as String?) ?? '',
      data: DateTime(day.year, day.month, day.day),
      entrada: entrada,
      saida: _atDay(day, json['saida'] as String?),
    );
  }

  /// Combina o dia com uma hora `HH:mm[:ss]` do backend.
  static DateTime? _atDay(DateTime day, String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      parts.length > 1 ? int.parse(parts[1]) : 0,
      parts.length > 2 ? int.parse(parts[2].split('.').first) : 0,
    );
  }

  @override
  List<Object?> get props => [matricula, data, entrada, saida];
}
