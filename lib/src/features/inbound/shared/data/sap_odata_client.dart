import 'package:dio/dio.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_session_repository.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/entities/sap_session.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Cliente OData V2 dos SAP Gateways, compartilhado pelos submódulos do inbound.
///
/// Autenticação: os [Dio] SAP não têm interceptor de auth (ver
/// `AppConfig._buildDio`); cada request leva o cookie da [SapSession] emitida
/// pelo backend `core`, e as escritas levam também o `X-CSRF-Token`. Se a sessão
/// expirar, o cliente renova e repete a chamada **uma** vez.
///
/// É parametrizado por `service` porque o inbound consome mais de um serviço
/// OData do mesmo sistema (`ZGJAAUTO_GENERIC_SRV` para veículos,
/// `ZGJAAUTO_SB_GENERIC` para a contagem cega). O cache de sessão é do
/// [SapSessionRepository], que é singleton no DI.
class SapODataClient {
  SapODataClient(this._sessions, this._band, this._nel, this._vita);

  final SapSessionRepository _sessions;
  final SapBandeirantesDio _band;
  final SapNelDio _nel;
  final SapVitamedicDio _vita;

  /// Prefixo dos serviços OData no Gateway.
  static const String _odataBasePath = '/sap/opu/odata';

  /// Teto de páginas seguidas por [getAll].
  ///
  /// Existe para transformar um `__next` infinito (ou uma carga absurda) num
  /// erro explícito. Numa contagem cega, truncar a lista em silêncio é o pior
  /// desfecho possível: o item que sumiu passa batido e a carga é recebida sem
  /// ter sido conferida.
  static const int _maxPaginas = 50;

  String basePath(String service) => '$_odataBasePath/$service';

  /// Lê UMA entidade e devolve o conteúdo do envelope `d`.
  Future<Map<String, dynamic>> getEntity({
    required BackendService backend,
    required String service,
    required String path,
    Map<String, dynamic>? query,
  }) async {
    final response = await send(
      backend: backend,
      service: service,
      request: (dio, session) => dio.get<dynamic>(
        '${basePath(service)}/$path',
        queryParameters: query,
        options: Options(headers: {'Cookie': session.cookieHeader}),
      ),
    );
    return _envelope(response.data);
  }

  /// Lê uma COLEÇÃO inteira, seguindo o `__next` até acabar.
  Future<List<Map<String, dynamic>>> getAll({
    required BackendService backend,
    required String service,
    required String path,
    Map<String, dynamic>? query,
  }) async {
    final resultados = <Map<String, dynamic>>[];
    var url = '${basePath(service)}/$path';
    Map<String, dynamic>? parametros = query;

    for (var pagina = 0; pagina < _maxPaginas; pagina++) {
      final response = await send(
        backend: backend,
        service: service,
        request: (dio, session) => dio.get<dynamic>(
          url,
          queryParameters: parametros,
          options: Options(headers: {'Cookie': session.cookieHeader}),
        ),
      );

      final envelope = _envelope(response.data);
      resultados.addAll(_results(envelope));

      final proxima = envelope['__next'];
      if (proxima is! String || proxima.trim().isEmpty) return resultados;

      // O Gateway devolve o `__next` como URL ABSOLUTA. Reemitir só o
      // path+query contra o mesmo Dio: a URL absoluta pode apontar para outro
      // host (proxy, load balancer) e a sessão só vale onde foi aberta.
      final uri = Uri.parse(proxima.trim());
      url = uri.path;
      parametros = uri.queryParameters.isEmpty ? null : uri.queryParameters;
    }

    throw ServerFailure(
      'O SAP devolveu mais de $_maxPaginas páginas em "$path". '
      'A leitura foi interrompida para não entregar uma lista incompleta.',
    );
  }

  /// Escrita (POST/MERGE/PUT/DELETE). Devolve a `Response` crua — quem chama
  /// decide qual 2xx é aceitável (MERGE no OData V2 responde **204**).
  Future<Response<dynamic>> write({
    required BackendService backend,
    required String service,
    required String method,
    required String path,
    Object? body,
  }) {
    return send(
      backend: backend,
      service: service,
      request: (dio, session) => dio.request<dynamic>(
        '${basePath(service)}/$path',
        data: body,
        options: Options(
          method: method,
          headers: {
            'Cookie': session.cookieHeader,
            'X-CSRF-Token': session.csrfToken,
          },
        ),
      ),
    );
  }

