import 'package:intl/intl.dart';

/// Formatação numérica pt-BR compartilhada pelos dashboards do BI (milhar,
/// decimal, percentual, dias, horas). O `intl` já é inicializado em `main`
/// (`initializeDateFormatting('pt_BR')`). Espelha o `BiFormato` do backend, mas
/// aqui só para valores que a tela precisa compor localmente (rótulos de eixo,
/// células de tabela) — KPIs já vêm formatados do BFF.
abstract final class BiFormat {
  BiFormat._();

  static final NumberFormat _milhar = NumberFormat.decimalPattern('pt_BR');
  static final NumberFormat _dec2 = NumberFormat('#,##0.00', 'pt_BR');

  /// Inteiro com separador de milhar (ex.: `1248` → `"1.248"`).
  static String inteiro(num v) => _milhar.format(v.round());

  /// Duas casas decimais (ex.: `18.4` → `"18,40"`).
  static String decimal(num v) => _dec2.format(v);

  /// Percentual com duas casas (ex.: `84.73` → `"84,73%"`).
  static String pct(num v) => '${_dec2.format(v)}%';

  /// Dias com duas casas (ex.: `18.4` → `"18,40 dias"`).
  static String dias(num v) => '${_dec2.format(v)} dias';

  /// Horas inteiras com milhar (ex.: `6487` → `"6.487 h"`).
  static String horas(num v) => '${_milhar.format(v.round())} h';

  /// Valor de ranking/contagem: inteiro quando redondo, senão uma casa.
  static String contagem(num v) =>
      v == v.roundToDouble() ? inteiro(v) : decimal(v);
}
