import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaMessageStrip": uma faixa de cada tipo, uma com link e uma que
/// pode ser fechada.
class GjaMessageStripPage extends StatefulWidget {
  /// Cria a página.
  const GjaMessageStripPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaMessageStrip';

  /// Rota nomeada.
  static const route = '/gja-message-strip';

  /// Texto da faixa que pode ser fechada.
  static const closable = 'Esta faixa pode ser fechada.';

  @override
  State<GjaMessageStripPage> createState() => _GjaMessageStripPageState();
}

class _GjaMessageStripPageState extends State<GjaMessageStripPage> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaMessageStripPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Mensagens no modelo do sap.m.MessageStrip'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.s,
          alignItems: GjaFlexAlignItems.stretch,
          items: [
            for (final type in GjaValueState.values)
              GjaMessageStrip(
                text: 'Mensagem do tipo ${type.name}.',
                type: type,
                showIcon: true,
              ),
            GjaMessageStrip(
              text: 'O pedido 4711 aguarda aprovação.',
              type: GjaValueState.warning,
              showIcon: true,
              link: GjaLink(text: 'Abrir pedido', onPress: () {}),
            ),
            if (_visible)
              GjaMessageStrip(
                text: GjaMessageStripPage.closable,
                showCloseButton: true,
                onClose: () => setState(() => _visible = false),
              ),
          ],
        ),
      ],
    );
  }
}
