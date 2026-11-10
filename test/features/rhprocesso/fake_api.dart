import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';

/// Resposta configurada no [FakeApi].
class RespostaFake {
  RespostaFake.json(Object? corpo, {this.status = 200, this.headers = const {}})
      : bytes = utf8.encode(jsonEncode(corpo)),
        contentType = 'application/json';

  RespostaFake.bytes(this.bytes, {this.status = 200, this.headers = const {}, this.contentType = 'application/pdf'});

  final List<int> bytes;
  final int status;
  final String contentType;
  final Map<String, String> headers;
}

/// `rhprocesso-api` em memória: responde por `MÉTODO /path` e guarda as
/// requisições para o teste conferir path, query e corpo.
class FakeApi implements HttpClientAdapter {
  final Map<String, RespostaFake> respostas = {};
  final List<RequestOptions> requisicoes = [];

  void quando(String metodoEPath, RespostaFake resposta) =>
      respostas[metodoEPath] = resposta;

  RhprocessoDio get dio => RhprocessoDio(
        Dio(BaseOptions(baseUrl: 'https://api-rhprocesso.test'))
          ..httpClientAdapter = this,
      );

  RequestOptions get ultima => requisicoes.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requisicoes.add(options);
    final r = respostas['${options.method} ${options.uri.path}'];
    if (r == null) {
      return ResponseBody.fromString(
        '{"code":"NAO_ENCONTRADO","message":"rota nao configurada no fake"}',
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromBytes(
      r.bytes,
      r.status,
      headers: {
        Headers.contentTypeHeader: [r.contentType],
        for (final h in r.headers.entries) h.key: [h.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
