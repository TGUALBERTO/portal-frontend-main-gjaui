import '../../../shared/models/models.dart';

/// Resposta completa (BFF) do painel "Visão SAP e Multiplataforma" — espelha
/// `SapDashboardResponse` (`GET /dashboards/sap-multiplataforma`, Grafico4.png).
class SapDashboard {
  const SapDashboard({
    required this.cards,
    required this.chamadosPorSistemaSap,
    required this.chamadosPorMultiplataforma,
    required this.slaPorSistema,
    required this.ofensores,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<Ponto> chamadosPorSistemaSap;
  final List<Ponto> chamadosPorMultiplataforma;
  final List<Ponto> slaPorSistema;
  final List<RankingItem> ofensores;
  final List<Insight> insights;

  factory SapDashboard.fromJson(Map<String, dynamic> j) => SapDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        chamadosPorSistemaSap:
            parseList(j['chamadosPorSistemaSap'], Ponto.fromJson),
        chamadosPorMultiplataforma:
            parseList(j['chamadosPorMultiplataforma'], Ponto.fromJson),
        slaPorSistema: parseList(j['slaPorSistema'], Ponto.fromJson),
        ofensores: parseList(j['ofensores'], RankingItem.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
