import 'package:gjamobile/src/routing/app_routes.dart';

/// Registry that maps a backend `feature.code` to its go_router route.
///
/// Single source of truth for "which app a feature opens". Adding a new
/// navigable feature is a one-line entry here — the Home builds itself from
/// the user's enabled features and looks the route up by code.
///
/// Features NOT present here still render as cards (the user is entitled to
/// them), but tapping shows an "em breve" toast until a route is wired.
const Map<String, String> featureRoutes = {
  'users': AppRoutes.gaUsers,
  'groups': AppRoutes.gaGroups,
  'features': AppRoutes.gaFeatures,
  'modules': AppRoutes.gaModules,
  'permissions': AppRoutes.gaPermissions,
  // Gerenciamento de Deltas: catálogo de processos de integração, com
  // histórico das execuções e disparo manual.
  'integracoes': AppRoutes.gaIntegracoes,

  // ── Inboud GJAAUTO─────────────────────────────────────────────────────────
  'gjaauto-inbound-checkIn-veiculo': AppRoutes.gjaautoInboundCheckInVeiculo,
  'gjaauto-inbound-checkOut-veiculo': AppRoutes.gjaautoInboundCheckOutVeiculo,
  'gjaauto-inbound-consulta-checkIn': AppRoutes.gjaautoInboundConsultaCheckin,
  'gjaauto-inbound-contagem-cega': AppRoutes.gjaautoInboundContagemCega,

  // ── Portaria ──────────────────────────────────────────────────────────────
  // Códigos hipotéticos (convenção espelhando o inbound acima) — ajustar
  // aqui se o backend/RBAC cadastrar um `feature.code` diferente.
  'portaria-entrada-veiculo': AppRoutes.portariaEntradaVeiculo,
  'portaria-saida-veiculo': AppRoutes.portariaSaidaVeiculo,

  // ── TeamsBot ──────────────────────────────────────────────────────────────
  // Cada feature abre o shell interno já na aba correta. A chave é o
  // `feature.code` cadastrado no GA; os aliases cobrem variações de nome.
  // Se algum card ainda mostrar "em breve", ajuste o code no GA para uma das
  // chaves abaixo (ou me peça para adicionar o code exato aqui).
  'teamsbot-atas': AppRoutes.teamsbotAtas,  // ATAs
  'teamsbot-consulta': AppRoutes.teamsbotConsultar,// Consulta com IA (RAG)
  'teamsbot-custos': AppRoutes.teamsbotCustos,  // Custos
  'teamsbot-fila': AppRoutes.teamsbotFila,// Fila
  'teamsbot-reunioes': AppRoutes.teamsbotReunioes,// Reuniões (Teams)

  // ── Helpdesk ─────────────────────────────────────────────────────────────
  // Ajuste a chave para o `feature.code` cadastrado no GA, se for diferente.
  'helpdesk-timesheet': AppRoutes.helpdeskTimesheet,


  // ── BI (Business Intelligence) ────────────────────────────────────────────
  // Chaves = feature.code registrados no backend (AccessSeeder, módulo BI).
  // Cada uma abre a aba correspondente no BiShell. RBAC granular (canRead) —
  // não entram em adminOnlyFeatureCodes.
  'bi_executivo': AppRoutes.biExecutive,
  'bi_empresa': AppRoutes.biCompany,
  'bi_incidentes': AppRoutes.biIncidents,
  'bi_requisicoes': AppRoutes.biRequests,
  'bi_melhorias': AppRoutes.biImprovements,
  'bi_sla': AppRoutes.biSla,
  'bi_backlog': AppRoutes.biBacklog,
  'bi_capacity': AppRoutes.biCapacity,
  'bi_sap': AppRoutes.biSap,
  'bi_multiplataforma': AppRoutes.biMultiplataforma,
  'bi_mudancas': AppRoutes.biChange,
  'bi_qualidade': AppRoutes.biQuality,
  'bi_time': AppRoutes.biTeam,
  'bi_individual': AppRoutes.biUser,
  'bi_desenvolvimento': AppRoutes.biDesenvolvimento,
  'bi_riscos': AppRoutes.biRiscos,

  // ── RH Processo ───────────────────────────────────────────────────────────
  // Chaves = feature.code do AccessSeeder (módulo RH), os mesmos que a
  // rhprocesso-api autoriza. RBAC granular — não entram em adminOnly.
  'rhprocesso_volume': AppRoutes.rhVolume,
  'rhprocesso_estrutura': AppRoutes.rhEstrutura,
  'rhprocesso_caracteristicas': AppRoutes.rhCaracteristicas,
  'rhprocesso_parametros': AppRoutes.rhParametros,
};

/// Feature codes that require ADMIN membership. This is a UX guard only — the
/// backend also enforces it on every endpoint.
const Set<String> adminOnlyFeatureCodes = {
  'users',
  'groups',
  'features',
  'modules',
  'permissions',
  'integracoes',
};

/// Resolves the go_router route for a feature code, or null when unmapped.
String? routeForFeatureCode(String code) => featureRoutes[code];
