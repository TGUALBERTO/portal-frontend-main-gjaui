import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaDialog": um diálogo de confirmação que mostra o resultado e
/// um diálogo de erro.
class GjaDialogPage extends StatefulWidget {
  /// Cria a página.
  const GjaDialogPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaDialog';

  /// Rota nomeada.
  static const route = '/gja-dialog';

  /// Texto do botão que abre a confirmação.
  static const delete = 'Excluir pedido';

  /// Texto mostrado depois de confirmar.
  static const deleted = 'Pedido excluído';

  @override
  State<GjaDialogPage> createState() => _GjaDialogPageState();
}

class _GjaDialogPageState extends State<GjaDialogPage> {
  String? _result;

  Future<void> _confirm() async {
    final confirmed = await GjaDialog.open<bool>(
      context,
      builder: (context) => GjaDialog(
        title: 'Excluir o pedido 4711?',
        state: GjaValueState.warning,
        content: const GjaText(
          'O pedido e os itens dele serão excluídos. Não é possível desfazer.',
        ),
        beginButton: GjaButton(
          text: 'Excluir',
          type: GjaButtonType.emphasized,
          onPress: () => Navigator.of(context).pop(true),
        ),
        endButton: GjaButton(
          text: 'Cancelar',
          onPress: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    if (!mounted) return;
    setState(
      () => _result = confirmed == true ? GjaDialogPage.deleted : 'Cancelado',
    );
  }

  Future<void> _error() => GjaDialog.open<void>(
    context,
    builder: (context) => GjaDialog(
      title: 'Falha ao salvar',
      state: GjaValueState.error,
      content: const GjaText('O servidor não respondeu. Tente de novo.'),
      endButton: GjaButton(
        text: 'Fechar',
        onPress: () => Navigator.of(context).pop(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return GjaPage(
      title: GjaDialogPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Diálogos modais no modelo do sap.m.Dialog'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaHBox(
          items: [
            GjaButton(text: GjaDialogPage.delete, onPress: _confirm),
            GjaButton(text: 'Mostrar erro', onPress: _error),
          ],
        ),
        if (result != null) ...[
          const GjaSpacing.vertical(GjaSpace.l),
          GjaText(result),
        ],
      ],
    );
  }
}
