import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../feedback_sobreposicoes/dropdown/gja_dropdown.dart';
import '../../feedback_sobreposicoes/popover/gja_popover.dart';

/// Campo de seleção, como o `sap.m.Select` do SAPUI5.
///
/// Mostra o texto do item de [selectedKey] (ou [placeholder]) num campo com
/// seta e, acionado por toque, Enter, Espaço, F4 ou Alt+seta para baixo,
/// abre a lista de [items] na largura do campo. Escolher um item fecha a
/// lista e chama [onChange] com o valor dele, quando difere do atual, sem
/// mudar sozinho. Esc fecha a lista sem mudar nada.
///
/// Com [enabled] `false`, fica desabilitado; com [editable] `false`, recebe
/// o foco, mas não abre a lista. [valueState] colore a borda e o fundo, e
/// [valueStateText] aparece abaixo do campo enquanto ele tem o foco.
///
/// ```dart
/// GjaSelect<String>(
///   semanticLabel: 'Status',
///   selectedKey: status,
///   onChange: (value) => setState(() => status = value),
///   items: const [
///     GjaDropdownItem(key: 'aberto', text: 'Em aberto'),
///     GjaDropdownItem(key: 'aprovado', text: 'Aprovado'),
///   ],
/// )
/// ```
class GjaSelect<T> extends StatefulWidget {
  /// Cria o campo de seleção de [items].
  GjaSelect({
    required this.items,
    required this.semanticLabel,
    this.selectedKey,
    this.onChange,
    this.placeholder,
    this.enabled = true,
    this.editable = true,
    this.valueState = GjaValueState.none,
    this.valueStateText,
    super.key,
  }) : assert(items.isNotEmpty, 'items não pode ser vazia'),
       assert(semanticLabel != '', 'semanticLabel não pode ser vazio');

  /// Itens, na ordem da lista.
  final List<GjaDropdownItem<T>> items;

  /// Valor do item escolhido, ou nulo.
  final T? selectedKey;

  /// Chamado com o valor do item escolhido, quando muda, como o evento
  /// `change` do UI5.
  final ValueChanged<T>? onChange;

  /// Nome do campo e da lista para leitores de tela.
  final String semanticLabel;

  /// Texto mostrado sem item escolhido.
  final String? placeholder;

  /// Se o campo pode ser acionado e focado.
  final bool enabled;

  /// Se a escolha pode mudar; `false` deixa o campo somente leitura.
  final bool editable;

  /// Estado de valor, que colore a borda e o fundo.
  final GjaValueState valueState;

  /// Mensagem do estado de valor, mostrada abaixo do campo com o foco.
  final String? valueStateText;

  @override
  State<GjaSelect<T>> createState() => _GjaSelectState<T>();
}

class _GjaSelectState<T> extends State<GjaSelect<T>> {
  final _controller = GjaPopoverController(debugLabel: 'GjaSelect');
  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canOpen => widget.enabled && widget.editable;

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent || !_canOpen) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final alt = HardwareKeyboard.instance.isAltPressed;
    if (key == LogicalKeyboardKey.f4 ||
        (alt && key == LogicalKeyboardKey.arrowDown)) {
      _controller.open();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final selected = widget.items
        .where((item) => item.key == widget.selectedKey)
        .firstOrNull;
    final hasState = widget.valueState != GjaValueState.none;
    final state = colors.stateColors(widget.valueState);
    final corners = BorderRadius.circular(theme.radius.field);
    final message = widget.valueStateText;
    final placeholder = widget.placeholder;

    final field = GjaInteractable(
      semanticLabel: widget.semanticLabel,
      onPressed: !widget.enabled
          ? null
          : (widget.editable ? _controller.toggle : () {}),
      focusRingBorderRadius: corners,
      builder: (context, states) {
        final active =
            widget.editable &&
            (states.contains(GjaInteractionState.hovered) ||
                states.contains(GjaInteractionState.pressed) ||
                states.contains(GjaInteractionState.focused));
        final background = !widget.editable
            ? colors.headerBackground
            : (hasState ? state.background : colors.base);
        final border = active
            ? colors.brand
            : (hasState ? state.border : colors.fieldBorder);
        final text = selected?.text ?? placeholder;
        return ExcludeSemantics(
          child: Opacity(
            opacity: theme.interaction.opacity(states),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: corners,
                border: Border.all(
                  color: border,
                  width: const BorderSide().width,
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: theme.density.controlHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
                  child: Row(
                    spacing: theme.spacing.xs,
                    children: [
                      Expanded(
                        child: text == null
                            ? const SizedBox.shrink()
                            : Text(
                                text,
                                style: theme.typography.base.copyWith(
                                  color: selected == null
                                      ? colors.label
                                      : colors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (widget.editable)
                        Icon(
                          GjaIcons.slimArrowDown,
                          size: theme.icons.control,
                          color: colors.brand,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final anchored = GjaDropdown<T>(
      controller: _controller,
      semanticLabel: widget.semanticLabel,
      selectedKey: widget.selectedKey,
      items: widget.items,
      onSelectionChange: (value) {
        if (value != widget.selectedKey) widget.onChange?.call(value);
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        onFocusChange: (value) => setState(() => _focused = value),
        child: MergeSemantics(
          child: Semantics(
            value: selected?.text,
            hint: hasState ? message : null,
            child: field,
          ),
        ),
      ),
    );

    final showMessage =
        hasState && message != null && message != '' && _focused;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        anchored,
        if (showMessage)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: theme.spacing.xxs,
              start: theme.spacing.s,
            ),
            child: ExcludeSemantics(
              child: Text(
                message,
                style: theme.typography.small.copyWith(color: state.foreground),
              ),
            ),
          ),
      ],
    );
  }
}
