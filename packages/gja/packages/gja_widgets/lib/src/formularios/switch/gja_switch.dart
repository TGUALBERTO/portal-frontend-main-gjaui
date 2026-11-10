import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Chave liga/desliga, como o `sap.m.Switch` do SAPUI5.
///
/// É controlada: mostra [state] e, ao ser acionada (toque, Enter ou Espaço),
/// chama [onChange] com `!state`, sem mudar sozinha. A alça fica no início do
/// trilho desligada e no fim ligada, com a mudança animada por
/// `motion.short`. Sem texto visível, [semanticLabel] é o nome lido pelo
/// leitor de tela; coloque um rótulo ao lado na tela.
///
/// ```dart
/// GjaSwitch(
///   semanticLabel: 'Notificações',
///   state: notificar,
///   onChange: (value) => setState(() => notificar = value),
/// )
/// ```
class GjaSwitch extends StatelessWidget {
  /// Cria a chave.
  const GjaSwitch({
    required this.semanticLabel,
    this.state = false,
    this.onChange,
    this.enabled = true,
    super.key,
  }) : assert(semanticLabel != '', 'semanticLabel não pode ser vazio');

  /// Se a chave está ligada.
  final bool state;

  /// Chamado com o novo estado quando a chave é acionada, como o evento
  /// `change` do UI5.
  final ValueChanged<bool>? onChange;

  /// Nome anunciado pelo leitor de tela.
  final String semanticLabel;

  /// Se a chave pode ser acionada e focada.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final height = theme.icons.medium;
    final handle = theme.icons.control;
    final corners = BorderRadius.circular(theme.radius.full);
    final onChange = this.onChange;

    return MergeSemantics(
      child: GjaInteractable(
        semanticLabel: semanticLabel,
        toggled: state,
        onPressed: enabled ? () => onChange?.call(!state) : null,
        focusRingBorderRadius: corners,
        builder: (context, states) {
          final hovered =
              states.contains(GjaInteractionState.hovered) ||
              states.contains(GjaInteractionState.pressed);
          final track = state
              ? (hovered ? colors.brandHover : colors.brand)
              : (hovered ? colors.label : colors.fieldBorder);
          // A alça segue a direção do texto: ligada fica no fim.
          return ExcludeSemantics(
            child: Opacity(
              opacity: theme.interaction.opacity(states),
              child: AnimatedContainer(
                duration: theme.motion.short,
                curve: theme.motion.standard,
                width: height * 2,
                height: height,
                decoration: BoxDecoration(color: track, borderRadius: corners),
                child: AnimatedAlign(
                  duration: theme.motion.short,
                  curve: theme.motion.standard,
                  alignment: state
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: EdgeInsets.all((height - handle) / 2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.base,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: handle),
                    ),
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
