import 'package:gjamobile/src/features/kba/domain/entities/kba_session.dart';
import 'package:gjamobile/src/features/kba/domain/entities/kba_submit_result.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Códigos de erro do backend para o fluxo KBA (error-handling starter).
abstract final class KbaErrorCodes {
  KbaErrorCodes._();

  static const String unavailable = 'KBA_UNAVAILABLE';
  static const String blocked = 'KBA_BLOCKED';
  static const String alreadyLinked = 'KBA_ALREADY_LINKED';
  static const String cpfNotFound = 'KBA_CPF_NOT_FOUND';
  static const String invalidCpf = 'KBA_INVALID_CPF';
  static const String sessionExpired = 'KBA_SESSION_EXPIRED';
  static const String insufficientData = 'KBA_INSUFFICIENT_DATA';
  static const String rateLimited = 'KBA_RATE_LIMITED';
}

class KbaRepository {
  KbaRepository(this._core);

  final CoreDio _core;

  /// Inicia (ou reaproveita) a sessão de perguntas da tentativa corrente.
  AsyncAppResult<KbaSession> startSession(String cpf) {
    return runTask(() async {
      final response = await _core.dio
          .post<dynamic>('/kba/session', data: {'cpf': cpf});
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid /kba/session response');
      }
      return KbaSession.fromJson(data);
    }, requiresNetwork: true);
  }

  /// Envia as respostas; [answers] mapeia questionId -> índice selecionado.
  AsyncAppResult<KbaSubmitResult> submitAnswers(
    String sessionId,
    Map<String, int> answers,
  ) {
    return runTask(() async {
      final response = await _core.dio.post<dynamic>(
        '/kba/session/$sessionId/answers',
        data: {
          'answers': answers.entries
              .map((e) => {'questionId': e.key, 'selectedIndex': e.value})
              .toList(growable: false),
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid /kba answers response');
      }
      return KbaSubmitResult.fromJson(data);
    }, requiresNetwork: true);
  }
}
