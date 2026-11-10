import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';

/// Cabeçalho com o aviso da API (ex.: SAP sem resposta para uma filial).
const String cabecalhoAviso = 'x-rhprocesso-aviso';

/// Nome do arquivo no `Content-Disposition`. Aceita `filename*=UTF-8''...`
/// (RFC 5987, com prioridade) e `filename="..."`. `null` se não houver.
String? nomeDoContentDisposition(String? valor) {
  if (valor == null || valor.isEmpty) return null;

  final estendido = RegExp(r"filename\*\s*=\s*[^']*''([^;]+)", caseSensitive: false)
      .firstMatch(valor);
  if (estendido != null) {
    try {
      return Uri.decodeComponent(estendido.group(1)!.trim());
    } on ArgumentError {
      // Segue para o filename simples.
    }
  }

  final simples = RegExp(r'filename\s*=\s*("([^"]*)"|[^;]+)', caseSensitive: false)
      .firstMatch(valor);
  if (simples == null) return null;
  final nome = (simples.group(2) ?? simples.group(1) ?? '').trim();
  return nome.isEmpty ? null : nome;
}

/// Monta o [ArquivoGerado] de uma resposta binária. [nomePadrao] cobre a
/// resposta sem `Content-Disposition` (o navegador pode escondê-lo se o CORS
/// não o expuser).
ArquivoGerado arquivoDaResposta(Response<List<int>> resposta, String nomePadrao) {
  final nome = nomeDoContentDisposition(
          resposta.headers.value('content-disposition')) ??
      nomePadrao;
  final aviso = resposta.headers.value(cabecalhoAviso);
  return ArquivoGerado(
    nome: nome,
    bytes: Uint8List.fromList(resposta.data ?? const []),
    aviso: aviso == null || aviso.trim().isEmpty ? null : aviso.trim(),
  );
}

/// Num download (`ResponseType.bytes`), o corpo de erro da API
/// (`{code, message, correlationId}`) chega como bytes, e o `AppErrorHandler`
/// só sabe ler a mensagem de um `Map`. Esta conversão devolve o erro com o
/// corpo já decodificado, para o usuário ver "Consultor não encontrado…" em vez
/// de um "Erro 404" genérico.
DioException comCorpoDecodificado(DioException erro) {
  final resposta = erro.response;
  final dados = resposta?.data;
  if (resposta == null || dados is! List<int>) return erro;
  try {
    final json = jsonDecode(utf8.decode(dados));
    return erro.copyWith(
      response: Response<dynamic>(
        data: json,
        statusCode: resposta.statusCode,
        statusMessage: resposta.statusMessage,
        headers: resposta.headers,
        requestOptions: resposta.requestOptions,
      ),
    );
  } on FormatException {
    return erro;
  }
}
