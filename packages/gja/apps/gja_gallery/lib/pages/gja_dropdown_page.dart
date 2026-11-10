import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaDropdown": uma lista de situações sob um campo de status, na
/// largura dele, e uma lista de ações sob um botão de ícone, na largura
/// mínima.
class GjaDropdownPage extends StatefulWidget {
  /// Cria a página.
  const GjaDropdownPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaDropdown';

  /// Rota nomeada.
  static const route = '/gja-dropdown';

  /// Rótulo do botão de status para a situação [label].
  static String status(String label) => 'Status: $label';

  @override
  State<GjaDropdownPage> createState() => _GjaDropdownPageState();
}

const _statuses = [
  GjaDropdownItem(
    key: 'aberto',
    text: 'Em aberto',
    icon: GjaIcons.pending,
    additionalText: '8',
  ),
  GjaDropdownItem(
    key: 'aprovado',
    text: 'Aprovado',
    icon: GjaIcons.sysEnter2,
    additionalText: '12',
  ),
  GjaDropdownItem(
    key: 'rejeitado',
    text: 'Rejeitado',
    icon: GjaIcons.error,
    additionalText: '3',
  ),
  GjaDropdownItem(
    key: 'arquivado',
    text: 'Arquivado',
    icon: GjaIcons.folderBlank,
    enabled: false,
  ),
];

const _actions = [
  GjaDropdownItem(key: 'editar', text: 'Editar', icon: GjaIcons.edit),
  GjaDropdownItem(key: 'copiar', text: 'Copiar', icon: GjaIcons.copy),
  GjaDropdownItem(key: 'excluir', text: 'Excluir', icon: GjaIcons.delete),
];

class _GjaDropdownPageState extends State<GjaDropdownPage> {
  final _status = GjaPopoverController();
  final _more = GjaPopoverController();
  String _selected = 'aberto';
  String? _action;

  @override
  void dispose() {
    _status.dispose();
    _more.dispose();
    super.dispose();
  }

  String get _label =>
      _statuses.firstWhere((item) => item.key == _selected).text;

  @override
  Widget build(BuildContext context) {
    final action = _action;
    return GjaPage(
      title: GjaDropdownPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Listas ancoradas no modelo do sap.m.Select'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaText(
              'Setas, Home, End e a primeira letra navegam pelos itens; Enter '
              'escolhe e Esc fecha.',
            ),
            GjaHBox(
              gap: GjaSpace.m,
              items: [
                GjaDropdown<String>(
                  controller: _status,
                  semanticLabel: 'Status',
                  selectedKey: _selected,
                  items: _statuses,
                  onSelectionChange: (value) =>
                      setState(() => _selected = value),
                  child: _StatusField(
                    label: GjaDropdownPage.status(_label),
                    onPressed: _status.toggle,
                  ),
                ),
                GjaDropdown<String>(
                  controller: _more,
                  semanticLabel: 'Mais ações',
                  items: _actions,
                  onSelectionChange: (value) => setState(() => _action = value),
                  child: GjaButton(
                    icon: GjaIcons.overflow,
                    tooltip: 'Mais ações',
                    onPress: _more.toggle,
                    type: GjaButtonType.transparent,
                  ),
                ),
              ],
            ),
            if (action != null)
              GjaText(
                'Ação: ${_actions.firstWhere((item) => item.key == action).text}',
              ),
          ],
        ),
      ],
    );
  }
}

/// Campo de status acionável, no formato de um futuro `GjaSelect`: a lista
/// do dropdown fica na largura dele.
class _StatusField extends StatelessWidget {
  const _StatusField({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    return SizedBox(
      width: theme.spacing.xxxl * 6,
      child: MergeSemantics(
        child: GjaInteractable(
          semanticLabel: label,
          onPressed: onPressed,
          builder: (context, states) => SizedBox(
            width: double.infinity,
            child: GjaContainer(
              surface: GjaSurface.base,
              border: true,
              radius: GjaRadius.field,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: theme.density.controlHeight,
                ),
                child: GjaSpacing.padding(
                  horizontal: GjaSpace.m,
                  child: Row(
                    children: [
                      Expanded(
                        child: ExcludeSemantics(child: GjaText(label)),
                      ),
                      const GjaIcon(GjaIcons.slimArrowDown),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
