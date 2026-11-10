import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:file_saver/file_saver.dart';

import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/salvar_arquivo.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/tipo_arquivo.dart';

/// Web: `showSaveFilePicker` (File System Access API, Chrome/Edge) chamado já no
/// clique — depois de minutos gerando o PDF o navegador recusaria o diálogo por
/// falta de gesto do usuário. O arquivo é gravado no destino escolhido quando a
/// API responder. Sem a API (Firefox, Safari), vira download comum.
Future<DestinoArquivo?> escolherDestino(String nomeSugerido) async {
  if (!globalContext.has('showSaveFilePicker')) return _Download(nomeSugerido);

  final tipo = TipoArquivo.de(nomeSugerido);
  final opcoes = JSObject()..['suggestedName'] = nomeSugerido.toJS;
  if (tipo != TipoArquivo.outro) {
    final aceita = JSObject()..[tipo.mime] = <JSString>['.${tipo.extensao}'.toJS].toJS;
    final filtro = JSObject()
      ..['description'] = tipo.descricao.toJS
      ..['accept'] = aceita;
    opcoes['types'] = <JSObject>[filtro].toJS;
  }

  try {
    final arquivo = await globalContext
        .callMethod<JSPromise<JSObject>>('showSaveFilePicker'.toJS, opcoes)
        .toDart;
    return _ArquivoEscolhido(arquivo);
  } catch (e) {
    // AbortError: o usuário fechou o diálogo.
    if (e.toString().contains('AbortError')) return null;
    rethrow;
  }
}

class _ArquivoEscolhido implements DestinoArquivo {
  _ArquivoEscolhido(this.handle);

  final JSObject handle;

  @override
  Future<bool> gravar(ArquivoGerado arquivo) async {
    final escrita =
        await handle.callMethod<JSPromise<JSObject>>('createWritable'.toJS).toDart;
    await escrita.callMethod<JSPromise<JSAny?>>('write'.toJS, arquivo.bytes.toJS).toDart;
    await escrita.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart;
    return true;
  }

  @override
  Future<void> descartar() async {
    // `remove()` só existe no Chromium recente; sem ele fica o arquivo vazio.
    if (!handle.has('remove')) return;
    try {
      await handle.callMethod<JSPromise<JSAny?>>('remove'.toJS).toDart;
    } catch (_) {}
  }
}

/// Navegador sem `showSaveFilePicker`: download comum (onde salvar depende da
/// configuração do navegador).
class _Download implements DestinoArquivo {
  _Download(this.nome);

  final String nome;

  @override
  Future<bool> gravar(ArquivoGerado arquivo) async {
    final tipo = TipoArquivo.de(nome);
    await FileSaver.instance.saveFile(
      name: tipo.semExtensao(nome),
      bytes: arquivo.bytes,
      ext: tipo.extensao,
      mimeType: tipo.mimeType,
    );
    return true;
  }

  @override
  Future<void> descartar() async {}
}
