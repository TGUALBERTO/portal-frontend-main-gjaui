import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaToolbar": uma barra de cabeçalho de tabela, uma barra de
/// informação acionável e os desenhos.
class GjaToolbarPage extends StatefulWidget {
  /// Cria a página.
  const GjaToolbarPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaToolbar';

  /// Rota nomeada.
  static const route = '/gja-toolbar';

  /// Texto da barra de informação.
  static const filters = '2 filtros ativos: Status, Data';

  /// Texto mostrado depois de tocar a barra de informação.
  static const cleared = 'Filtros limpos';

  @override
  State<GjaToolbarPage> createState() => _GjaToolbarPageState();
}

class _GjaToolbarPageState extends State<GjaToolbarPage> {
  bool _cleared = false;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaToolbarPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Barras de ferramentas no modelo do sap.m.Toolbar'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          alignItems: GjaFlexAlignItems.stretch,
          items: [
            GjaToolbar(
              content: [
                const GjaTitle(
                  'Pedidos (12)',
                  titleStyle: GjaTitleLevel.h5,
                ),
                const Spacer(),
                GjaButton(
                  icon: GjaIcons.add,
                  tooltip: 'Novo pedido',
                  type: GjaButtonType.transparent,
                  onPress: () {},
                ),
                GjaButton(
                  icon: GjaIcons.sort,
                  tooltip: 'Ordenar',
                  type: GjaButtonType.transparent,
                  onPress: () {},
                ),
                const GjaSeparator.vertical(),
                GjaButton(
                  icon: GjaIcons.actionSettings,
                  tooltip: 'Configurações',
                  type: GjaButtonType.transparent,
                  onPress: () {},
                ),
              ],
            ),
            if (_cleared)
              const GjaText(GjaToolbarPage.cleared)
            else
              GjaToolbar(
                design: GjaToolbarDesign.info,
                semanticLabel: GjaToolbarPage.filters,
                onPress: () => setState(() => _cleared = true),
                content: const [GjaText(GjaToolbarPage.filters)],
              ),
            for (final design in GjaToolbarDesign.values)
              GjaToolbar(
                design: design,
                content: [GjaText('Desenho ${design.name}')],
              ),
            const GjaToolbar(
              style: GjaToolbarStyle.clear,
              content: [GjaText('Estilo clear, sem borda')],
            ),
          ],
        ),
      ],
    );
  }
}
