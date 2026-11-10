import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';

import 'destino_arquivo_io.dart'
    if (dart.library.js_interop) 'destino_arquivo_web.dart' as plataforma;

/// Onde o arquivo gerado vai ser gravado, escolhido pelo usuário.
abstract interface class DestinoArquivo {
  /// Grava o arquivo no destino escolhido. `false` quando não gravou.
  Future<bool> gravar(ArquivoGerado arquivo);

  /// A geração falhou depois da escolha: apaga o arquivo vazio que o diálogo
  /// já criou, quando a plataforma permite.
  Future<void> descartar();
}

/// Pergunta onde salvar, sugerindo [nomeSugerido] (com extensão). `null` quando
/// o usuário cancela. Injetável para os controllers serem testados sem plugin.
typedef EscolherDestino = Future<DestinoArquivo?> Function(String nomeSugerido);

/// Abre o "Salvar como" ANTES da geração, em todas as plataformas (na web o
/// navegador só permite o diálogo logo após o clique, e o PDF pode levar
/// minutos). Navegador sem suporte (Firefox, Safari) cai no download comum.
Future<DestinoArquivo?> escolherDestino(String nomeSugerido) =>
    plataforma.escolherDestino(nomeSugerido);

/// `<yyyymm>_<nome>_<matricula>.<ext>`, com a mesma normalização do nome que
/// a API devolve no `Content-Disposition` (sem acento nem caractere inválido).
String nomeArquivoVolume(String periodo, String nome, String matricula, String extensao) {
  const de = 'ÁÀÂÃÄáàâãäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÕÖóòôõöÚÙÛÜúùûüÇçÑñ';
  const para = 'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNn';
  final semAcento = StringBuffer();
  for (final c in nome.split('')) {
    final i = de.indexOf(c);
    semAcento.write(i >= 0 ? para[i] : c);
  }
  final limpo = semAcento
      .toString()
      .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return '${periodo}_${limpo}_$matricula.$extensao';
}
