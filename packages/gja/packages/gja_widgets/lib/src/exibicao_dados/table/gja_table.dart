import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../formularios/check_box/gja_check_box.dart';
import '../../fundacao_layout/title/gja_title.dart';

/// Modo de seleção de uma [GjaTable], como o `mode` (`sap.m.ListMode`) do
/// SAPUI5.
enum GjaListMode {
  /// Sem seleção.
  none,

  /// Acionar uma linha a escolhe, e só ela fica escolhida.
  singleSelectMaster,

  /// Cada linha tem uma caixa de seleção, e o cabeçalho escolhe todas.
  multiSelect,
}

/// Tipo de uma linha, como o `type` (`sap.m.ListType`) do SAPUI5.
enum GjaListType {
  /// Não reage ao ponteiro nem ao teclado.
  inactive,

  /// Acionável: chama `onItemPress`.
  active,

  /// Acionável, com uma seta no fim, para abrir um detalhe.
  navigation,
}

/// Alinhamento horizontal de uma [GjaColumn], como o `hAlign` do SAPUI5.
enum GjaColumnHAlign {
  /// No início da linha (à esquerda em LTR).
  begin,

  /// No centro.
  center,

  /// No fim da linha (à direita em LTR), como números e valores.
  end,
}

/// Coluna de uma [GjaTable], como o `sap.m.Column` do SAPUI5.
///
/// É uma configuração, não um widget: use em [GjaTable.columns].
@immutable
class GjaColumn {
  /// Cria a coluna [header].
  const GjaColumn({
    required this.header,
    this.hAlign = GjaColumnHAlign.begin,
    this.flex = 1,
    this.minScreenWidth,
    this.demandPopin = false,
  });

  /// Título da coluna.
  final String header;

  /// Alinhamento do título e das células.
  final GjaColumnHAlign hAlign;

  /// Proporção da largura da tabela, no lugar do `width` em CSS do UI5.
  final int flex;

  /// Menor classe de tamanho, da largura da tabela, em que a coluna
  /// aparece; nula, aparece sempre.
  final GjaSizeClass? minScreenWidth;

  /// Se, escondida por [minScreenWidth], a célula desce para baixo da linha
  /// com o título da coluna.
  final bool demandPopin;
}

/// Item de uma [GjaTable], como o `sap.m.ListItemBase` do SAPUI5: uma
/// linha ([GjaColumnListItem]) ou um título de grupo
/// ([GjaGroupHeaderListItem]).
@immutable
sealed class GjaListItemBase<T> {
  const GjaListItemBase();
}

/// Título de grupo de uma [GjaTable], como o `sap.m.GroupHeaderListItem`
/// do SAPUI5: separa as linhas seguintes, até o próximo título.
///
/// Não pode ser escolhido nem acionado. É uma configuração, não um widget:
/// use em [GjaTable.items].
class GjaGroupHeaderListItem<T> extends GjaListItemBase<T> {
  /// Cria o título de grupo [title].
  const GjaGroupHeaderListItem({required this.title, this.count});

  /// Título do grupo.
  final String title;

  /// Contagem mostrada entre parênteses depois do título.
  final String? count;
}

/// Linha de uma [GjaTable], como o `sap.m.ColumnListItem` do SAPUI5.
///
/// É uma configuração, não um widget: use em [GjaTable.items].
class GjaColumnListItem<T> extends GjaListItemBase<T> {
  /// Cria a linha [key] com [cells].
  const GjaColumnListItem({
    required this.key,
    required this.cells,
    this.type = GjaListType.inactive,
  });

  /// Chave da linha, devolvida por `onItemPress` e `onSelectionChange`.
  final T key;

  /// Células, uma por coluna, na ordem de `columns`.
  final List<Widget> cells;

  /// Tipo da linha.
  final GjaListType type;
}

