import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaSeparator": separadores horizontais entre itens de uma coluna
/// e um separador vertical entre ações de um `GjaBar`.
class GjaSeparatorPage extends StatelessWidget {
  /// Cria a página.
  const GjaSeparatorPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaSeparator';

  /// Rota nomeada.
  static const route = '/gja-separator';

  /// Chave da coluna com separadores horizontais.
  static const listKey = Key('separator-list');

  /// Chave da barra com separador vertical.
  static const barKey = Key('separator-bar');

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Separadores no modelo do sap.m.ToolbarSeparator'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Horizontal',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            const GjaVBox(
              key: listKey,
              gap: GjaSpace.s,
              items: [
                GjaText('Item 1'),
                GjaSeparator(),
                GjaText('Item 2'),
                GjaSeparator(),
                GjaText('Item 3'),
              ],
            ),
            const GjaTitle(
              'Vertical numa barra',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaBar(
              key: barKey,
              contentLeft: [
                GjaButton(text: 'Salvar', onPress: () {}),
                const GjaSeparator.vertical(),
                GjaButton(text: 'Copiar', onPress: () {}),
                GjaButton(text: 'Excluir', onPress: () {}),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
