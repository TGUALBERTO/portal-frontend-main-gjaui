import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Aba de um [GjaIconTabBar], como o `sap.m.IconTabFilter` do SAPUI5.
///
/// É uma configuração, não um widget: use em [GjaIconTabBar.items].
@immutable
class GjaIconTabFilter<T> {
  /// Cria a aba [text] com a chave [key].
  const GjaIconTabFilter({
    required this.key,
    required this.text,
    this.icon,
    this.count,
    this.enabled = true,
    this.content,
  });

  /// Chave devolvida por `onSelect` quando a aba é escolhida.
  final T key;

  /// Texto da aba.
  final String text;

  /// Ícone antes do texto.
  final IconData? icon;

  /// Contagem depois do texto, entre parênteses (ex.: itens da aba).
  final String? count;

  /// Se a aba pode ser escolhida e focada.
  final bool enabled;

  /// Conteúdo mostrado quando a aba está escolhida.
  final Widget? content;
}

/// Barra de abas, como o `sap.m.IconTabBar` do SAPUI5.
///
/// O cabeçalho mostra as abas de [items], com a de [selectedKey] (ou a
/// primeira habilitada) destacada na cor da marca; abaixo fica o `content`
/// dela. É controlada: escolher outra aba (toque, Enter ou Espaço) chama
/// [onSelect] com a chave dela, sem mudar sozinha.
///
/// Pelo teclado, Tab entra pela aba escolhida, as setas para os lados movem
/// o foco entre as abas habilitadas, sem escolher, e Enter ou Espaço
/// escolhem, como no UI5. O cabeçalho rola na horizontal quando as abas não
/// cabem.
///
/// ```dart
/// GjaIconTabBar<String>(
///   selectedKey: aba,
///   onSelect: (key) => setState(() => aba = key),
///   items: const [
///     GjaIconTabFilter(key: 'itens', text: 'Itens', count: '12'),
///     GjaIconTabFilter(key: 'notas', text: 'Notas'),
///   ],
/// )
/// ```
class GjaIconTabBar<T> extends StatefulWidget {
  /// Cria a barra de abas de [items].
  const GjaIconTabBar({
    required this.items,
    this.selectedKey,
    this.onSelect,
    this.applyContentPadding = true,
    super.key,
  });

  /// Abas, na ordem do cabeçalho.
  final List<GjaIconTabFilter<T>> items;

  /// Chave da aba escolhida; nula escolhe a primeira habilitada.
  final T? selectedKey;

  /// Chamado com a chave da aba escolhida, como o evento `select` do UI5.
  final ValueChanged<T>? onSelect;

  /// Se o conteúdo tem `spacing.l` em volta.
  final bool applyContentPadding;

  @override
  State<GjaIconTabBar<T>> createState() => _GjaIconTabBarState<T>();
}

class _GjaIconTabBarState<T> extends State<GjaIconTabBar<T>> {
  final _nodes = <FocusNode>[];

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    while (_nodes.length < widget.items.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
  }

  int get _selected {
    final items = widget.items;
    final index = items.indexWhere(
      (item) => item.key == widget.selectedKey && item.enabled,
    );
    if (index >= 0) return index;
    final first = items.indexWhere((item) => item.enabled);
    return first >= 0 ? first : 0;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final int step;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      step = rtl ? -1 : 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      step = rtl ? 1 : -1;
    } else {
      return KeyEventResult.ignored;
    }
    final current = _nodes.indexWhere((node) => node.hasFocus);
    if (current < 0) return KeyEventResult.ignored;
    final count = widget.items.length;
    for (var k = 1; k <= count; k++) {
      final i = (current + step * k) % count;
      if (widget.items[i].enabled) {
        _nodes[i].requestFocus();
        break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    assert(items.isNotEmpty, 'items não pode ser vazia');
    assert(
      items.map((item) => item.key).toSet().length == items.length,
      'as chaves das abas devem ser distintas',
    );
    assert(
      items.every((item) => item.text != ''),
      'os textos das abas não podem ser vazios',
    );
    _syncNodes();
    final theme = GjaThemeData.of(context);
    final selected = _selected;
    for (var i = 0; i < items.length; i++) {
      _nodes[i].skipTraversal = i != selected;
    }
    final content = items[selected].content;

    final header = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colors.separator,
            width: const BorderSide().width,
          ),
        ),
      ),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, item) in items.indexed)
                _Tab(
                  item: item,
                  selected: i == selected,
                  focusNode: _nodes[i],
                  onPress: () {
                    if (i != selected) widget.onSelect?.call(item.key);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (content != null)
          widget.applyContentPadding
              ? Padding(
                  padding: EdgeInsets.all(theme.spacing.l),
                  child: content,
                )
              : content,
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.selected,
    required this.focusNode,
    required this.onPress,
  });

  final GjaIconTabFilter<Object?> item;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final count = item.count;
    final icon = item.icon;
    return MergeSemantics(
      child: GjaInteractable(
        semanticLabel: count == null ? item.text : '${item.text} ($count)',
        selected: selected,
        focusNode: focusNode,
        onPressed: item.enabled ? onPress : null,
        focusRingBorderRadius: BorderRadius.zero,
        builder: (context, states) {
          final active =
              states.contains(GjaInteractionState.hovered) ||
              states.contains(GjaInteractionState.pressed);
          final color = selected ? colors.brand : colors.text;
          return ExcludeSemantics(
            child: Opacity(
              opacity: theme.interaction.opacity(states),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active ? colors.hoverBackground : null,
                ),
                child: SizedBox(
                  height: theme.density.barHeight,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.l,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.spacing.xs,
                            children: [
                              if (icon != null)
                                Icon(
                                  icon,
                                  size: theme.icons.control,
                                  color: color,
                                ),
                              Text(
                                item.text,
                                style: theme.typography.base.copyWith(
                                  color: color,
                                ),
                              ),
                              if (count != null)
                                Text(
                                  '($count)',
                                  style: theme.typography.base.copyWith(
                                    color: colors.label,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (selected)
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: SizedBox(
                            height: theme.spacing.xxs,
                            child: ColoredBox(color: colors.brand),
                          ),
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