/// Tabela responsiva, como o `sap.m.Table` do SAPUI5.
///
/// Mostra os títulos de [columns] e, abaixo, as linhas de [items]. Linhas
/// `active` e `navigation` chamam [onItemPress]; com [mode], as linhas
/// podem ser escolhidas. É controlada: a seleção é [selectedKeys], e
/// mudá-la chama [onSelectionChange] com o novo conjunto, sem mudar
/// sozinha. Sem itens, mostra [noDataText].
///
/// A tabela olha a própria largura: uma coluna com `minScreenWidth` maior
/// que a classe de tamanho dela some e, com `demandPopin`, desce para baixo
/// das outras células, com o título. Pelo teclado, as setas para cima e
/// para baixo movem o foco entre as linhas acionáveis.
///
/// [items] pode ter títulos de grupo ([GjaGroupHeaderListItem]) entre as
/// linhas. Com [growing], mostra só as primeiras [growingThreshold] linhas e,
/// abaixo delas, um botão que mostra as próximas, com a contagem
/// "[mostradas / total]", como o `growing` do UI5.
///
/// ```dart
/// GjaTable<String>(
///   columns: const [
///     GjaColumn(header: 'Produto'),
///     GjaColumn(header: 'Preço', hAlign: GjaColumnHAlign.end),
///   ],
///   items: [
///     for (final p in produtos)
///       GjaColumnListItem(
///         key: p.id,
///         type: GjaListType.navigation,
///         cells: [GjaText(p.nome), GjaText(p.preco)],
///       ),
///   ],
///   onItemPress: abrir,
/// )
/// ```
class GjaTable<T> extends StatefulWidget {
  /// Cria a tabela de [columns] e [items].
  const GjaTable({
    required this.columns,
    required this.items,
    this.headerText,
    this.noDataText,
    this.mode = GjaListMode.none,
    this.selectedKeys = const {},
    this.onSelectionChange,
    this.onItemPress,
    this.growing = false,
    this.growingThreshold = 20,
    this.growingTriggerText,
    super.key,
  }) : assert(growingThreshold > 0, 'growingThreshold deve ser positivo');

  /// Colunas, da primeira à última.
  final List<GjaColumn> columns;

  /// Linhas e títulos de grupo, de cima para baixo.
  final List<GjaListItemBase<T>> items;

  /// Título acima da tabela, e nome dela para o leitor de tela.
  final String? headerText;

  /// Texto mostrado sem itens; nulo usa o `noData` da localização.
  final String? noDataText;

  /// Modo de seleção.
  final GjaListMode mode;

  /// Chaves das linhas escolhidas.
  final Set<T> selectedKeys;

  /// Chamado com a nova seleção, como o evento `selectionChange` do UI5.
  final ValueChanged<Set<T>>? onSelectionChange;

  /// Chamado com a chave da linha acionada, como o evento `itemPress` do
  /// UI5.
  final ValueChanged<T>? onItemPress;

  /// Se mostra as linhas aos poucos, com o botão de mais linhas.
  final bool growing;

  /// Linhas mostradas de início e a cada toque no botão de mais linhas.
  final int growingThreshold;

  /// Texto do botão de mais linhas; nulo usa o `more` da localização.
  final String? growingTriggerText;

  @override
  State<GjaTable<T>> createState() => _GjaTableState<T>();
}

class _GjaTableState<T> extends State<GjaTable<T>> {
  final _nodes = <T, FocusNode>{};

  /// Chaves das linhas acionáveis, na ordem, para as setas.
  List<T> _order = [];

  /// Linhas mostradas com `growing`; nulo vale `growingThreshold`.
  int? _shown;

  List<GjaColumnListItem<T>> get _rows =>
      widget.items.whereType<GjaColumnListItem<T>>().toList();

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool _actionable(GjaColumnListItem<T> item) =>
      item.type != GjaListType.inactive ||
      widget.mode == GjaListMode.singleSelectMaster;

  void _validate() {
    final columns = widget.columns;
    final items = _rows;
    assert(columns.isNotEmpty, 'columns não pode ser vazia');
    assert(
      items.every((item) => item.cells.length == columns.length),
      'cada linha precisa de uma célula por coluna',
    );
    assert(
      items.map((item) => item.key).toSet().length == items.length,
      'as chaves das linhas devem ser distintas',
    );
  }

  void _toggle(T key, bool selected) {
    final keys = {...widget.selectedKeys};
    selected ? keys.add(key) : keys.remove(key);
    widget.onSelectionChange?.call(keys);
  }

