import '../../../shared/models/models.dart';

/// Linha da tabela "SLA por Empresa" (painel 4 do executivo).
class LinhaSlaEmpresa {
  const LinhaSlaEmpresa({
    required this.empresa,
    required this.slaGeral,
    required this.slaIncidentes,
    required this.slaRequisicoes,
  });

  final String empresa;
  final double slaGeral;
  final double slaIncidentes;
  final double slaRequisicoes;

  factory LinhaSlaEmpresa.fromJson(Map<String, dynamic> j) => LinhaSlaEmpresa(
        empresa: parseStr(j['empresa']),
        slaGeral: parseDouble(j['slaGeral']),
        slaIncidentes: parseDouble(j['slaIncidentes']),
        slaRequisicoes: parseDouble(j['slaRequisicoes']),
      );
}

/// Resposta completa (BFF) do dashboard executivo — espelha
/// `ExecutiveDashboardResponse` do backend.
class ExecutiveDashboard {
  const ExecutiveDashboard({
    required this.cards,
    required this.tendencia,
    required this.volumePorEmpresa,
    required this.tiposDemanda,
    required this.slaPorEmpresa,
    required this.ofensores,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<Serie> tendencia;
  final List<Ponto> volumePorEmpresa;
  final List<Ponto> tiposDemanda;
  final List<LinhaSlaEmpresa> slaPorEmpresa;
  final List<RankingItem> ofensores;
  final List<Insight> insights;

  factory ExecutiveDashboard.fromJson(Map<String, dynamic> j) =>
      ExecutiveDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        tendencia: parseList(j['tendencia'], Serie.fromJson),
        volumePorEmpresa: parseList(j['volumePorEmpresa'], Ponto.fromJson),
        tiposDemanda: parseList(j['tiposDemanda'], Ponto.fromJson),
        slaPorEmpresa: parseList(j['slaPorEmpresa'], LinhaSlaEmpresa.fromJson),
        ofensores: parseList(j['ofensores'], RankingItem.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
