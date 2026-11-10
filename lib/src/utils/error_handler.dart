import 'package:dio/dio.dart';

import 'failure.dart';

class AppErrorHandler {
  static String format(dynamic error) {
    if (error is String) return error;

    if (error is DioException) return _formatDio(error);

    // Generic fallback: try a `.message` property, then toString().
    try {
      final dynamic message = (error as dynamic).message;
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}

    final asString = error?.toString();
    if (asString != null && asString.isNotEmpty) return asString;

    return 'Ocorreu um erro inesperado';
  }

  /// Mapeia um erro qualquer para a variante de [AppFailure] mais adequada.
  ///
  /// - [DioException] com corpo `application/problem+json` → [ApiFailure]
  ///   carregando `status`/`title`/`detail`.
  /// - Erros de conexão/timeout → [NetworkFailure].
  /// - Demais [DioException] → [ApiFailure] com o `statusCode` (sem body legível).
  /// - Qualquer outro erro → [ServerFailure].
  ///
  /// Usado por [runTask] no `catch`. É aditivo: como todas as variantes são
  /// [AppFailure], o código existente que só lê `.message` segue funcionando.
  static AppFailure mapError(Object error) {
    if (error is AppFailure) return error;

    if (error is DioException) {
      final problem = _problemDetail(error);
      if (problem != null) return problem;

      if (_isConnectivityError(error)) {
        return NetworkFailure(
          'Sem conexão com o servidor. Verifique sua internet e tente novamente.',
          cause: error,
        );
      }

      return ApiFailure(
        _formatDio(error),
        status: error.response?.statusCode,
        code: _errorCode(error),
        cause: error,
      );
    }

    return ServerFailure(format(error), cause: error);
  }

  /// Código de erro do backend (`{ code: "..." }`), quando presente no corpo.
  static String? _errorCode(DioException error) {
    final data = error.response?.data;
    if (data is! Map) return null;
    final odata = data['error'];
    final code = odata is Map ? odata['code'] : data['code'];
    return code is String && code.isNotEmpty ? code : null;
  }

  /// Mensagem de um erro do SAP Gateway (OData V2), nos dois formatos que ele
  /// devolve:
  ///
  /// - JSON: `{"error": {"code", "message": {"lang", "value"},
  ///   "innererror": {"errordetails": [{"message"}]}}}`;
  /// - XML: `<error><code/><message xml:lang="pt">...</message></error>`,
  ///   que chega como `String` quando o Gateway ignora o `Accept`.
  ///
  /// Sem isto, o `error` do JSON é um `Map` e não uma `String`, e o 500 do SAP
  /// virava só "Erro interno do servidor" — a mensagem real do ABAP (o que o
  /// conferente ou o suporte precisam ler) se perdia.
  static String? _odataMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is! Map) return null;

      final message = error['message'];
      final principal = switch (message) {
        {'value': final String value} => value.trim(),
        String() => message.trim(),
        _ => '',
      };

      // As mensagens detalhadas do ABAP (BAPIRET/message container) vêm em
      // `errordetails`. A principal costuma ser a primeira delas; as demais
      // entram só se acrescentarem algo.
      final detalhes = <String>[];
      final inner = error['innererror'];
      final lista = inner is Map ? inner['errordetails'] : null;
      if (lista is List) {
        for (final d in lista) {
          final m = d is Map ? d['message'] : null;
          if (m is String && m.trim().isNotEmpty) detalhes.add(m.trim());
        }
      }

      final partes = <String>{
        if (principal.isNotEmpty) principal,
        ...detalhes,
      };
      return partes.isEmpty ? null : partes.join(' — ');
    }

    if (data is String && data.contains('<message')) {
      final match = RegExp(
        r'<message[^>]*>([\s\S]*?)</message>',
      ).firstMatch(data);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }

  /// Corpo HTML (página de erro do ICM/ICF, short dump). Devolvido cru, ele
  /// despejaria a página inteira na tela; o `<title>` é o que identifica o
  /// erro.
  static String? _htmlTitle(String data) {
    if (!RegExp(r'<html', caseSensitive: false).hasMatch(data)) return null;
    final title = RegExp(
      r'<title[^>]*>([\s\S]*?)</title>',
      caseSensitive: false,
    ).firstMatch(data)?.group(1)?.trim();
    return title == null || title.isEmpty ? '' : title;
  }

  /// Lê um corpo `problem+json` de uma resposta de erro, quando presente.
  static ApiFailure? _problemDetail(DioException error) {
    final response = error.response;
    if (response == null) return null;

    final data = response.data;
    if (data is! Map) return null;

    final map = data.cast<String, dynamic>();
    final title = map['title']?.toString();
    final detail = map['detail']?.toString();
    final status = (map['status'] as num?)?.toInt() ?? response.statusCode;

    // Só tratamos como problem+json se houver pelo menos title/detail.
    if (title == null && detail == null) return null;

    final message =
        [title, detail].where((e) => e != null && e.isNotEmpty).join(' — ');
    return ApiFailure(
      message.isEmpty ? 'Erro ${status ?? ''}'.trim() : message,
      status: status,
      title: title,
      detail: detail,
      code: _errorCode(error),
      cause: error,
    );
  }

  static bool _isConnectivityError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.unknown:
        return error.response == null;
      default:
        return false;
    }
  }

  /// Extracts the most meaningful message from a [DioException], preferring the
  /// backend response body (Spring's default error shape carries the exception
  /// message under `message`/`error`/`detail`).
  static String _formatDio(DioException error) {
    final data = error.response?.data;
    final status = error.response?.statusCode;

    final odata = _odataMessage(data);
    if (odata != null) return odata;

    if (data is String) {
      final title = _htmlTitle(data);
      if (title != null) {
        final prefixo = status == null ? 'Erro' : 'Erro $status';
        return title.isEmpty ? prefixo : '$prefixo: $title';
      }
    }

    if (data is Map) {
      for (final key in const ['message', 'detail', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    // No usable body — fall back to a status-aware message.
    switch (status) {
      case 400:
        return 'Requisição inválida';
      case 401:
        return 'Não autenticado';
      case 403:
        return 'Acesso negado';
      case 404:
        return 'Recurso não encontrado';
      case 409:
        return 'Conflito: o recurso já existe ou não pode ser alterado';
      case 422:
        return 'Dados inválidos';
      case 500:
        return 'Erro interno do servidor';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Tempo de conexão esgotado';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Falha de conexão com o servidor';
    }

    final message = error.message;
    if (message != null && message.isNotEmpty) return message;
    return 'Ocorreu um erro inesperado';
  }
}