  void _press(GjaColumnListItem<T> item) {
    if (widget.mode == GjaListMode.singleSelectMaster &&
        !(widget.selectedKeys.length == 1 &&
            widget.selectedKeys.contains(item.key))) {
      widget.onSelectionChange?.call({item.key});
    }
    if (item.type != GjaListType.inactive) {
      widget.onItemPress?.call(item.key);
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final int step;
    if (key == LogicalKeyboardKey.arrowDown) {
      step = 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      step = -1;
    } else {
      return KeyEventResult.ignored;
    }
    final current = _order.indexWhere((k) => _nodes[k]?.hasFocus ?? false);
    if (current < 0) return KeyEventResult.ignored;
    final next = current + step;
    if (next >= 0 && next < _order.length) _nodes[_order[next]]!.requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _validate();
    final theme = GjaThemeData.of(context);
    final l10n = GjaLocalizations.of(context);
    final items = _rows;
    final limit = widget.growing
        ? (_shown ?? widget.growingThreshold).clamp(0, items.length)
        : items.length;
    // Linhas e títulos até a última linha mostrada; um título só aparece
    // se alguma linha dele aparece.
    final shownItems = <GjaListItemBase<T>>[];
    var count = 0;
    for (final item in widget.items) {
      if (count >= limit) break;
      shownItems.add(item);
      if (item is GjaColumnListItem<T>) count++;
    }
    final multi = widget.mode == GjaListMode.multiSelect;
    final hasNavigation = items.any(
      (item) => item.type == GjaListType.navigation,
    );
    final keys = items.map((item) => item.key).toSet();
    _nodes.removeWhere((key, node) {
      final gone = !keys.contains(key);
      if (gone) node.dispose();
      return gone;
    });
    _order = [
      for (final item in shownItems)
        if (item is GjaColumnListItem<T> && _actionable(item)) item.key,
    ];
    final header = widget.headerText;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: header,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sizeClass = theme.breakpoints.classify(constraints.maxWidth);
          bool shown(GjaColumn column) {
            final min = column.minScreenWidth;
            return min == null || sizeClass.isAtLeast(min);
          }

          final visible = [
            for (final (i, column) in widget.columns.indexed)
              if (shown(column)) i,
          ];
          final popin = [
            for (final (i, column) in widget.columns.indexed)
              if (!shown(column) && column.demandPopin) i,
          ];
          final selectedCount = items
              .where((item) => widget.selectedKeys.contains(item.key))
              .length;

          final headerRow = _Frame(
            selected: false,
            leading: multi
                ? GjaCheckBox(
                    semanticLabel: l10n.selectAll,
                    selected: items.isNotEmpty && selectedCount == items.length,
                    partiallySelected:
                        selectedCount > 0 && selectedCount < items.length,
                    enabled: items.isNotEmpty,
                    onSelect: (_) => widget.onSelectionChange?.call(
                      selectedCount == items.length ? <T>{} : keys,
                    ),
                  )
                : null,
            trailing: hasNavigation,
            child: _Cells(
              columns: widget.columns,
              visible: visible,
              cells: [
                for (final column in widget.columns)
                  Text(
                    column.header,
                    textAlign: _textAlign(column.hAlign),
                    style: theme.typography.base.copyWith(
                      color: theme.colors.label,
                    ),
                  ),
              ],
            ),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.s,
                    vertical: theme.spacing.s,
                  ),
                  child: GjaTitle(header, titleStyle: GjaTitleLevel.h5),
                ),
              headerRow,
              if (items.isEmpty)
                _Frame(
                  selected: false,
                  child: Center(
                    child: Text(
                      widget.noDataText ?? l10n.noData,
                      style: theme.typography.base.copyWith(
                        color: theme.colors.label,
                      ),
                    ),
                  ),
                ),
              Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: _onKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in shownItems)
                      switch (item) {
                        GjaColumnListItem<T>() => _row(
                          item,
                          visible: visible,
                          popin: popin,
                          multi: multi,
                          trailing: hasNavigation,
                          selectItem: l10n.selectItem,
                        ),
                        GjaGroupHeaderListItem<T>() => _GroupHeader(
                          title: item.title,
                          count: item.count,
                        ),
                      },
                  ],
                ),
              ),
              if (limit < items.length)
                _GrowingTrigger(
                  text: widget.growingTriggerText ?? l10n.more,
                  counter:
                      '[${l10n.formatInteger(limit)} / '
                      '${l10n.formatInteger(items.length)}]',
                  onPress: () =>
                      setState(() => _shown = limit + widget.growingThreshold),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    GjaColumnListItem<T> item, {
    required List<int> visible,
    required List<int> popin,
    required bool multi,
    required bool trailing,
    required String selectItem,
  }) {
    final selected = widget.selectedKeys.contains(item.key);
    final theme = GjaThemeData.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cells(columns: widget.columns, visible: visible, cells: item.cells),
        for (final i in popin)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: theme.spacing.s,
              end: theme.spacing.s,
              bottom: theme.spacing.xs,
            ),
            child: Row(
              spacing: theme.spacing.xs,
              children: [
                Text(
                  '${widget.columns[i].header}:',
                  style: theme.typography.base.copyWith(
                    color: theme.colors.label,
                  ),
                ),
                Flexible(child: item.cells[i]),
              ],
            ),
          ),
      ],
    );
    final arrow = item.type == GjaListType.navigation;
    final Widget body;
    if (_actionable(item)) {
      body = MergeSemantics(
        child: GjaInteractable(
          focusNode: _nodes.putIfAbsent(item.key, FocusNode.new),
          selected: widget.mode == GjaListMode.singleSelectMaster && selected,
          onPressed: () => _press(item),
          focusRingBorderRadius: BorderRadius.zero,
          builder: (context, states) {
            final active =
                states.contains(GjaInteractionState.hovered) ||
                states.contains(GjaInteractionState.pressed);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: active && !selected
                    ? theme.colors.hoverBackground
                    : null,
              ),
              child: _WithArrow(
                arrow: arrow,
                trailing: trailing,
                child: content,
              ),
            );
          },
        ),
      );
    } else {
      body = Semantics(
        container: true,
        child: _WithArrow(arrow: false, trailing: trailing, child: content),
      );
    }
    return _Frame(
      selected: selected,
      leading: multi
          ? GjaCheckBox(
              semanticLabel: selectItem,
              selected: selected,
              onSelect: (value) => _toggle(item.key, value),
            )
          : null,
      child: body,
    );
  }
}

