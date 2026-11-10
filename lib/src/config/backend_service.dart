import 'app_environment.dart';

/// Backends que o app acessa, fixos em código (não configuráveis em runtime).
///
/// Cada backend é alcançado DIRETO no seu host. A URL base por ambiente é
/// COMPLETA (scheme + host[:porta]), sem `/api` e sem barra final. O scheme é
/// POR BACKEND. Em QAS/PRD os backends ficam em HTTPS (host dedicado atrás do
/// Traefik) — a web é servida em HTTPS e o browser bloqueia chamada HTTP
/// (mixed-content), então o backend TEM que ser HTTPS. Em LOCAL é HTTP direto.
/// Adicionar um backend = adicionar um valor aqui.
enum BackendService {
  /// Backend core/portal: usuários, acesso (RBAC) e sync de auth.
  // TODO: confirmar os subdomínios dedicados do backend core. Precisam de DNS +
  // cert TLS (ex.: cobertos por um wildcard `*.rebic.com.br`).
  core(
    label: 'Core / Portal',
    baseUrls: {
      AppEnvironment.local: 'http://localhost:8080',
      AppEnvironment.qas: 'https://api-portal-qas.rebic.com.br',
      AppEnvironment.prd: 'https://api-portal.rebic.com.br',
    },
  ),

  /// Backend TeamsBot: ATAs (RAG), custos e pipeline de reuniões. Endpoints em
  /// `/api/atas...`, `/api/meetings...` e `/api/meeting-minutes...`.
  // TODO: confirmar hosts reais do TeamsBot (DNS + cert TLS). Placeholders.
  teamsbot(
    label: 'TeamsBot / ATAs',
    baseUrls: {
      AppEnvironment.local: 'http://localhost:8001',
      AppEnvironment.qas: 'https://teamsbot-qas.rebic.com.br',
      AppEnvironment.prd: 'https://teamsbot.rebic.com.br',
    },
  ),

  /// Backend Portaria: entrada/saída de veículos (check-in/checkout). Endpoints em
  /// `/api/entrada-saida-veiculo...`.
  // TODO: confirmar hosts reais do Portaria (DNS + cert TLS). Placeholders.
  portaria(
    label: 'Portaria / Entrada/Saída de Veículos',
    baseUrls: {
      AppEnvironment.local: 'http://gowwarm001',
      AppEnvironment.qas: 'http://gowwarm001',
      AppEnvironment.prd: 'http://gowwarm001',
    },
  ),

  /// Backend RH Processo (`rhprocesso-api`): volume x NF, DANFE em PDF,
  /// estrutura comercial e cadastros. Endpoints em `/api/v1/...`. Usa o mesmo
  /// token Microsoft e autoriza pelas features `rhprocesso_*` do RBAC do core.
  /// LOCAL na 8082 porque a 8080 é do core.
  rhprocesso(
    label: 'RH Processo',
    baseUrls: {
      AppEnvironment.local: 'http://localhost:8082',
      AppEnvironment.qas: 'https://api-rhprocesso-qas.rebic.com.br',
      AppEnvironment.prd: 'https://api-rhprocesso.rebic.com.br',
    },
  ),

  /// SAP Gateway da Refrescos Bandeirantes (OData V2, `/sap/opu/odata/sap/...`).
  ///
  /// ATENÇÃO: hosts em **HTTP puro** na porta 8000. Isso implica:
  /// - Android exige o `network_security_config.xml` (cleartext para
  ///   `rebic.com.br`) — sem ele o Android 9+ bloqueia a chamada;
  /// - na web servida em HTTPS o browser bloqueia por mixed-content. A tela de
  ///   check-in não tem a web como alvo (ver [isSap]).
  ///
  /// Nomenclatura dos hosts segue o padrão SAP D/Q/P (dev/quality/production).
  sapBandeirantes(
    label: 'SAP Bandeirantes',
    baseUrls: {
      AppEnvironment.local: 'http://GOISD001.rebic.com.br:8000',
      AppEnvironment.qas: 'http://GOISQ001.rebic.com.br:8000',
      AppEnvironment.prd: 'http://GOISP001.rebic.com.br:8000',
    },
  ),

  /// SAP Gateway da N&L Indústria (OData V2).
  sapNel(
    label: 'SAP NEL',
    baseUrls: {
      AppEnvironment.local: 'https://vhnlids4ci.sap.nelindustria.com.br:44300',
      AppEnvironment.qas: 'https://vhnliqs4ci.sap.nelindustria.com.br:44300',
      AppEnvironment.prd: 'https://vhnlips4ci.sap.nelindustria.com.br:44300',
    },
  ),

  /// SAP Gateway da Vitamedic (OData V2).
  sapVitamedic(
    label: 'SAP Vitamedic',
    baseUrls: {
      AppEnvironment.local: 'https://vhvtfds4ci.sap.vitamedic.ind.br:44300',
      AppEnvironment.qas: 'https://vhvtfqs4ci.sap.vitamedic.ind.br:44300',
      AppEnvironment.prd: 'https://vhvtfps4ci.sap.vitamedic.ind.br:44300',
    },
  );

  const BackendService({required this.label, required this.baseUrls});

  /// True para os SAP Gateways, que **não** usam o token Microsoft.
  ///
  /// Eles autenticam por uma sessão SAP (cookie + `X-CSRF-Token`) emitida pelo
  /// backend `core` em `GET /sap/session` — o app nunca vê usuário/senha SAP.
  /// `AppConfig` usa esta flag para NÃO anexar o interceptor de auth Microsoft
  /// nesses Dios (ele sobrescreveria o `Authorization` a cada request).
  bool get isSap =>
      this == sapBandeirantes || this == sapNel || this == sapVitamedic;

  /// Nome curto e legível (ex.: "Core / Portal").
  final String label;

  /// URL base COMPLETA por ambiente: scheme + host[:porta], sem `/api`, sem
  /// barra final.
  final Map<AppEnvironment, String> baseUrls;

  /// URL base deste backend no [env]; lança se não configurada. Remove uma
  /// barra final defensivamente para nunca duplicar ao concatenar paths.
  String baseUrlFor(AppEnvironment env) {
    final url = baseUrls[env] ?? (throw StateError('Sem URL base para $name em ${env.name}'));
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
