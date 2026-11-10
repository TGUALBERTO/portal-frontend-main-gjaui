import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Opção de escolha única, como o `sap.m.RadioButton` do SAPUI5.
///
/// É controlada: mostra [selected] e, acionada sem estar marcada (toque na
/// opção ou no texto, Enter ou Espaço), chama [onSelect] com `true`, sem
/// mudar sozinha. Com [enabled] `false`, fica desabilitada; com [editable]
/// `false`, recebe o foco, mas não muda. [valueState] colore a borda e o
/// fundo do círculo.
///
/// Para um conjunto de opções, use `GjaRadioButtonGroup`, que marca a
/// opção escolhida e navega entre elas com as setas.
///
/// ```dart
/// GjaRadioButton(
///   text: 'Receber por e-mail',
///   selected: canal == Canal.email,
///   onSelect: (_) => setState(() => canal = Canal.email),
/// )
/// ```
class GjaRadioButton extends StatelessWidget {
  /// Cria a opção.
  const GjaRadioButton({
    this.selected = false,
    this.onSelect,
    this.text,
    this.semanticLabel,
    this.enabled = true,
    this.editable = true,
    this.valueState = GjaValueState.none,
    this.wrapping = false,
    this.focusNode,
    super.key,
  }) : assert(
         (text != null && text != '') ||
             (semanticLabel != null && semanticLabel != ''),
         'GjaRadioButton precisa de text ou semanticLabel não vazio',
       );

  /// Se a opção está marcada.
  final bool selected;

  /// Chamado com `true` quando a opção desmarcada é acionada, como o evento
  /// `select` do UI5.
  final ValueChanged<bool>? onSelect;

  /// Texto ao lado do círculo, também anunciado pelo leitor de tela.
  final String? text;

  /// Nome anunciado quando não há [text].
  final String? semanticLabel;

  /// Se a opção pode ser acionada e focada.
  final bool enabled;

  /// Se a opção pode ser escolhida; `false` deixa a opção somente leitura.
  final bool editable;

  /// Estado de valor, que colore a borda e o fundo do círculo.
  final GjaValueState valueState;

  /// Se o texto quebra em várias linhas, em vez de terminar com reticências.
  final bool wrapping;

  /// Nó de foco da opção; o `GjaRadioButtonGroup` usa para as setas.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final text = this.text;
    final onSelect = this.onSelect;
    final VoidCallback? onPressed = !enabled
        ? null
        : (!editable || selected ? () {} : () => onSelect?.call(true));

    final button = GjaInteractable(
      semanticLabel: text ?? semanticLabel,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusNode: focusNode,
      onPressed: onPressed,
      focusRingBorderRadius: BorderRadius.circular(theme.radius.full),
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
        final dot = editable ? colors.brand : colors.label;

        final circle = DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: const BorderSide().width),
          ),
          child: SizedBox.square(
            dimension: theme.icons.control + theme.spacing.xxs,
            child: selected
                ? Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: theme.spacing.s),
                    ),
                  )
                : null,
          ),
        );
        // O nome já está na semântica da opção; o conteúdo é visual.
        return ExcludeSemantics(
          child: Opacity(
            opacity: theme.interaction.opacity(states),
            child: text == null
                ? circle
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.spacing.xs,
                    children: [
                      circle,
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
    return MergeSemantics(
      child: Semantics(readOnly: !editable && enabled, child: button),
    );
  }
}
