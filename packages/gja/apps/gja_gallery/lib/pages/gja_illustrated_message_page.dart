import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaIllustratedMessage": os tipos em tamanho `spot`, uma
/// mensagem `dialog` e uma de busca sem resultados com a ação "Limpar
/// filtros", que mostra a lista.
class GjaIllustratedMessagePage extends StatefulWidget {
  /// Cria a página.
  const GjaIllustratedMessagePage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaIllustratedMessage';

  /// Rota nomeada.
  static const route = '/gja-illustrated-message';

  /// Texto da ação que limpa os filtros.
  static const clear = 'Limpar filtros';

  /// Texto mostrado depois de limpar os filtros.
  static const list = 'Pedidos 4711, 4712 e 4713';

  @override
  State<GjaIllustratedMessagePage> createState() =>
      _GjaIllustratedMessagePageState();
}

class _GjaIllustratedMessagePageState
    extends State<GjaIllustratedMessagePage> {
  bool _filtered = true;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaIllustratedMessagePage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Estados vazios no modelo do sap.m.IllustratedMessage'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.xl,
          alignItems: GjaFlexAlignItems.stretch,
          items: [
            if (_filtered)
              GjaIllustratedMessage(
                illustrationType: GjaIllustrationType.noFilterResults,
                title: 'Nenhum pedido com esses filtros',
                description: 'Limpe os filtros para ver todos os pedidos.',
                additionalContent: [
                  GjaButton(
                    text: GjaIllustratedMessagePage.clear,
                    type: GjaButtonType.emphasized,
                    onPress: () => setState(() => _filtered = false),
                  ),
                ],
              )
            else
              const GjaText(GjaIllustratedMessagePage.list),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              gap: GjaSpace.l,
              items: [
                for (final type in GjaIllustrationType.values)
                  SizedBox(
                    width: 160,
                    child: GjaIllustratedMessage(
                      title: type.name,
                      illustrationType: type,
                      illustrationSize: GjaIllustrationSize.spot,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
