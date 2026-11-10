import 'package:intl/intl.dart';

/// Formatacao das colunas da tela de integracoes, em pt-BR.
///
/// Separado do `AtaFormat` (TeamsBot) porque precisa de duracao — que la nao
/// existe — e porque um formatador com nome de outra feature confunde.
abstract final class IntegracaoFormat {
  IntegracaoFormat._();

  static final DateFormat _dataHora = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
  static final DateFormat _dataHoraCompacta = DateFormat('dd/MM HH:mm', 'pt_BR');
  static final NumberFormat _inteiro = NumberFormat.decimalPattern('pt_BR');

  /// `10/06/2026 às 14:00`, ou travessao quando nao houve execucao.
  static String dataHora(DateTime? d) => d == null ? '—' : _dataHora.format(d);

  /// `10/06 14:00` — versao curta para a tabela, onde a forma completa ocupa
  /// mais de 200px por coluna e empurra a coluna de acoes para fora da tela.
  /// O valor completo continua disponivel no tooltip.
  static String dataHoraCompacta(DateTime? d) =>
      d == null ? '—' : _dataHoraCompacta.format(d);

  /// Inteiro com separador de milhar.
  static String inteiro(num? valor) =>
      valor == null ? '—' : _inteiro.format(valor);

  /// Duracao legivel: `820 ms`, `47 s`, `12 min 30 s`, `2 h 05 min`.
  ///
  /// Uma carga completa leva dezenas de minutos e um delta some em
  /// milissegundos — mostrar tudo em segundos deixaria as duas pontas ilegiveis.
  static String duracao(int? milissegundos) {
    if (milissegundos == null || milissegundos < 0) return '—';
    if (milissegundos < 1000) return '$milissegundos ms';

    final totalSegundos = milissegundos ~/ 1000;
    if (totalSegundos < 60) return '$totalSegundos s';

    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    if (minutos < 60) {
      return segundos == 0 ? '$minutos min' : '$minutos min $segundos s';
    }

    final horas = minutos ~/ 60;
    final restoMinutos = minutos % 60;
    return '$horas h ${restoMinutos.toString().padLeft(2, '0')} min';
  }

  /// Resumo dos contadores de uma execucao, ex.: `1.204 (+30 ~1.174)`.
  static String registros({
    required int processados,
    required int inseridos,
    required int atualizados,
  }) {
    if (processados == 0) return '0';
    // Rotinas que nao detalham o upsert reportam tudo como inserido; mostrar
    // "+N ~0" nesses casos sugeriria um detalhe que o backend nao tem.
    if (atualizados == 0) return inteiro(processados);
    return '${inteiro(processados)} (+${inteiro(inseridos)} ~${inteiro(atualizados)})';
  }
}
