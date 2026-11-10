import 'dart:typed_data';

/// Arquivo gerado pela API (PDF de DANFEs ou planilha), pronto para salvar.
class ArquivoGerado {
  const ArquivoGerado({
    required this.nome,
    required this.bytes,
    this.aviso,
  });

  /// Nome informado no `Content-Disposition` (`<yyyymm>_<nome>_<mat>.pdf`).
  final String nome;
  final Uint8List bytes;

  /// `X-Rhprocesso-Aviso`: o arquivo saiu, mas sem parte dos dados (ex.: o SAP
  /// não respondeu e os DANFEs ficaram sem chave e protocolo).
  final String? aviso;

  /// Nome sem a extensão, como o `FileSaver` espera.
  String get nomeBase {
    final i = nome.lastIndexOf('.');
    return i > 0 ? nome.substring(0, i) : nome;
  }

  String get extensao {
    final i = nome.lastIndexOf('.');
    return i > 0 ? nome.substring(i + 1) : '';
  }
}
