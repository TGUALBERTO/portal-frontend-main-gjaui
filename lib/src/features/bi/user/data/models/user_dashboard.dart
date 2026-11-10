import '../../../shared/models/models.dart';

/// Cartão de perfil do colaborador (Grafico6). Espelha o record
/// `PerfilColaborador` do backend.
class PerfilColaborador {
  const PerfilColaborador({
    required this.id,
    required this.nome,
    required this.squad,
    required this.empresa,
    required this.capacidadeMensalHoras,
    this.email = '',
  });

  final int id;
  final String nome;
  final String squad;
  final String empresa;
  final int capacidadeMensalHoras;

  /// E-mail (UPN) do colaborador — usado para buscar a foto no Graph. Vazio
  /// quando o backend não tem e-mail do usuário GLPI.
  final String email;

  factory PerfilColaborador.fromJson(Map<String, dynamic> j) => PerfilColaborador(
        id: parseInt(j['id']),
        nome: parseStr(j['nome']),
        squad: parseStr(j['squad']),
        empresa: parseStr(j['empresa']),
        capacidadeMensalHoras: parseInt(j['capacidadeMensalHoras']),
        email: parseStr(j['email']),
      );
}

/// Resposta completa (BFF) do painel "Performance Individual" — espelha
/// `UserDashboardResponse` (`GET /dashboards/user/{userId}`, Grafico6.png).
/// O contrato não traz "competências" → sem radar (não inventamos dado).
class UserDashboard {
  const UserDashboard({
    required this.perfil,
    required this.cards,
    required this.distribuicaoPorTipo,
    required this.evolucaoHoras,
    required this.insights,
  });

  final PerfilColaborador? perfil;
  final List<KpiCard> cards;
  final List<Ponto> distribuicaoPorTipo;
  final List<Serie> evolucaoHoras;
  final List<Insight> insights;

  factory UserDashboard.fromJson(Map<String, dynamic> j) => UserDashboard(
        perfil: j['perfil'] is Map<String, dynamic>
            ? PerfilColaborador.fromJson(j['perfil'] as Map<String, dynamic>)
            : null,
        cards: parseList(j['cards'], KpiCard.fromJson),
        distribuicaoPorTipo: parseList(j['distribuicaoPorTipo'], Ponto.fromJson),
        evolucaoHoras: parseList(j['evolucaoHoras'], Serie.fromJson),
        insights: parseList(j['insights'], Insight.fromJson),
      );
}