  /// Executa [request] com uma sessão válida. Em 401 (sessão expirada) ou 403
  /// com `x-csrf-token: Required` (token inválido), renova a sessão e repete
  /// **uma única vez** — sem custo no caminho feliz e sem risco de loop.
  Future<Response<dynamic>> send({
    required BackendService backend,
    required String service,
    required Future<Response<dynamic>> Function(Dio dio, SapSession session)
        request,
  }) async {
    final dio = dioFor(backend);
    // baseUrl do ambiente ATIVO: o seletor da Home muta a baseUrl dos Dios in
    // place, então ler daqui é o que garante que sessão e chamada de negócio
    // usem o mesmo host.
    final baseUrl = dio.options.baseUrl;
    final session = await _sessions.ensure(
      backend: backend,
      baseUrl: baseUrl,
      service: service,
    );

    try {
      return await request(dio, session);
    } on DioException catch (error) {
      if (!_isSessionInvalid(error)) {
        _logErro(error);
        rethrow;
      }
      AppLogger.warning(
        'Sessão SAP inválida (${error.response?.statusCode}); renovando e repetindo.',
      );
      final renewed = await _sessions.ensure(
        backend: backend,
        baseUrl: baseUrl,
        service: service,
        refresh: true,
      );
      try {
        return await request(dio, renewed);
      } on DioException catch (retryError) {
        _logErro(retryError);
        rethrow;
      }
    }
  }

  /// Registra QUAL chamada falhou e o `transactionid` do Gateway.
  ///
  /// Quando o ABAP levanta uma exceção não tratada, o Gateway responde só
  /// "an unknown internal server error occurred" — a tela não tem como dizer
  /// mais. O `transactionid` é a chave para achar o erro na
  /// `/IWFND/ERROR_LOG` (e de lá o dump na ST22) sem caçar pelo horário.
  static void _logErro(DioException error) {
    final response = error.response;
    final data = response?.data;
    final inner = data is Map && data['error'] is Map
        ? (data['error'] as Map)['innererror']
        : null;
    final transacao = inner is Map ? inner['transactionid'] : null;
    final horario = inner is Map ? inner['timestamp'] : null;

    AppLogger.error(
      'SAP OData ${error.requestOptions.method} ${error.requestOptions.uri} '
      '→ ${response?.statusCode ?? error.type.name}'
      '${transacao != null ? ' | transactionid=$transacao' : ''}'
      '${horario != null ? ' | timestamp=$horario' : ''}',
    );
  }

  Dio dioFor(BackendService backend) => switch (backend) {
        BackendService.sapBandeirantes => _band.dio,
        BackendService.sapNel => _nel.dio,
        BackendService.sapVitamedic => _vita.dio,
        _ => throw ArgumentError.value(
            backend,
            'backend',
            'Não é um SAP Gateway',
          ),
      };

  /// Desembrulha o `d` do OData V2.
  static Map<String, dynamic> _envelope(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Resposta inválida do SAP (esperado JSON)');
    }
    final data = body['d'];
    if (data is! Map) {
      throw const FormatException(
        'Resposta do SAP sem o envelope "d" — confira o header Accept',
      );
    }
    return data.cast<String, dynamic>();
  }

  /// Coleção do envelope. Tolerante às duas formas que o Gateway usa:
  /// `d.results` (o normal) e `d` já sendo a lista.
  static List<Map<String, dynamic>> _results(Map<String, dynamic> envelope) {
    final results = envelope['results'];
    if (results is List) {
      return results
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }
    return const [];
  }

  static bool _isSessionInvalid(DioException error) {
    final response = error.response;
    if (response == null) return false;
    if (response.statusCode == 401) return true;
    if (response.statusCode == 403) {
      return response.headers.value('x-csrf-token')?.toLowerCase() ==
          'required';
    }
    return false;
  }
}
