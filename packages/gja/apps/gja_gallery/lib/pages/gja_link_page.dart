import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaLink": variantes, um link com quebra e "Ver pedido 4711",
/// que mostra uma mensagem ao ser acionado.
class GjaLinkPage extends StatefulWidget {
  /// Cria a página.
  const GjaLinkPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaLink';

  /// Rota nomeada.
  static const route = '/gja-link';

  /// Texto do link de exemplo e a mensagem que ele mostra.
  static const orderLink = 'Ver pedido 4711';

  /// Mensagem mostrada ao acionar [orderLink].
  static const opened = 'Pedido 4711 aberto';

  @override
  State<GjaLinkPage> createState() => _GjaLinkPageState();
}

class _GjaLinkPageState extends State<GjaLinkPage> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaLinkPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Navegação secundária e referências a objetos'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Variantes',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaLink(
              text: GjaLinkPage.orderLink,
              onPress: () => setState(() => _opened = true),
            ),
            if (_opened) const GjaText(GjaLinkPage.opened),
            GjaLink(text: 'Link sutil', subtle: true, onPress: () {}),
            GjaLink(
              text: 'Link enfatizado',
              emphasized: true,
              onPress: () {},
            ),
            const GjaLink(text: 'Link desabilitado', enabled: false),
            const GjaTitle(
              'Com quebra',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            SizedBox(
              width: 240,
              child: GjaLink(
                text:
                    'Ver todos os pedidos aguardando aprovação do gestor do '
                    'centro de custo',
                wrapping: true,
                onPress: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
