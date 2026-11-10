import '../utils/platform_info.dart';

/// Ambientes de backend que o app pode acessar.
///
/// O ambiente seleciona QUAL URL base de cada backend usar — as URLs (scheme +
/// host[:porta]) vivem em [BackendService]. O registro do app no Azure e as
/// demais configurações são compartilhados. O ambiente ativo é escolhido em
/// runtime na tela Home e persistido entre execuções; veja [AppConfig].
enum AppEnvironment {
  // LOCAL: backends rodando direto na máquina do dev. Só é oferecido no desktop
  // (veja [isDesktopOnly] / [available]).
  local('LOCAL'),
  // QAS/PRD: cada backend é acessado direto no seu próprio host, na raiz, sem
  // `/api` (scheme e porta definidos por backend em [BackendService]).
  qas('QAS'),
  prd('PRD');

  const AppEnvironment(this.label);

  /// Nome curto e legível exibido na UI (ex.: "QAS", "PRD").
  final String label;

  /// Indica se este ambiente só pode ser selecionado em plataformas desktop.
  bool get isDesktopOnly => this == AppEnvironment.local;

  /// Ambiente usado em instalação nova ou quando o valor persistido está
  /// ausente/inválido. Padrão QAS, para que instalações novas nunca apontem
  /// para produção nem caiam no LOCAL (exclusivo de desktop).
  static const AppEnvironment fallback = AppEnvironment.qas;

  /// Ambientes selecionáveis na plataforma atual. O LOCAL é filtrado, a menos
  /// que esteja rodando em um SO desktop.
  static List<AppEnvironment> get available {
    final isDesktop = PlatformInfo.isDesktop;
    return [
      for (final env in values)
        if (!env.isDesktopOnly || isDesktop) env,
    ];
  }

  /// Resolve um [name] persistido de volta para um ambiente, ou null se
  /// desconhecido.
  static AppEnvironment? fromName(String? name) {
    if (name == null) return null;
    for (final env in values) {
      if (env.name == name) return env;
    }
    return null;
  }

  /// Resolve o ambiente a partir do [host] que serve o app na web (o ambiente
  /// é definido pelo deploy). Retorna null para hosts desconhecidos (ex.: URLs
  /// de preview), deixando o chamador cair no valor persistido/fallback.
  ///
  /// - `localhost` / `127.0.0.1`        → DEV (LOCAL)
  /// - `portal-qas.rebic.com.br`        → QAS
  /// - `portal.rebic.com.br`            → PRD
  static AppEnvironment? fromWebHost(String host) {
    switch (host.toLowerCase()) {
      case 'localhost':
      case '127.0.0.1':
        return AppEnvironment.local;
      case 'portal-qas.rebic.com.br':
        return AppEnvironment.qas;
      case 'portal.rebic.com.br':
        return AppEnvironment.prd;
      default:
        return null;
    }
  }
}
