import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaSelect": campos interativos, um com ícones nos itens, um com
/// espaço reservado e campos com estado de valor, somente leitura e
/// desabilitado.
class GjaSelectPage extends StatefulWidget {
  /// Cria a página.
  const GjaSelectPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaSelect';

  /// Rota nomeada.
  static const route = '/gja-select';

  /// Rótulo do campo de status.
  static const statusLabel = 'Status';

  /// Itens de status.
  static const statuses = [
    GjaDropdownItem(key: 'aberto', text: 'Em aberto'),
    GjaDropdownItem(key: 'aprovado', text: 'Aprovado'),
    GjaDropdownItem(key: 'recusado', text: 'Recusado'),
  ];

  @override
  State<GjaSelectPage> createState() => _GjaSelectPageState();
}

class _GjaSelectPageState extends State<GjaSelectPage> {
  String _status = 'aberto';
  String? _sort;
  String? _priority;

  @override
  Widget build(BuildContext context) {
    Widget field(String label, Widget select) => GjaVBox(
      gap: GjaSpace.xxs,
      alignItems: GjaFlexAlignItems.stretch,
      items: [GjaLabel(label), select],
    );
    return GjaPage(
      title: GjaSelectPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Campos de seleção no modelo do sap.m.Select'),
        const GjaSpacing.vertical(GjaSpace.l),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GjaVBox(
              gap: GjaSpace.m,
              alignItems: GjaFlexAlignItems.stretch,
              items: [
                field(
                  GjaSelectPage.statusLabel,
                  GjaSelect<String>(
                    semanticLabel: GjaSelectPage.statusLabel,
                    items: GjaSelectPage.statuses,
                    selectedKey: _status,
                    onChange: (value) => setState(() => _status = value),
                  ),
                ),
                field(
                  'Ordenar por',
                  GjaSelect<String>(
                    semanticLabel: 'Ordenar por',
                    placeholder: 'Escolha a ordem',
                    selectedKey: _sort,
                    onChange: (value) => setState(() => _sort = value),
                    items: const [
                      GjaDropdownItem(
                        key: 'data',
                        text: 'Data',
                        icon: GjaIcons.calendar,
                      ),
                      GjaDropdownItem(
                        key: 'valor',
                        text: 'Valor',
                        icon: GjaIcons.sort,
                      ),
                    ],
                  ),
                ),
                field(
                  'Prioridade',
                  GjaSelect<String>(
                    semanticLabel: 'Prioridade',
                    selectedKey: _priority,
                    valueState: _priority == null
                        ? GjaValueState.error
                        : GjaValueState.none,
                    valueStateText: 'Escolha uma prioridade',
                    onChange: (value) => setState(() => _priority = value),
                    items: const [
                      GjaDropdownItem(key: 'alta', text: 'Alta'),
                      GjaDropdownItem(key: 'baixa', text: 'Baixa'),
                    ],
                  ),
                ),
                field(
                  'Somente leitura',
                  GjaSelect<String>(
                    semanticLabel: 'Somente leitura',
                    items: GjaSelectPage.statuses,
                    selectedKey: 'aprovado',
                    editable: false,
                  ),
                ),
                field(
                  'Desabilitado',
                  GjaSelect<String>(
                    semanticLabel: 'Desabilitado',
                    items: GjaSelectPage.statuses,
                    selectedKey: 'recusado',
                    enabled: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
