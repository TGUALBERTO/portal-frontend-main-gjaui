import '../../../shared/models/models.dart';

/// Resposta (BFF) dos painéis por tipo de chamado — Incidentes, Requisições e
/// Mudanças (mesma forma de contrato). Espelha `TipoChamadoDashboardResponse` e
/// `ChangeDashboardResponse` do backend.
class TipoChamadoDashboard {
  const TipoChamadoDashboard({
    required this.cards,
    required this.tendencia,
    required this.porEmpresa,
    required this.porPrioridade,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<Serie> tendencia;
  final List<Ponto> porEmpresa;
  final List<Ponto> porPrioridade;
  final List<Insight> insights;

  factory TipoChamadoDashboard.fromJson(Map<String, dynamic> j) =>
      TipoChamadoDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        tendencia: parseList(j['tendencia'], Serie.fromJson),
        porEmpresa: parseList(j['porEmpresa'], Ponto.fromJson),
        porPrioridade: parseList(j['porPrioridade'], Ponto.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
