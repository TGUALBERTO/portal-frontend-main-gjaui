import 'package:dio/dio.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../imports/core_imports.dart';
import '../services/app_talker.dart';
import 'app_environment.dart';
import 'backend_service.dart';

class AppConfig {
  AppConfig._();

  /// Um [Dio] por backend. Construídos em [init] e mantidos estáveis pela vida
  /// do app — [setEnvironment] muta a `baseUrl` in place em vez de recriar — de
  /// modo que o DI possa segurar as referências.
  static final Map<BackendService, Dio> _dios = {};

  static const String _envStorageKey = 'app_environment';

  /// Ambiente de backend reativo. Lido pelo seletor de ambiente da Home e
  /// persistido via Hive para que a escolha sobreviva a reinícios. Exige que o
  /// [HiveService] esteja inicializado antes de [init] rodar.
  static final Signal<AppEnvironment> environment =
      signal(_resolveInitialEnvironment());

  /// Ambiente inicial. Na web, o host que serve o app tem prioridade — o
  /// ambiente é determinado pelo deploy (localhost→DEV, portal-qas→QAS,
  /// portal→PRD), o que evita que um valor persistido antigo aponte o frontend
  /// para o backend errado. Fora da web, ou em host desconhecido, cai no valor
  /// persistido no Hive.
  static AppEnvironment _resolveInitialEnvironment() {
    if (PlatformInfo.isWeb) {
      final fromUrl = AppEnvironment.fromWebHost(Uri.base.host);
      if (fromUrl != null) return fromUrl;
    }
    return _readPersistedEnvironment();
  }

  /// [Dio] do [service]. Lança se acessado antes de [init].
  static Dio dioFor(BackendService service) =>
      _dios[service] ??
      (throw StateError(
        'AppConfig.init() precisa rodar antes de dioFor($service)',
      ));

  static AppEnvironment _readPersistedEnvironment() {
    final stored = HiveService.instance.get<String>(_envStorageKey);
    final env = AppEnvironment.fromName(stored);
    // Protege contra um ambiente persistido que não é válido nesta plataforma
    // (ex.: LOCAL carregado em um dispositivo mobile).
    if (env == null || !AppEnvironment.available.contains(env)) {
      return AppEnvironment.fallback;
    }
    return env;
  }

  /// Constrói um [Dio] por backend, todos no ambiente ativo, com o mesmo
  /// interceptor de auth (token único) e o mesmo logger.
  static Future<void> init() async {
    for (final service in BackendService.values) {
      _dios[service] = _buildDio(service, environment.value);
    }
  }

  static Dio _buildDio(BackendService service, AppEnvironment env) {
    final dio = Dio(
      BaseOptions(
        baseUrl: service.baseUrlFor(env),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth interceptor: mesma lógica (refresh + Bearer) em todos os backends,
    // EXCETO os SAP Gateways. Neles a autenticação é o cookie de sessão SAP
    // (anexado por request no repositório) e o interceptor abaixo sobrescreveria
    // o header `Authorization` com um Bearer do Entra ID que o SAP não entende.
    if (!service.isSap) {
      dio.interceptors.add(_authInterceptor());
    }

    // HTTP logging via Talker — adicionado por último para logar a request já
    // com o Authorization aplicado. Habilitado em debug e na web contra QAS.
    if (_httpLogsEnabled(env)) {
      dio.interceptors.add(_talkerLogger());
    }

    return dio;
  }

  /// Interceptor de auth compartilhado: faz refresh quando expirado e anexa o
  /// Bearer token da sessão Microsoft. O mesmo token vale para todos os
  /// backends (autenticação só no login do frontend).
  static InterceptorsWrapper _authInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storage = TokenStorage.instance;
          var session = await storage.read();
          if (session != null &&
              session.isExpired &&
              session.refreshToken != null) {
            final refreshed = await MicrosoftAuthService.instance
                .refresh(session.refreshToken!);
            if (refreshed != null) {
              await storage.save(refreshed);
              session = refreshed;
            }
          }
          if (session != null && !session.isExpired) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          return handler.next(options);
        },
      );

  /// Habilita logs HTTP em debug (DX no dev) e também na web rodando contra o
  /// QAS, mesmo em release. Fora do release nativo e do PRD na web.
  static bool _httpLogsEnabled(AppEnvironment env) =>
      kDebugMode || (PlatformInfo.isWeb && env == AppEnvironment.qas);

  static TalkerDioLogger _talkerLogger() => TalkerDioLogger(
        talker: appTalker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: false,
          printRequestData: true,
          printResponseData: true,
          // Evita vazar o Bearer token nos logs.
          hiddenHeaders: {'authorization'},
        ),
      );

  /// Troca o ambiente de backend ativo em runtime: muta a `baseUrl` de CADA
  /// [Dio] in place (não recria instâncias — o DI segura as referências) e
  /// persiste a escolha. Não faz nada quando [env] já está ativo.
  static Future<void> setEnvironment(AppEnvironment env) async {
    if (env == environment.value) return;
    environment.value = env;
    for (final entry in _dios.entries) {
      entry.value.options.baseUrl = entry.key.baseUrlFor(env);
    }
    await HiveService.instance.put(_envStorageKey, env.name);
  }
}
