import 'json_utils.dart';

/// Opção de um seletor de filtro (empresa/squad). Espelha o record `FiltroOpcao`
/// do backend: id que vai no `DashboardFilter` + rótulo de exibição.
class FiltroOpcao {
  const FiltroOpcao({required this.id, required this.nome});

  final int id;
  final String nome;

  factory FiltroOpcao.fromJson(Map<String, dynamic> j) =>
      FiltroOpcao(id: parseInt(j['id']), nome: parseStr(j['nome']));
}

/// Dados de referência da barra de filtros (`GET /dashboards/filtros`). Espelha
/// `FiltrosReferencia` do backend. Empresas são NOMES normalizados (distintos) —
/// o filtro usa o nome, que agrupa todos os ids com o mesmo rótulo. Squads só se
/// aplicam aos dashboards de tarefa (Time/Capacity).
class FiltrosReferencia {
  const FiltrosReferencia({required this.empresas, required this.squads});

  final List<String> empresas;
  final List<FiltroOpcao> squads;

  factory FiltrosReferencia.fromJson(Map<String, dynamic> j) => FiltrosReferencia(
        // Tolerante às duas formas de contrato: lista de nomes ("empresa") ou
        // lista de objetos {id, nome} (versão antiga do backend) — evita o
        // seletor sumir num deploy parcial. Dedup preserva a ordem.
        empresas: _nomes(j['empresas']),
        squads: parseList(j['squads'], FiltroOpcao.fromJson),
      );

  static List<String> _nomes(dynamic v) {
    if (v is! List) return const [];
    final vistos = <String>{};
    final out = <String>[];
    for (final e in v) {
      final nome = e is Map ? parseStr(e['nome']) : e.toString();
      if (nome.isNotEmpty && vistos.add(nome)) out.add(nome);
    }
    return out;
  }
}
