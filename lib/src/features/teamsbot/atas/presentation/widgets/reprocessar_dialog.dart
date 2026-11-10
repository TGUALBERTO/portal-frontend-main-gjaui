import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Abre o diálogo de confirmação de reprocessamento. Devolve `true` ao
/// confirmar, ou `null` se cancelado.
Future<bool?> showReprocessarDialog() {
  return showAppDialog<bool>(child: const _ReprocessarDialog());
}

class _ReprocessarDialog extends StatelessWidget {
  const _ReprocessarDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reprocessar ATA'),
      content: const SizedBox(
        width: 420,
        child: Text(
          'Isto vai regerar a ATA a partir da transcrição. O conteúdo atual '
          'será substituído. Deseja continuar?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(
          label: 'Reprocessar',
          prefixIcon: const Icon(GjaIcons.refresh, size: 18),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
