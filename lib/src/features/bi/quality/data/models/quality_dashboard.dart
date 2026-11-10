import '../../../shared/models/models.dart';

/// Resposta completa (BFF) do painel de Qualidade — espelha
/// `QualityDashboardResponse` (`GET /dashboards/quality`).
class QualityDashboard {
  const QualityDashboard({
    required this.cards,
    required this.slaPorTipo,
    required this.backlogPorFaixaAging,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<Ponto> slaPorTipo;
  final List<Ponto> backlogPorFaixaAging;
  final List<Insight> insights;

  factory QualityDashboard.fromJson(Map<String, dynamic> j) => QualityDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        slaPorTipo: parseList(j['slaPorTipo'], Ponto.fromJson),
        backlogPorFaixaAging:
            parseList(j['backlogPorFaixaAging'], Ponto.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
