import '../../../shared/models/models.dart';

/// Linha da matriz "Comparativo de Indicadores por Empresa" (painel 1).
/// Espelha o record `LinhaComparativoEmpresa` do backend.
class LinhaComparativoEmpresa {
  const LinhaComparativoEmpresa({
    required this.empresa,
    required this.chamados,
    required this.slaMedio,
    required this.backlog,
    required this.agingMedio,
    required this.incidentesSev1,
  });

  final String empresa;
  final int chamados;
  final double slaMedio;
  final int backlog;
  final double agingMedio;
  final int incidentesSev1;

  factory LinhaComparativoEmpresa.fromJson(Map<String, dynamic> j) =>
      LinhaComparativoEmpresa(
        empresa: parseStr(j['empresa']),
        chamados: parseInt(j['chamados']),
        slaMedio: parseDouble(j['slaMedio']),
        backlog: parseInt(j['backlog']),
        agingMedio: parseDouble(j['agingMedio']),
        incidentesSev1: parseInt(j['incidentesSev1']),
      );
}

/// Resposta completa (BFF) do "Painel Comparativo por Empresa" — espelha
/// `CompanyDashboardResponse` do backend (`GET /dashboards/company`).
class CompanyDashboard {
  const CompanyDashboard({
    required this.cards,
    required this.comparativo,
    required this.volumePorEmpresa,
    required this.evolucaoSla,
    required this.insights,
  });

  final List<KpiCard> cards;
  final List<LinhaComparativoEmpresa> comparativo;
  final List<Ponto> volumePorEmpresa;
  final List<Serie> evolucaoSla;
  final List<Insight> insights;

  factory CompanyDashboard.fromJson(Map<String, dynamic> j) => CompanyDashboard(
        cards: parseList(j['cards'], KpiCard.fromJson),
        comparativo:
            parseList(j['comparativo'], LinhaComparativoEmpresa.fromJson),
        volumePorEmpresa: parseList(j['volumePorEmpresa'], Ponto.fromJson),
        evolucaoSla: parseList(j['evolucaoSla'], Serie.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
