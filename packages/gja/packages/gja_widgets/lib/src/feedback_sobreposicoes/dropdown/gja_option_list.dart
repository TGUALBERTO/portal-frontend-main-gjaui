import 'dart:ui' show SemanticsRole;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../fundacao_layout/separator/gja_separator.dart';
import '../popover/gja_popover.dart';

/// Opção de uma [GjaOptionList].
///
/// Uso interno de `GjaDropdown` e `GjaMenu`; não exportado.
class GjaOption {
  /// Cria a opção [label].
  const GjaOption({
    required this.label,
    required this.onChosen,
    this.icon,
    this.trailing,
    this.selected = false,
    this.startsSection = false,
  });

  /// Rótulo, em uma linha.
  final String label;

  /// Chamado ao escolher a opção, depois de fechar a lista; nulo desabilita.
  final VoidCallback? onChosen;

  /// Ícone antes do rótulo.
  final IconData? icon;

  /// Texto no fim, no tom `muted` (texto adicional ou atalho).
  final String? trailing;

  /// Se a opção está selecionada.
  final bool selected;

  /// Se um separador vem antes da opção (exceto a primeira).
  final bool startsSection;
}

/// Lista de opções num popover ancorado na largura da âncora, com as cores da
/// família `list`, navegação por setas, Home, End e primeira letra, e foco
/// inicial na opção selecionada ou na primeira habilitada.
///
/// Uso interno de `GjaDropdown` e `GjaMenu`; não exportado.
class GjaOptionList extends StatefulWidget {
  /// Cria a lista de [options], ancorada em [child].
  const GjaOptionList({
    required this.controller,
    required this.options,
    required this.semanticLabel,
    required this.child,
    this.placement = GjaPlacement.bottom,
    this.onDismiss,
    this.listRole,
    this.itemRole,
    super.key,
  });

  /// Abre e fecha a lista.
  final GjaPopoverController controller;

  /// Opções, na ordem da lista.
  final List<GjaOption> options;

  /// Nome da lista para leitores de tela.
  final String semanticLabel;

  /// A âncora.
  final Widget child;

  /// Posição preferida em relação à âncora.
  final GjaPlacement placement;

  /// Chamado quando a lista fecha por toque fora ou Esc.
  final VoidCallback? onDismiss;

  /// Papel semântico da lista (ex.: `menu`), ou nenhum.
  final SemanticsRole? listRole;

  /// Papel semântico de cada opção (ex.: `menuItem`), ou nenhum.
  final SemanticsRole? itemRole;

  @override
  State<GjaOptionList> createState() => _GjaOptionListState();
}

