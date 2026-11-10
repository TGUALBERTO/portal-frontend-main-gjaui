import 'package:dio/dio.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/entities/sap_session.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/sap_backend.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Busca a sessão SAP no backend `core` (que já recebe o Bearer Microsoft pelo
/// interceptor de auth compartilhado).
///
/// Contrato: `GET /sap/session?baseUrl=<host>&service=<NAMESPACE>/<NOME>&codigoEmpresa=<codigo>`.
///
/// Divisão de responsabilidade:
/// - **empresa**: o app informa a empresa da operação; o backend autoriza a
///   troca somente para Consultores. Os demais usam a empresa do cadastro.
/// - **ambiente** (`baseUrl`): do app. Só ele sabe se está apontado para
///   DEV/QAS/PRD, e a sessão precisa ser aberta no MESMO sistema onde as
///   chamadas de negócio vão cair. O backend só aceita hosts da allow-list dele.
/// - **serviço**: do app. No SAP a autenticação é do sistema (o token vale para
///   todos os serviços daquele sistema), mas abrir a sessão contra o serviço que
///   a tela consome faz uma falta de ativação no SICF ou de autorização
///   `S_SERVICE` aparecer já aqui.
///
/// ```json
/// { "sapSystem": "NEL", "baseUrl": "...", "service": "...", "csrfToken": "...",
///   "cookies": ["SAP_SESSIONID_...=..."], "expiresIn": 1800 }
/// ```
///
/// Vive na feature porque só o inbound consome; promover para `lib/src/services/`
/// quando uma segunda feature precisar.
class SapSessionRepository {
  SapSessionRepository(this._core);

  final CoreDio _core;

  static const String _path = '/sap/session';

  /// Sessões vivas, por `sistema|host|serviço`.
  ///
  /// O cache vive aqui — e não no repositório de negócio — porque o inbound tem
  /// mais de um repositório SAP (veículos em `ZGJAAUTO_GENERIC_SRV`, contagem em
  /// `ZGJAAUTO_SB_GENERIC`) e cada um com o próprio cache abriria uma sessão
  /// nova a cada troca de tela.
  ///
  /// O **host** entra na chave de propósito: o card "Ambiente" da Home muta a
  /// `baseUrl` dos Dios in place, então trocar QAS→PRD precisa dar miss em vez
  /// de reusar o cookie do ambiente anterior. O **serviço** entra porque é ele
  /// que faz um 403 de `S_SERVICE` aparecer na abertura da sessão, e não no meio
  /// da operação.
  final Map<String, SapSession> _cache = {};

  /// Devolve uma sessão válida para (sistema, host, serviço), usando o cache.
  ///
  /// **Lança** em vez de devolver `AppResult`: é sempre chamada de dentro do
  /// `runTask` do repositório de negócio, que converte a exceção em `AppFailure`.
  Future<SapSession> ensure({
    required BackendService backend,
    required String baseUrl,
    required String service,
    bool refresh = false,
  }) async {
    final alvo = SapSession.normalizeBaseUrl(baseUrl);
    final chave = '${backend.sapSystemCode}|$alvo|$service';

    final cached = _cache[chave];
    if (!refresh && cached != null && cached.isUsable && !cached.isExpired) {
      return cached;
    }
    _cache.remove(chave);

    final result = await fetch(
      baseUrl: baseUrl,
      service: service,
      codigoEmpresa: backend.sapCodigoEmpresa,
    );
    return result.fold(
      (session) {
        if (!session.isUsable) {
          throw const ServerFailure(
            'Sessão SAP incompleta (token ou cookie ausente). '
            'Verifique o endpoint /sap/session no backend.',
          );
        }
        final expected = backend.sapSystemCode;
        final received = session.sapSystem.toUpperCase();
        if (expected != null && received.isNotEmpty && received != expected) {
          throw ServerFailure(
            'Sessão SAP emitida para "$received", mas a empresa selecionada '
            'usa "$expected". Operação cancelada por segurança.',
          );
        }
        if (session.baseUrl.isNotEmpty && session.baseUrl != alvo) {
          throw ServerFailure(
            'Sessão SAP aberta em "${session.baseUrl}", mas as chamadas iriam '
            'para "$alvo". Operação cancelada por segurança.',
          );
        }
        _cache[chave] = session;
        return session;
      },
      (failure) => throw failure,
    );
  }

  /// [baseUrl] é o host SAP do ambiente ativo (o mesmo que as chamadas de
  /// negócio vão usar). [service] vai no formato `<NOME>` ou
  /// `<NAMESPACE>/<NOME>` (ex.: `GJAAUTO/MAIN_SRV`).
  AsyncAppResult<SapSession> fetch({
    required String baseUrl,
    required String service,
    int? codigoEmpresa,
  }) {
    return runTask(() async {
      try {
        final response = await _core.dio.get<dynamic>(
          _path,
          queryParameters: {
            'baseUrl': baseUrl,
            'service': service,
            if (codigoEmpresa != null) 'codigoEmpresa': codigoEmpresa,
          },
        );
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Resposta inválida de $_path');
        }
        return SapSession.fromJson(data);
      } on DioException catch (error) {
        // Mensagens acionáveis para os erros previstos no contrato. Sem isto, o
        // 404 daqui ficaria indistinguível do 404 de "check-in não existe" que
        // o SAP devolve na consulta.
        //
        // Em 403/502 a mensagem do backend é mais específica que qualquer texto
        // fixo daqui (diz qual empresa, qual sistema, ou que a security session
        // do SAP está desligada), então ela tem preferência. No 404 não há
        // mensagem útil: o endpoint simplesmente não existe.
        final doBackend = _mensagemDoBackend(error);
        throw switch (error.response?.statusCode) {
          404 => const ServerFailure(
              'Sessão SAP indisponível: o endpoint $_path ainda não está '
              'publicado neste ambiente.',
            ),
          403 => AuthFailure(
              doBackend ??
                  'Seu usuário não tem sessão SAP liberada para esta empresa.',
            ),
          502 => ServerFailure(
              doBackend ??
                  'O SAP não respondeu ao servidor. Tente novamente em instantes.',
            ),
          _ => error,
        };
      }
      // `requiresNetwork: false` de propósito: este fetch só é chamado de
      // dentro do `runTask(requiresNetwork: true)` do InboundRepositoryImpl,
      // que já checou a conexão. Repetir a checagem dispararia um segundo
      // `showGlobalToast` de "sem internet" na mesma busca.
    });
  }

  /// Mensagem do corpo de erro do backend. O `error-handling-spring-boot-starter`
  /// responde `{status, code, message, path}` — não é `problem+json`, então não
  /// há `title`/`detail` aqui.
  static String? _mensagemDoBackend(DioException error) {
    final data = error.response?.data;
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return null;
  }
}
