import '../../../shared/models/models.dart';

/// Linha da tabela "Backlog por Empresa e Prioridade" (Alta/Média/Baixa + Total).
/// Espelha o record `LinhaBacklogPrioridade` do backend.
class LinhaBacklogPrioridade {
  const LinhaBacklogPrioridade({
    required this.empresa,
    required this.alta,
    required this.media,
    required this.baixa,
    required this.total,
  });

  final String empresa;
  final int alta;
  final int media;
  final int baixa;
  final int total;

  factory LinhaBacklogPrioridade.fromJson(Map<String, dynamic> j) =>
      LinhaBacklogPrioridade(
        empresa: parseStr(j['empresa']),
        alta: parseInt(j['alta']),
        media: parseInt(j['media']),
        baixa: parseInt(j['baixa']),
        total: parseInt(j['total']),
      );
}

/// Resposta completa (BFF) do painel "SLA e Backlog" — espelha
/// `SlaBacklogDashboardResponse` (`GET /dashboards/sla-backlog`, Grafico3.png).
class SlaBacklogDashboard {
  const SlaBacklogDashboard({
    required this.cards,
    required this.evolucaoSla,
    required this.backlogPorFaixaAging,
    required this.slaPorTipo,
    required this.backlogPorEmpresaPrioridade,
    required this.ofensores,
    required this.semMovimentacao,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<Serie> evolucaoSla;
  final List<Ponto> backlogPorFaixaAging;
  final List<Ponto> slaPorTipo;
  final List<LinhaBacklogPrioridade> backlogPorEmpresaPrioridade;
  final List<RankingItem> ofensores;
  final List<Ponto> semMovimentacao;
  final List<Insight> insights;

  factory SlaBacklogDashboard.fromJson(Map<String, dynamic> j) =>
      SlaBacklogDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        evolucaoSla: parseList(j['evolucaoSla'], Serie.fromJson),
        backlogPorFaixaAging:
            parseList(j['backlogPorFaixaAging'], Ponto.fromJson),
        slaPorTipo: parseList(j['slaPorTipo'], Ponto.fromJson),
        backlogPorEmpresaPrioridade: parseList(
            j['backlogPorEmpresaPrioridade'], LinhaBacklogPrioridade.fromJson),
        ofensores: parseList(j['ofensores'], RankingItem.fromJson),
        semMovimentacao: parseList(j['semMovimentacao'], Ponto.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
