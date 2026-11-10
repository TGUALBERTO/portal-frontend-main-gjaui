import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaMessageToast": botões que mostram avisos breves.
class GjaMessageToastPage extends StatelessWidget {
  /// Cria a página.
  const GjaMessageToastPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaMessageToast';

  /// Rota nomeada.
  static const route = '/gja-message-toast';

  /// Mensagem do botão "Salvar".
  static const saved = 'Pedido salvo';

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Avisos breves no modelo do sap.m.MessageToast'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaHBox(
          items: [
            GjaButton(
              text: 'Salvar',
              type: GjaButtonType.emphasized,
              onPress: () => GjaMessageToast.show(context, saved),
            ),
            GjaButton(
              text: 'Enviar',
              onPress: () => GjaMessageToast.show(
                context,
                'O pedido 4711 foi enviado para aprovação do gestor.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
