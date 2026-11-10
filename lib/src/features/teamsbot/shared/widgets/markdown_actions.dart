import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Exibe o Markdown bruto num diálogo, com opção de copiar.
Future<void> mostrarMarkdownBruto(int id, String markdown) {
  return showAppDialog<void>(
    child: _RawMarkdownDialog(id: id, markdown: markdown),
  );
}

/// Baixa o conteúdo Markdown como `ata-{id}.md`.
Future<void> baixarMarkdown(int id, String markdown) async {
  try {
    final bytes = Uint8List.fromList(utf8.encode(markdown));
    await FileSaver.instance.saveFile(
      name: 'ata-$id',
      bytes: bytes,
      ext: 'md',
      mimeType: MimeType.text,
    );
    showGlobalToast(
        message: 'Download de ata-$id.md iniciado.', status: 'success');
  } catch (e) {
    showGlobalToast(message: 'Não foi possível baixar o arquivo.', status: 'error');
  }
}

/// Baixa a ATA em Word como `ata-{id}.docx` (formato executivo do template GJA).
Future<void> baixarWord(int id, Uint8List bytes) async {
  try {
    await FileSaver.instance.saveFile(
      name: 'ata-$id',
      bytes: bytes,
      ext: 'docx',
      mimeType: MimeType.microsoftWord,
    );
    showGlobalToast(
        message: 'Download de ata-$id.docx iniciado.', status: 'success');
  } catch (e) {
    showGlobalToast(message: 'Não foi possível baixar o arquivo.', status: 'error');
  }
}

class _RawMarkdownDialog extends StatelessWidget {
  const _RawMarkdownDialog({required this.id, required this.markdown});

  final int id;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Markdown bruto'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: SingleChildScrollView(
          child: SelectableText(
            markdown,
            style:
                context.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        AppButton(
          label: 'Copiar',
          variant: ButtonVariant.secondary,
          width: ButtonSize.small,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: markdown));
            showGlobalToast(message: 'Markdown copiado.', status: 'success');
          },
        ),
      ],
    );
  }
}
