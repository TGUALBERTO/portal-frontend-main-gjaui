import 'package:file_saver/file_saver.dart';

/// PDF de DANFEs ou planilha: extensão e tipos MIME para os diálogos de salvar.
enum TipoArquivo {
  pdf('pdf', 'application/pdf', 'PDF', MimeType.pdf),
  xlsx('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Planilha Excel', MimeType.microsoftExcel),
  outro('', 'application/octet-stream', 'Arquivo', MimeType.other);

  const TipoArquivo(this.extensao, this.mime, this.descricao, this.mimeType);

  final String extensao;
  final String mime;
  final String descricao;
  final MimeType mimeType;

  static TipoArquivo de(String nome) {
    final ext = nome.contains('.') ? nome.split('.').last.toLowerCase() : '';
    return TipoArquivo.values.firstWhere((t) => t.extensao == ext, orElse: () => outro);
  }

  String semExtensao(String nome) =>
      extensao.isNotEmpty && nome.toLowerCase().endsWith('.$extensao')
          ? nome.substring(0, nome.length - extensao.length - 1)
          : nome;
}
