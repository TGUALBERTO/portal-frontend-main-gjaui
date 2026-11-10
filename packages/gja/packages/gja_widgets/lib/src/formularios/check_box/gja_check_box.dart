import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Caixa de seleção, como o `sap.m.CheckBox` do SAPUI5.
///
/// É controlada: mostra [selected] e, ao ser acionada (toque na caixa ou no
/// texto, Espaço ou Enter), chama [onSelect] com o novo valor, sem mudar
/// sozinha. Com [partiallySelected], mostra a marca parcial, e acionar marca
/// a caixa. Com [enabled] `false`, fica desabilitada; com [editable]
/// `false`, recebe o foco, mas não muda. [valueState] colore a borda e o
/// fundo com as cores do estado.
///
/// O texto é opcional; sem ele, [semanticLabel] dá o nome lido pelo leitor
/// de tela.
///
/// ```dart
/// GjaCheckBox(
///   text: 'Aceito os termos',
///   selected: aceito,
///   onSelect: (value) => setState(() => aceito = value),
/// )
/// ```
class GjaCheckBox extends StatelessWidget {
  /// Cria a caixa de seleção.
  const GjaCheckBox({
    this.selected = false,
    this.onSelect,
    this.text,
    this.semanticLabel,
    this.partiallySelected = false,
    this.enabled = true,
    this.editable = true,
    this.valueState = GjaValueState.none,
    this.wrapping = false,
    super.key,
  }) : assert(
         (text != null && text != '') ||
             (semanticLabel != null && semanticLabel != ''),
         'GjaCheckBox precisa de text ou semanticLabel não vazio',
       );

  /// Se a caixa está marcada.
  final bool selected;

  /// Chamado com o novo valor quando a caixa é acionada, como o evento
  /// `select` do UI5.
  final ValueChanged<bool>? onSelect;

  /// Texto ao lado da caixa, também anunciado pelo leitor de tela.
  final String? text;

  /// Nome anunciado quando não há [text].
  final String? semanticLabel;

  /// Se a caixa mostra a marca parcial (por exemplo, quando só parte de um
  /// grupo está marcada).
  final bool partiallySelected;

  /// Se a caixa pode ser acionada e focada.
  final bool enabled;

  /// Se o valor pode mudar; `false` deixa a caixa somente leitura.
  final bool editable;

  /// Estado de valor, que colore a borda e o fundo da caixa.
  final GjaValueState valueState;

  /// Se o texto quebra em várias linhas, em vez de terminar com reticências.
  final bool wrapping;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final text = this.text;
    final onSelect = this.onSelect;
    final VoidCallback? onPressed = !enabled
        ? null
        : (!editable
              ? () {}
              : () => onSelect?.call(partiallySelected || !selected));

    final Widget box = GjaInteractable(
      semanticLabel: text ?? semanticLabel,
      checked: partiallySelected ? null : selected,
      mixed: partiallySelected,
      onPressed: onPressed,
      focusRingBorderRadius: BorderRadius.circular(theme.radius.field),
      builder: (context, states) {
        final active =
            editable &&
            (states.contains(GjaInteractionState.hovered) ||
                states.contains(GjaInteractionState.pressed));
        final state = colors.stateColors(valueState);
        final (Color background, Color border) = !editable
            ? (colors.background, colors.separator)
            : valueState != GjaValueState.none
            ? (state.background, active ? colors.brand : state.border)
            : (colors.base, active ? colors.brand : colors.fieldBorder);
        final mark = editable ? colors.brand : colors.label;
        final side = theme.icons.control + theme.spacing.xxs;

        final square = DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border, width: const BorderSide().width),
            borderRadius: BorderRadius.circular(theme.radius.field),
          ),
          child: SizedBox.square(
            dimension: side,
            child: partiallySelected
                ? Padding(
                    padding: EdgeInsets.all(theme.spacing.xs),
                    child: ColoredBox(color: mark),
                  )
                : selected
                ? Center(
                    child: Icon(
                      GjaIcons.accept,
                      size: theme.icons.control,
                      color: mark,
                    ),
                  )
                : null,
          ),
        );
        // O nome já está na semântica da caixa; o conteúdo é visual.
        return ExcludeSemantics(
          child: Opacity(
            opacity: theme.interaction.opacity(states),
            child: text == null
                ? square
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: theme.spacing.xs,
                    children: [
                      square,
                      Flexible(
                        child: Text(
                          text,
                          style: theme.typography.base.copyWith(
                            color: colors.text,
                          ),
                          maxLines: wrapping ? null : 1,
                          overflow: wrapping ? null : TextOverflow.ellipsis,
                          softWrap: wrapping,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
    // Somente leitura: focável, sem mudar, e anunciada como somente leitura.
    return MergeSemantics(
      child: Semantics(readOnly: !editable && enabled, child: box),
    );
  }
}
