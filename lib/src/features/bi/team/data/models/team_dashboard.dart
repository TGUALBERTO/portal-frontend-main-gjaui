import '../../../shared/models/models.dart';

/// Linha da tabela "Visão Consolidada por Squad" (painel 4 do Grafico5). Espelha
/// o record `LinhaSquad` do backend.
class LinhaSquad {
  const LinhaSquad({
    required this.squad,
    required this.colaboradores,
    required this.horas,
    required this.ocupacao,
    required this.slaMedio,
  });

  final String squad;
  final int colaboradores;
  final double horas;
  final double ocupacao;
  final double slaMedio;

  factory LinhaSquad.fromJson(Map<String, dynamic> j) => LinhaSquad(
        squad: parseStr(j['squad']),
        colaboradores: parseInt(j['colaboradores']),
        horas: parseDouble(j['horas']),
        ocupacao: parseDouble(j['ocupacao']),
        slaMedio: parseDouble(j['slaMedio']),
      );
}

/// Resposta completa (BFF) do painel "Performance do Time" — espelha
/// `TeamDashboardResponse` (`GET /dashboards/team`, Grafico5.png).
class TeamDashboard {
  const TeamDashboard({
    required this.cards,
    required this.ocupacaoPorSquad,
    required this.horasPorSquad,
    required this.consolidadoPorSquad,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<Ponto> ocupacaoPorSquad;
  final List<Ponto> horasPorSquad;
  final List<LinhaSquad> consolidadoPorSquad;
  final List<Insight> insights;

  factory TeamDashboard.fromJson(Map<String, dynamic> j) => TeamDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        ocupacaoPorSquad: parseList(j['ocupacaoPorSquad'], Ponto.fromJson),
        horasPorSquad: parseList(j['horasPorSquad'], Ponto.fromJson),
        consolidadoPorSquad:
            parseList(j['consolidadoPorSquad'], LinhaSquad.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
