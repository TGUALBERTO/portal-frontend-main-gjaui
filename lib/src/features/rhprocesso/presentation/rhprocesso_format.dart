import 'package:intl/intl.dart';

/// Formatação pt-BR das telas do RH Processo (moeda, CXU, datas).
abstract final class RhFormat {
  RhFormat._();

  static final NumberFormat _moeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  static final NumberFormat _dec2 = NumberFormat('#,##0.00', 'pt_BR');
  static final NumberFormat _dec5 = NumberFormat('#,##0.00###', 'pt_BR');
  static final NumberFormat _inteiro = NumberFormat.decimalPattern('pt_BR');
  static final DateFormat _data = DateFormat('dd/MM/yyyy');

  /// `R$ 1.234,56`.
  static String moeda(num v) => _moeda.format(v);

  /// Quantidade em caixas unitárias, duas casas (`1.234,50`).
  static String cxu(num v) => _dec2.format(v);

  /// Quantidade ou fator com até 5 casas, como a API calcula (`0,08333`).
  static String decimal(num v) => _dec5.format(v);

  static String inteiro(num v) => _inteiro.format(v);

  static String data(DateTime? d) => d == null ? '—' : _data.format(d);

  /// Texto vazio ou nulo vira travessão.
  static String texto(String? s) => s == null || s.trim().isEmpty ? '—' : s;
}
