import 'package:intl/intl.dart';

/// Formatação de datas em português do Brasil para as telas da feature TeamsBot.
///
/// Os locales são inicializados em `main.dart` via `initializeDateFormatting`.
abstract final class AtaFormat {
  AtaFormat._();

  static final DateFormat _curto = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _extenso = DateFormat("dd 'de' MMMM 'de' y", 'pt_BR');
  static final DateFormat _dataHora =
      DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
  static final DateFormat _hora = DateFormat('HH:mm', 'pt_BR');
  static final NumberFormat _moeda =
      NumberFormat.currency(locale: 'en_US', symbol: r'US$', decimalDigits: 4);
  static final NumberFormat _inteiro = NumberFormat.decimalPattern('pt_BR');

  /// `10/06/2026` ou `—` quando nulo.
  static String data(DateTime? d) => d == null ? '—' : _curto.format(d);

  /// `10 de junho de 2026`.
  static String dataExtensa(DateTime? d) => d == null ? '—' : _extenso.format(d);

  /// `10/06/2026 às 14:00`.
  static String dataHora(DateTime? d) => d == null ? '—' : _dataHora.format(d);

  /// `14:00`.
  static String hora(DateTime? d) => d == null ? '—' : _hora.format(d);

  /// Formata uma data ISO (`"2026-06-10"`) recebida como String.
  static String dataIso(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    return parsed == null ? iso : _curto.format(parsed);
  }

  /// Custo em US$ com 4 casas (`US$0.0123`) ou `—` quando nulo.
  static String custo(double? usd) => usd == null ? '—' : _moeda.format(usd);

  /// Inteiro com separador de milhar (`1.234`).
  static String inteiro(num? value) =>
      value == null ? '—' : _inteiro.format(value);
}
