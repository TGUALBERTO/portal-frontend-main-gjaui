import '../../../shared/models/models.dart';

/// Resposta completa (BFF) do painel de Capacity — espelha
/// `CapacityDashboardResponse` (`GET /dashboards/capacity`).
class CapacityDashboard {
  const CapacityDashboard({
    required this.cards,
    required this.horasPorSquad,
    required this.horasPorTecnico,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<Ponto> horasPorSquad;
  final List<Ponto> horasPorTecnico;
  final List<Insight> insights;

  factory CapacityDashboard.fromJson(Map<String, dynamic> j) => CapacityDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        horasPorSquad: parseList(j['horasPorSquad'], Ponto.fromJson),
        horasPorTecnico: parseList(j['horasPorTecnico'], Ponto.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
