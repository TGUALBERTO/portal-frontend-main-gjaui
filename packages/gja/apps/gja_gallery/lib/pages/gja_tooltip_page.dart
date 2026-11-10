import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaTooltip": ícones com dica e um texto com dica longa.
class GjaTooltipPage extends StatelessWidget {
  /// Cria a página.
  const GjaTooltipPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaTooltip';

  /// Rota nomeada.
  static const route = '/gja-tooltip';

  /// Ícones de exemplo e as dicas deles.
  static const examples = [
    (GjaIcons.edit, 'Editar pedido'),
    (GjaIcons.delete, 'Excluir pedido'),
    (GjaIcons.download, 'Baixar PDF'),
  ];

  /// Chave do primeiro ícone de exemplo.
  static const firstIconKey = Key('tooltip-first-icon');

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Passe o ponteiro, foque pelo teclado ou toque longamente',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Ícones',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              gap: GjaSpace.l,
              items: [
                for (final (i, (icon, message)) in examples.indexed)
                  GjaTooltip(
                    message: message,
                    child: GjaIcon(
                      icon,
                      key: i == 0 ? firstIconKey : null,
                      tone: GjaIconTone.brand,
                      size: GjaIconSize.large,
                    ),
                  ),
              ],
            ),
            const GjaTitle(
              'Dica longa',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            const GjaTooltip(
              message:
                  'Pedidos aguardando aprovação há mais de cinco dias úteis são '
                  'enviados ao gestor do centro de custo.',
              child: GjaText('Regra de escalonamento'),
            ),
          ],
        ),
      ],
    );
  }
}