class _GjaOptionListState extends State<GjaOptionList> {
  final List<FocusNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(GjaOptionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Um nó de foco por item.
  void _syncNodes() {
    while (_nodes.length < widget.options.length) {
      _nodes.add(
        FocusNode(debugLabel: 'GjaOptionList item ${_nodes.length}'),
      );
    }
    while (_nodes.length > widget.options.length) {
      _nodes.removeLast().dispose();
    }
  }

  bool _enabled(int index) => widget.options[index].onChosen != null;

  /// Item que recebe o foco ao abrir: o selecionado habilitado ou o primeiro
  /// habilitado.
  int? get _initial {
    final options = widget.options;
    final selected = options.indexWhere(
      (option) => option.selected && option.onChosen != null,
    );
    if (selected >= 0) return selected;
    final first = options.indexWhere((option) => option.onChosen != null);
    return first >= 0 ? first : null;
  }

  void _choose(VoidCallback onChosen) {
    widget.controller.close();
    onChosen();
  }

  void _focus(int index) {
    final node = _nodes[index];
    node.requestFocus();
    final context = node.context;
    if (context != null) Scrollable.ensureVisible(context);
  }

  /// Próximo índice habilitado a partir de [from], no passo [step], sem dar a
  /// volta; nulo quando não há.
  int? _next(int from, int step) {
    for (var i = from + step; i >= 0 && i < _nodes.length; i += step) {
      if (_enabled(i)) return i;
    }
    return null;
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final current = _nodes.indexWhere((node) => node.hasPrimaryFocus);
    final key = event.logicalKey;
    int? target;
    if (key == LogicalKeyboardKey.arrowDown) {
      target = current < 0 ? _initial : _next(current, 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      target = current < 0 ? _initial : _next(current, -1);
    } else if (key == LogicalKeyboardKey.home) {
      target = _next(-1, 1);
    } else if (key == LogicalKeyboardKey.end) {
      target = _next(_nodes.length, -1);
    } else {
      final character = event.character;
      if (character == null ||
          character.trim().isEmpty ||
          character.runes.length != 1) {
        return KeyEventResult.ignored;
      }
      target = _byLetter(character.toLowerCase(), current);
      if (target == null) return KeyEventResult.handled;
    }
    if (target != null && target != current) _focus(target);
    return KeyEventResult.handled;
  }

  /// Próximo item habilitado depois de [current] cujo rótulo começa com
  /// [letter], dando a volta.
  int? _byLetter(String letter, int current) {
    final count = widget.options.length;
    for (var offset = 1; offset <= count; offset++) {
      final i = (current + offset) % count;
      if (_enabled(i) &&
          widget.options[i].label.toLowerCase().startsWith(letter)) {
        return i;
      }
    }
    return null;
  }

  Widget _item(BuildContext context, int index) {
    final theme = GjaThemeData.of(context);
    final item = widget.options[index];
    final family = GjaControlColors.of(GjaControlFamily.list, theme.colors);
    final additionalText = item.trailing;
    final onChosen = item.onChosen;
    // Um só nó por item: botão (com o papel do item), rótulo, foco e toque.
    return MergeSemantics(
      child: Semantics(
        role: widget.itemRole,
        child: GjaInteractable(
          focusNode: _nodes[index],
          selected: item.selected && onChosen != null,
          onPressed: onChosen == null ? null : () => _choose(onChosen),
          semanticLabel: additionalText == null
              ? item.label
              : '${item.label}, $additionalText',
          focusRingBorderRadius: BorderRadius.zero,
          builder: (context, states) {
            final c = family.resolve(states);
            // A cor do texto adicional segue o estado quando o fundo muda muito
            // (ativo); nos demais, fica no tom `muted`.
            final muted = states.contains(GjaInteractionState.pressed)
                ? c.text
                : theme.colors.label;
            // O rótulo já está na semântica do item; o conteúdo é visual.
            return ExcludeSemantics(
              child: Opacity(
                opacity: theme.interaction.opacity(states),
                child: SizedBox(
                  width: double.infinity,
                  child: ColoredBox(
                    color: c.background,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: theme.density.controlHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.m,
                        ),
                        child: Row(
                          spacing: theme.spacing.s,
                          children: [
                            if (item.icon case final icon?)
                              Icon(
                                icon,
                                size: theme.icons.control,
                                color: c.text,
                              ),
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.typography.base.copyWith(
                                  color: c.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (additionalText != null)
                              Text(
                                additionalText,
                                style: theme.typography.base.copyWith(
                                  color: muted,
                                ),
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Dá à lista o papel [GjaOptionList.listRole], quando há.
  Widget _role(Widget list) {
    final role = widget.listRole;
    if (role == null) return list;
    return Semantics(
      role: role,
      container: true,
      explicitChildNodes: true,
      child: list,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GjaPopover(
      controller: widget.controller,
      semanticLabel: widget.semanticLabel,
      width: GjaPopoverWidth.anchor,
      padded: false,
      placement: widget.placement,
      onDismiss: widget.onDismiss,
      content: Builder(
        builder: (context) {
          return _OnMount(
            // Depois do foco inicial do núcleo (primeiro focável), leva o
            // foco ao item selecionado.
            onMount: () {
              final initial = _initial;
              if (initial != null) _focus(initial);
            },
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _handleKey,
              child: _role(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.options.length; i++) ...[
                      if (i > 0 && widget.options[i].startsSection)
                        const GjaSeparator(),
                      _item(context, i),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      child: widget.child,
    );
  }
}

/// Chama [onMount] depois do primeiro quadro em que [child] aparece.
class _OnMount extends StatefulWidget {
  const _OnMount({required this.onMount, required this.child});

  final VoidCallback onMount;
  final Widget child;

  @override
  State<_OnMount> createState() => _OnMountState();
}

class _OnMountState extends State<_OnMount> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMount();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
