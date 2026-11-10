import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaTable": produtos com seleção múltipla, linhas de navegação e
/// colunas em popin.
class GjaTablePage extends StatefulWidget {
  /// Cria a página.
  const GjaTablePage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaTable';

  /// Rota nomeada.
  static const route = '/gja-table';

  @override
  State<GjaTablePage> createState() => _GjaTablePageState();
}

const _products = [
  ('teclado', 'Teclado', 'Periféricos', 'R\$ 120,00', '12'),
  ('mouse', 'Mouse', 'Periféricos', 'R\$ 45,00', '30'),
  ('monitor', 'Monitor 27"', 'Vídeo', 'R\$ 1.250,00', '4'),
  ('cabo', 'Cabo HDMI', 'Vídeo', 'R\$ 25,00', '80'),
  ('webcam', 'Webcam', 'Periféricos', 'R\$ 210,00', '7'),
];

class _GjaTablePageState extends State<GjaTablePage> {
  Set<String> _selected = const {};
  String? _opened;

  @override
  Widget build(BuildContext context) {
    final opened = _opened;
    return GjaPage(
      title: GjaTablePage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Tabela no modelo do sap.m.Table: em larguras pequenas, "Categoria" '
          'some e "Preço" desce para baixo da linha; os produtos vêm em grupos, '
          'três de cada vez (growing).',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaTable<String>(
          headerText: 'Produtos (${_products.length})',
          mode: GjaListMode.multiSelect,
          selectedKeys: _selected,
          onSelectionChange: (keys) => setState(() => _selected = keys),
          onItemPress: (key) => setState(
            () => _opened = _products.firstWhere((p) => p.$1 == key).$2,
          ),
          columns: const [
            GjaColumn(header: 'Produto', flex: 2),
            GjaColumn(
              header: 'Categoria',
              minScreenWidth: GjaSizeClass.large,
            ),
            GjaColumn(
              header: 'Preço',
              hAlign: GjaColumnHAlign.end,
              minScreenWidth: GjaSizeClass.medium,
              demandPopin: true,
            ),
            GjaColumn(header: 'Estoque', hAlign: GjaColumnHAlign.end),
          ],
          growing: true,
          growingThreshold: 3,
          items: [
            for (final group in ['Periféricos', 'Vídeo']) ...[
              GjaGroupHeaderListItem(
                title: group,
                count: '${_products.where((p) => p.$3 == group).length}',
              ),
              for (final (key, name, category, price, stock) in _products)
                if (category == group)
                  GjaColumnListItem(
                    key: key,
                    type: GjaListType.navigation,
                    cells: [
                      GjaText(name),
                      GjaText(category),
                      GjaText(price),
                      GjaText(stock),
                    ],
                  ),
            ],
          ],
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaText('${_selected.length} selecionados'),
        if (opened != null) GjaText('Aberto: $opened'),
      ],
    );
  }
}
