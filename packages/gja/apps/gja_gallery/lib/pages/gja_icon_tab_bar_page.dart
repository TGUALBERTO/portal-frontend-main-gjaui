import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaIconTabBar": abas de texto e abas com ícone e contagem.
class GjaIconTabBarPage extends StatefulWidget {
  /// Cria a página.
  const GjaIconTabBarPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaIconTabBar';

  /// Rota nomeada.
  static const route = '/gja-icon-tab-bar';

  /// Conteúdo da aba "Anexos".
  static const attachments = 'Contrato.pdf e Nota fiscal.xml';

  @override
  State<GjaIconTabBarPage> createState() => _GjaIconTabBarPageState();
}

class _GjaIconTabBarPageState extends State<GjaIconTabBarPage> {
  String _text = 'itens';
  String _icons = 'abertos';

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaIconTabBarPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Abas no modelo do sap.m.IconTabBar'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.xl,
          alignItems: GjaFlexAlignItems.stretch,
          items: [
            GjaIconTabBar<String>(
              selectedKey: _text,
              onSelect: (key) => setState(() => _text = key),
              items: const [
                GjaIconTabFilter(
                  key: 'itens',
                  text: 'Itens',
                  content: GjaText('12 itens no pedido 4711.'),
                ),
                GjaIconTabFilter(
                  key: 'notas',
                  text: 'Notas',
                  content: GjaText('Entregar no período da manhã.'),
                ),
                GjaIconTabFilter(
                  key: 'anexos',
                  text: 'Anexos',
                  content: GjaText(GjaIconTabBarPage.attachments),
                ),
              ],
            ),
            GjaIconTabBar<String>(
              selectedKey: _icons,
              onSelect: (key) => setState(() => _icons = key),
              items: const [
                GjaIconTabFilter(
                  key: 'abertos',
                  text: 'Abertos',
                  icon: GjaIcons.pending,
                  count: '8',
                  content: GjaText('8 pedidos abertos.'),
                ),
                GjaIconTabFilter(
                  key: 'aprovados',
                  text: 'Aprovados',
                  icon: GjaIcons.sysEnter2,
                  count: '21',
                  content: GjaText('21 pedidos aprovados.'),
                ),
                GjaIconTabFilter(
                  key: 'arquivados',
                  text: 'Arquivados',
                  icon: GjaIcons.folderBlank,
                  enabled: false,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
