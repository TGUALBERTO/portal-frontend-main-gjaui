/// Configuração estática do Azure AD / Microsoft OAuth2.
///
/// Estes valores estão atrelados ao registro do app no Azure e não mudam por
/// ambiente, então são mantidos como constantes de compilação em vez de serem
/// lidos de configuração externa. Apenas valores que variam por ambiente (ex.:
/// a URL base do backend) ficam fora daqui — veja [AppEnvironment].
class MicrosoftAuthConfig {
  MicrosoftAuthConfig._();

  static const String clientId = '2ad10533-fc70-4047-80dc-281ca6dd9d83';
  static const String tenant = 'organizations';

  // Esquema próprio (reverse-domain) em vez de `msauth://`: o esquema `msauth`
  // é especial — colide com o broker do Microsoft Authenticator e dispara o
  // tratamento de broker, que sem signature hash registrado faz o redirect não
  // voltar para o app. Um esquema dedicado é resolvido direto pelo intent-filter.
  static const String redirectUriAndroid = 'com.gja.gjamobile://oauth2redirect';

  /// Scope que autoriza chamadas à API de backend do Portal. Deve corresponder
  /// a um scope de "Expose an API" no registro do app no Azure AD (ex.:
  /// `api://[client-id]/access`). Obrigatório em ambientes não-locais: o
  /// backend rejeita tokens cujo audience não inclua esta API.
  static const String apiScope = 'api://$clientId/access';

  static const List<String> _baseScopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  static List<String> get scopes {
    final base = List<String>.of(_baseScopes);
    if (apiScope.isNotEmpty && !base.contains(apiScope)) base.add(apiScope);
    return base;
  }

  static String get authority =>
      'https://login.microsoftonline.com/$tenant/v2.0';

  static String get authorizationEndpoint =>
      'https://login.microsoftonline.com/$tenant/oauth2/v2.0/authorize';

  static String get tokenEndpoint =>
      'https://login.microsoftonline.com/$tenant/oauth2/v2.0/token';
}