/// Título de grupo, como o `sap.m.GroupHeaderListItem`.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count});

  final String title;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final count = this.count;
    return _Frame(
      selected: false,
      child: Semantics(
        header: true,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.s,
            vertical: theme.spacing.xs,
          ),
          child: Text(
            count == null ? title : '$title ($count)',
            style: theme.typography.baseBold.copyWith(color: theme.colors.text),
          ),
        ),
      ),
    );
  }
}

/// Botão de mais linhas, como o gatilho do `growing` do `sap.m.Table`.
class _GrowingTrigger extends StatelessWidget {
  const _GrowingTrigger({
    required this.text,
    required this.counter,
    required this.onPress,
  });

  final String text;
  final String counter;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    return MergeSemantics(
      child: GjaInteractable(
        semanticLabel: '$text $counter',
        onPressed: onPress,
        focusRingBorderRadius: BorderRadius.zero,
        builder: (context, states) {
          final active =
              states.contains(GjaInteractionState.hovered) ||
              states.contains(GjaInteractionState.pressed);
          return ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: active ? colors.hoverBackground : colors.base,
                border: Border(
                  bottom: BorderSide(
                    color: colors.separator,
                    width: const BorderSide().width,
                  ),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: theme.density.listItemHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(theme.spacing.xs),
                  // A linha ocupa a largura da tabela, mesmo sob restrições
                  // folgadas.
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            text,
                            style: theme.typography.baseBold.copyWith(
                              color: colors.text,
                            ),
                          ),
                          Text(
                            counter,
                            style: theme.typography.small.copyWith(
                              color: colors.label,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

TextAlign _textAlign(GjaColumnHAlign align) => switch (align) {
  GjaColumnHAlign.begin => TextAlign.start,
  GjaColumnHAlign.center => TextAlign.center,
  GjaColumnHAlign.end => TextAlign.end,
};

/// Fundo, borda inferior e altura mínima de uma linha, com a caixa de
/// seleção inicial e a reserva da seta final.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.selected,
    required this.child,
    this.leading,
    this.trailing = false,
  });

  final bool selected;
  final Widget child;
  final Widget? leading;

  /// Se reserva, à direita do conteúdo, a largura da seta das linhas
  /// `navigation` (só no cabeçalho; as linhas desenham a própria).
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final lead = leading;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? theme.colors.selectionBackground : theme.colors.base,
        border: Border(
          bottom: BorderSide(
            color: theme.colors.separator,
            width: const BorderSide().width,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.density.listItemHeight),
        child: Row(
          children: [
            if (lead != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
                child: lead,
              ),
            Expanded(
              child: trailing
                  ? _WithArrow(arrow: false, trailing: true, child: child)
                  : child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Conteúdo com a coluna final da seta, mostrada nas linhas `navigation`
/// e reservada nas outras.
class _WithArrow extends StatelessWidget {
  const _WithArrow({
    required this.arrow,
    required this.trailing,
    required this.child,
  });

  final bool arrow;
  final bool trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!trailing) return child;
    final theme = GjaThemeData.of(context);
    return Row(
      children: [
        Expanded(child: child),
        SizedBox(
          width: theme.icons.control + 2 * theme.spacing.s,
          child: arrow
              ? Icon(
                  GjaIcons.slimArrowRight,
                  size: theme.icons.control,
                  color: theme.colors.label,
                )
              : null,
        ),
      ],
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({
    required this.columns,
    required this.visible,
    required this.cells,
  });

  final List<GjaColumn> columns;
  final List<int> visible;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    return Row(
      children: [
        for (final i in visible)
          Expanded(
            flex: columns[i].flex,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.s,
                vertical: theme.spacing.xs,
              ),
              child: Align(
                heightFactor: 1,
                alignment: switch (columns[i].hAlign) {
                  GjaColumnHAlign.begin => AlignmentDirectional.centerStart,
                  GjaColumnHAlign.center => AlignmentDirectional.center,
                  GjaColumnHAlign.end => AlignmentDirectional.centerEnd,
                },
                child: cells[i],
              ),
            ),
          ),
      ],
    );
  }
}
