import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaSideNavigation": navegação com subitens e itens fixos, que
/// pode ser recolhida.
class GjaSideNavigationPage extends StatefulWidget {
  /// Cria a página.
  const GjaSideNavigationPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaSideNavigation';

  /// Rota nomeada.
  static const route = '/gja-side-navigation';

  @override
  State<GjaSideNavigationPage> createState() =>
      _GjaSideNavigationPageState();
}

class _GjaSideNavigationPageState extends State<GjaSideNavigationPage> {
  String _page = 'inicio';
  String _text = 'Início';
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaSideNavigationPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Navegação lateral no modelo do sap.tnt.SideNavigation',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaButton(
          text: _expanded ? 'Recolher' : 'Expandir',
          onPress: () => setState(() => _expanded = !_expanded),
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        SizedBox(
          height: 420,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GjaSideNavigation<String>(
                semanticLabel: 'Navegação principal',
                selectedKey: _page,
                expanded: _expanded,
                onItemSelect: (key) => setState(() {
                  _page = key;
                  _text = _texts[key]!;
                }),
                items: const [
                  GjaNavigationListItem(
                    key: 'inicio',
                    text: 'Início',
                    icon: GjaIcons.home,
                  ),
                  GjaNavigationListItem(
                    key: 'vendas',
                    text: 'Vendas',
                    icon: GjaIcons.document,
                    selectable: false,
                    items: [
                      GjaNavigationListItem(key: 'pedidos', text: 'Pedidos'),
                      GjaNavigationListItem(key: 'faturas', text: 'Faturas'),
                    ],
                  ),
                  GjaNavigationListItem(
                    key: 'clientes',
                    text: 'Clientes',
                    icon: GjaIcons.personPlaceholder,
                  ),
                  GjaNavigationListItem(
                    key: 'relatorios',
                    text: 'Relatórios',
                    icon: GjaIcons.folderBlank,
                    enabled: false,
                  ),
                ],
                fixedItems: const [
                  GjaNavigationListItem(
                    key: 'configuracoes',
                    text: 'Configurações',
                    icon: GjaIcons.actionSettings,
                  ),
                  GjaNavigationListItem(
                    key: 'ajuda',
                    text: 'Ajuda',
                    icon: GjaIcons.sysHelp,
                  ),
                ],
              ),
              const GjaSpacing.horizontal(GjaSpace.l),
              Expanded(child: GjaText('Página: $_text')),
            ],
          ),
        ),
      ],
    );
  }
}

const _texts = {
  'inicio': 'Início',
  'pedidos': 'Pedidos',
  'faturas': 'Faturas',
  'clientes': 'Clientes',
  'configuracoes': 'Configurações',
  'ajuda': 'Ajuda',
};
