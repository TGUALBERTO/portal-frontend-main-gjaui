import 'package:equatable/equatable.dart';

/// Período mensal no formato da API (`yyyymm`).
class Periodo extends Equatable {
  const Periodo(this.valor);

  /// `GET /api/v1/periodos` → `{periodo, ano, mes}`.
  factory Periodo.fromJson(Map<String, dynamic> json) =>
      Periodo(json['periodo'] as String? ?? '');

  /// `yyyymm`, como vai na query string (`?periodo=202609`).
  final String valor;

  bool get valido => RegExp(r'^\d{6}$').hasMatch(valor);

  /// `09/2026`. Um valor fora do formato aparece como veio.
  String get rotulo =>
      valido ? '${valor.substring(4)}/${valor.substring(0, 4)}' : valor;

  @override
  List<Object?> get props => [valor];
}
