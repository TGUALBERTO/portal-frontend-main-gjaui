/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example: `context.go(AppRoutes.onboarding)` instead of `context.go('/')`.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';

  /// Perfil do usuário logado (dados vindos da sessão + Microsoft Graph).
  static const String me = '/me';

  /// Fluxo de vínculo de matrícula (Dynamic KBA) do primeiro acesso.
  static const String kbaVinculo = '/vinculo';

  // ── Access management (GA) ────────────────────────────────────────────────
  static const String gaGroups = '/ga/groups';
  static const String gaGroupNew = '/ga/groups/new';

  /// Edit route template; use [gaGroupEditPath] to build a concrete path.
  static const String gaGroupEdit = '/ga/groups/:id';
  static String gaGroupEditPath(String id) => '/ga/groups/$id';

  static const String gaFeatures = '/ga/features';
  static const String gaFeatureNew = '/ga/features/new';

  /// Edit route template; use [gaFeatureEditPath] to build a concrete path.
  static const String gaFeatureEdit = '/ga/features/:id';
  static String gaFeatureEditPath(String id) => '/ga/features/$id';

  static const String gaModules = '/ga/modules';
  static const String gaModuleNew = '/ga/modules/new';

  /// Edit route template; use [gaModuleEditPath] to build a concrete path.
  static const String gaModuleEdit = '/ga/modules/:id';
  static String gaModuleEditPath(String id) => '/ga/modules/$id';

  static const String gaUsers = '/ga/users';

  /// User detail route template (admin); use [gaUserDetailPath] to build it.
  static const String gaUserDetail = '/ga/user/:id';
  static String gaUserDetailPath(String id) => '/ga/user/$id';

  /// User group-management route template; use [gaUserGroupsPath] to build it.
  static const String gaUserGroups = '/ga/users/:id';
  static String gaUserGroupsPath(String id) => '/ga/users/$id';

  static const String gaPermissions = '/ga/permissions';

  /// Gerenciamento de Deltas — catálogo de processos de integração (admin).
  static const String gaIntegracoes = '/ga/integracoes';

  // ── Inbound ───────────────────────────────────────────────────────────────
  static const String gjaautoInboundCheckInVeiculo = '/GJAAUTO/IN/checkInVeiculo';
  static const String gjaautoInboundCheckOutVeiculo = '/GJAAUTO/IN/checkOutVeiculo';
  static const String gjaautoInboundConsultaCheckin = '/GJAAUTO/IN/consultaCheckin';

  /// Contagem cega — cinco telas de um mesmo fluxo, cada uma com a sua rota
  /// para o endereço acompanhar onde o conferente está. As sub-rotas exigem uma
  /// sessão ativa (ver o guard em `inbound_routes.dart`).
  static const String gjaautoInboundContagemCega = '/GJAAUTO/IN/contagemCega';
  static const String gjaautoInboundContagemCegaNotas =
      '/GJAAUTO/IN/contagemCega/notas';

  /// Itens de uma NF-e; use [gjaautoInboundContagemCegaItensPath].
  static const String gjaautoInboundContagemCegaItens =
      '/GJAAUTO/IN/contagemCega/notas/:nota';
  static String gjaautoInboundContagemCegaItensPath(int nota) =>
      '/GJAAUTO/IN/contagemCega/notas/$nota';

  /// Contagem de um item; use [gjaautoInboundContagemCegaContagemPath].
  static const String gjaautoInboundContagemCegaContagem =
      '/GJAAUTO/IN/contagemCega/notas/:nota/itens/:item';
  static String gjaautoInboundContagemCegaContagemPath(int nota, int item) =>
      '/GJAAUTO/IN/contagemCega/notas/$nota/itens/$item';

  static const String gjaautoInboundContagemCegaResumo =
      '/GJAAUTO/IN/contagemCega/resumo';

  // ── Portaria ──────────────────────────────────────────────────────────────
  static const String portariaEntradaVeiculo = '/PORT/entradaVeiculo';
  static const String portariaSaidaVeiculo = '/PORT/saidaVeiculo';

  // ── Helpdesk ──────────────────────────────────────────────────────────────
  static const String helpdeskTimesheet = '/helpdesk/timesheet';// Timesheet (apontamento de horas).

  // ── TeamsBot (ATAs / RAG / custos / reuniões / fila) ──────────────────────
  // Abas do shell interno da feature.
  static const String teamsbotAtas = '/teamsbot/atas';
  static const String teamsbotConsultar = '/teamsbot/consultar';
  static const String teamsbotCustos = '/teamsbot/custos';
  static const String teamsbotReunioes = '/teamsbot/reunioes';
  static const String teamsbotFila = '/teamsbot/fila';

  // Telas full-screen (fora do shell). Templates + builders de path.
  static const String teamsbotConsultaHistorico = '/teamsbot/consultar/historico';

  static const String teamsbotAtaDetalhe = '/teamsbot/atas/:id';
  static String teamsbotAtaDetalhePath(int id) => '/teamsbot/atas/$id';

  static const String teamsbotAtaEditor = '/teamsbot/atas/:id/editar';
  static String teamsbotAtaEditorPath(int id) => '/teamsbot/atas/$id/editar';

  static const String teamsbotReuniaoDetalhe = '/teamsbot/reunioes/:id';
  static String teamsbotReuniaoDetalhePath(int id) => '/teamsbot/reunioes/$id';

  // ── BI (Business Intelligence) — abas do BiShell ──────────────────────────
  static const String biExecutive = '/bi/executive';
  static const String biCompany = '/bi/company';
  static const String biIncidents = '/bi/incidents';
  static const String biRequests = '/bi/requests';
  static const String biImprovements = '/bi/improvements';
  static const String biSla = '/bi/sla';
  static const String biBacklog = '/bi/backlog';
  static const String biCapacity = '/bi/capacity';
  static const String biSap = '/bi/sap';
  static const String biMultiplataforma = '/bi/multiplataforma';
  static const String biChange = '/bi/change';
  static const String biQuality = '/bi/quality';
  static const String biTeam = '/bi/team';
  static const String biUser = '/bi/user';

  /// Performance Individual de um colaborador específico; use [biUserPath].
  static const String biUserDetail = '/bi/user/:id';
  static String biUserPath(int id) => '/bi/user/$id';

  static const String biDesenvolvimento = '/bi/desenvolvimento';
  static const String biRiscos = '/bi/riscos';

  // ── RH Processo (rhprocesso-api) ──────────────────────────────────────────
  static const String rhVolume = '/rh/volume';
  static const String rhEstrutura = '/rh/estrutura';
  static const String rhCaracteristicas = '/rh/caracteristicas';
  static const String rhParametros = '/rh/parametros';
}
