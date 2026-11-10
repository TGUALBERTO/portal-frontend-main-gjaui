import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../radio_button/gja_radio_button.dart';

/// Grupo de opções de escolha única, como o `sap.m.RadioButtonGroup` do
/// SAPUI5.
///
/// Marca a opção de [selectedIndex] (`-1` não marca nenhuma) e, quando outra
/// é escolhida, chama [onSelect] com o índice dela, sem mudar sozinho. As
/// setas para baixo e para a direita escolhem a próxima opção habilitada, e
/// as para cima e para a esquerda a anterior, voltando nas pontas; Tab entra
/// no grupo pela opção marcada e sai no Tab seguinte. As opções ficam em
/// [columns] colunas de mesma largura, em ordem de leitura.
///
/// [enabled], [editable] e [valueState] do grupo valem para todas as opções.
///
/// ```dart
/// GjaRadioButtonGroup(
///   selectedIndex: pagamento,
///   onSelect: (i) => setState(() => pagamento = i),
///   buttons: const [
///     GjaRadioButton(text: 'Boleto'),
///     GjaRadioButton(text: 'Pix'),
///   ],
/// )
/// ```
class GjaRadioButtonGroup extends StatefulWidget {
  /// Cria o grupo de [buttons].
  const GjaRadioButtonGroup({
    required this.buttons,
    this.selectedIndex = 0,
    this.onSelect,
    this.columns = 1,
    this.enabled = true,
    this.editable = true,
    this.valueState = GjaValueState.none,
    super.key,
  }) : assert(columns >= 1, 'columns deve ser ao menos 1');

  /// Opções, em ordem de leitura; `selected`, `onSelect` e `focusNode` delas
  /// são definidos pelo grupo.
  final List<GjaRadioButton> buttons;

  /// Índice da opção marcada; `-1` não marca nenhuma.
  final int selectedIndex;

  /// Chamado com o índice da opção escolhida, como o evento `select` do UI5.
  final ValueChanged<int>? onSelect;

  /// Número de colunas.
  final int columns;

  /// Se as opções podem ser acionadas e focadas.
  final bool enabled;

  /// Se a escolha pode mudar.
  final bool editable;

  /// Estado de valor aplicado a todas as opções.
  final GjaValueState valueState;

  @override
  State<GjaRadioButtonGroup> createState() => _GjaRadioButtonGroupState();
}

class _GjaRadioButtonGroupState extends State<GjaRadioButtonGroup> {
  final _nodes = <FocusNode>[];

  bool _usable(int i) => widget.enabled && widget.buttons[i].enabled;

  void _syncNodes() {
    while (_nodes.length < widget.buttons.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.buttons.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final int step;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      step = 1;
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      step = -1;
    } else {
      return KeyEventResult.ignored;
    }
    final current = _nodes.indexWhere((n) => n.hasFocus);
    if (current < 0) return KeyEventResult.ignored;
    final count = widget.buttons.length;
    for (var k = 1; k <= count; k++) {
      final i = (current + step * k) % count;
      if (_usable(i)) {
        _nodes[i].requestFocus();
        if (widget.editable && widget.buttons[i].editable) {
          widget.onSelect?.call(i);
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.handled;
  }

  /// Cópia de [button] com os valores que o grupo controla.
  GjaRadioButton _inGroup(
    GjaRadioButton button, {
    required bool selected,
    required ValueChanged<bool> onSelect,
    required FocusNode focusNode,
  }) => GjaRadioButton(
    key: button.key,
    selected: selected,
    onSelect: onSelect,
    text: button.text,
    semanticLabel: button.semanticLabel,
    enabled: widget.enabled && button.enabled,
    editable: widget.editable && button.editable,
    valueState: widget.valueState == GjaValueState.none
        ? button.valueState
        : widget.valueState,
    wrapping: button.wrapping,
    focusNode: focusNode,
  );

  @override
  Widget build(BuildContext context) {
    assert(widget.buttons.isNotEmpty, 'buttons não pode ser vazia');
    _syncNodes();
    final count = widget.buttons.length;
    // Tab entra pela opção marcada ou, sem ela, pela primeira habilitada.
    final selected = widget.selectedIndex;
    final entry = selected >= 0 && selected < count && _usable(selected)
        ? selected
        : List.generate(count, (i) => i).firstWhere(_usable, orElse: () => 0);
    for (var i = 0; i < count; i++) {
      _nodes[i].skipTraversal = i != entry;
    }
    final items = [
      for (var i = 0; i < count; i++)
        _inGroup(
          widget.buttons[i],
          selected: i == selected,
          onSelect: (_) => widget.onSelect?.call(i),
          focusNode: _nodes[i],
        ),
    ];
    final columns = widget.columns;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: columns == 1
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < count; r += columns)
                  Row(
                    children: [
                      for (var c = 0; c < columns; c++)
                        Expanded(
                          child: r + c < count
                              ? Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: items[r + c],
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}
