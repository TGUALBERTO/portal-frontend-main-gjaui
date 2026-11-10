import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../config/backend_service.dart';
import 'app_talker.dart';

/// DIAGNÓSTICO DE STARTUP — pinga `<baseUrl>/actuator/health/ping` de CADA
/// backend registrado ([BackendService.values]), na RAIZ (sem `/api`), no
/// ambiente ativo. O endpoint é público no backend (`/actuator/health/**` é
/// `permitAll`), então não depende de token.
///
/// Cada backend é probado de forma isolada (try/catch próprio) e logado com o
/// nome do backend, para que a falha de um não mascare nem interrompa os
/// demais. Nunca lança: não afeta o boot do app.
///
/// Qualquer resposta HTTP limpa (200, 401, 404...) prova que o host roteia até
/// aquele backend e ele está no ar. `Connection refused` / timeout / 502 / 504
/// = backend fora, rede, DNS ou TLS.
Future<void> runBackendHealthPing() async {
  const path = '/actuator/health/ping';
  final env = AppConfig.environment.value;
  final origin = kIsWeb ? Uri.base.origin : '(nativo)';

  for (final service in BackendService.values) {
    final baseUrl = service.baseUrlFor(env);

    // Dio dedicado e isolado por backend: sem interceptor de auth (endpoint
    // público) nem refresh. validateStatus aceita tudo para que 4xx/5xx NÃO
    // virem exceção — queremos logar o status. Timeout curto: é diagnóstico.
    final probe = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (_) => true,
      ),
    );

    appTalker.info(
      '🔎 [HEALTH-CHECK] ${service.name} — baseUrl="$baseUrl" '
      'path="$path" origem="$origin"',
    );

    try {
      final response = await probe.get<dynamic>(path);
      appTalker.info(
        '✅ [HEALTH-CHECK] ${service.name} — alcançável\n'
        '   URL chamada : ${response.realUri}\n'
        '   Status      : ${response.statusCode} ${response.statusMessage ?? ''}\n'
        '   Body        : ${response.data}\n'
        '   → qualquer status HTTP prova roteamento até o backend.',
      );
    } on DioException catch (e) {
      appTalker.error(
        '⛔ [HEALTH-CHECK] ${service.name} — FALHA\n'
        '   URL chamada : ${e.requestOptions.uri}\n'
        '   Tipo        : ${e.type}\n'
        '   Status      : ${e.response?.statusCode ?? '(sem resposta)'}\n'
        '   Mensagem    : ${e.message}\n'
        '   Erro raiz   : ${e.error}\n'
        '   → sem resposta HTTP = backend fora / rede / DNS / TLS.',
        e,
        e.stackTrace,
      );
    } catch (e, st) {
      appTalker.error(
        '⛔ [HEALTH-CHECK] ${service.name} — erro inesperado',
        e,
        st,
      );
    }
  }
}
