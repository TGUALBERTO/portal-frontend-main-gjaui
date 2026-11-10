import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import 'package:gjamobile/src/utils/logger.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/salvar_arquivo.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/tipo_arquivo.dart';

/// Windows/Android: o diálogo do sistema abre antes da geração. O plugin exige
/// bytes, então o arquivo é criado vazio no local escolhido e sobrescrito com
/// `dart:io` quando a API responder — o que também evita a gravação em modo
/// texto do plugin no Windows, que corromperia o PDF.
Future<DestinoArquivo?> escolherDestino(String nomeSugerido) async {
  final tipo = TipoArquivo.de(nomeSugerido);
  final caminho = await FileSaver.instance.saveAs(
    name: tipo.semExtensao(nomeSugerido),
    bytes: Uint8List(0),
    ext: tipo.extensao,
    mimeType: tipo.mimeType,
  );
  if (caminho == null || caminho.isEmpty) return null;
  return _ArquivoEscolhido(File(caminho), nomeSugerido);
}

class _ArquivoEscolhido implements DestinoArquivo {
  _ArquivoEscolhido(this.arquivo, this.nome);

  final File arquivo;
  final String nome;

  @override
  Future<bool> gravar(ArquivoGerado gerado) async {
    try {
      await arquivo.writeAsBytes(gerado.bytes, flush: true);
      return true;
    } on FileSystemException catch (e) {
      // Android: o caminho que o plugin resolve do documento escolhido pode não
      // ser gravável (armazenamento restrito). Grava em Downloads.
      if (!Platform.isAndroid) rethrow;
      AppLogger.warning('rhprocesso: ${arquivo.path} não gravável ($e); salvando em Downloads');
      final tipo = TipoArquivo.de(nome);
      await FileSaver.instance.saveFile(
        name: tipo.semExtensao(nome),
        bytes: gerado.bytes,
        ext: tipo.extensao,
        mimeType: tipo.mimeType,
      );
      return true;
    }
  }

  @override
  Future<void> descartar() async {
    try {
      if (await arquivo.exists() && await arquivo.length() <= 1) await arquivo.delete();
    } catch (_) {
      // Sem permissão para apagar: fica o arquivo vazio.
    }
  }
}
