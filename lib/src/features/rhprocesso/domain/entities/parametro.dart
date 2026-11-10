/// Parâmetro geral do RH Processo (`RH_PROC.PARAMETRO`).
///
/// - ID 1: período (`yyyymm`) limite para usar a data de prestação de contas;
/// - ID 2: anos retroativos disponíveis na seleção de período;
/// - ID 3: período (`yyyymm`) limite da estrutura comercial;
/// - ID 4: dias retroativos da consulta ao backup de notas fiscais.
class Parametro {
  const Parametro({
    required this.id,
    required this.descricao,
    required this.valor,
  });

  factory Parametro.fromJson(Map<String, dynamic> json) => Parametro(
        id: (json['id'] as num?)?.toInt() ?? 0,
        descricao: json['descricao'] as String? ?? '',
        valor: (json['valor'] as num?)?.toInt() ?? 0,
      );

  final int id;
  final String descricao;
  final int valor;

  /// IDs 1 e 3 guardam um período `yyyymm`; o ID 2, um número de anos.
  bool get ehPeriodo => id == 1 || id == 3;

  /// Unidade dos parâmetros numéricos: o ID 4 é em dias; os demais, em anos.
  String get unidade => id == 4 ? 'dia(s)' : 'ano(s)';

  /// Mesma regra da API: período `yyyymm` com mês de 01 a 12, ou inteiro não
  /// negativo. Devolve a mensagem de erro, ou `null` se o valor é válido.
  String? validar(String texto) {
    final t = texto.trim();
    if (ehPeriodo) {
      final ok = RegExp(r'^\d{4}(0[1-9]|1[0-2])$').hasMatch(t);
      return ok ? null : 'Informe um período no formato yyyymm.';
    }
    final n = int.tryParse(t);
    return n != null && n >= 0 ? null : 'Informe um número inteiro não negativo.';
  }
}
