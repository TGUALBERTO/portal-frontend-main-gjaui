import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../fundacao_layout/icon/gja_icon.dart';
import '../../fundacao_layout/label/gja_label.dart';

/// Situação de um registro, como o `sap.m.ObjectStatus` do SAPUI5.
///
/// Mostra o [title] opcional ("Situação:", no tom `muted`), o [icon] e o
/// [text] na cor de frente do [state] (`colors.text` em `none`). Com
/// [inverted], vira uma etiqueta com o fundo, a borda e a frente do estado.
/// Com [onPress], fica ativo: sublinhado no hover, foco pelo teclado,
/// Enter e Espaço, e anunciado como botão. O texto quebra em várias linhas,
/// com o título e o ícone na primeira.
///
/// ```dart
/// GjaObjectStatus(
///   title: 'Situação',
///   text: 'Aprovado',
///   icon: GjaIcons.sysEnter2,
///   state: GjaValueState.success,
/// )
/// ```
class GjaObjectStatus extends StatelessWidget {
  /// Cria o status; informe [text] ou [icon].
  const GjaObjectStatus({
    this.text,
    this.icon,
    this.title,
    this.state = GjaValueState.none,
    this.inverted = false,
    this.onPress,
    super.key,
  }) : assert(
         (text != null && text != '') || icon != null,
         'informe text ou icon',
       );

  /// Valor da situação (ex.: "Aprovado").
  final String? text;

  /// Ícone antes do texto, do catálogo `GjaIcons` ou da aplicação.
  final IconData? icon;

  /// Rótulo antes do valor (ex.: "Situação"), seguido de dois-pontos.
  final String? title;

  /// Estado de valor, que define as cores.
  final GjaValueState state;

  /// Se o status é uma etiqueta preenchida com as cores do estado.
  final bool inverted;

  /// Ação do status ativo; nula torna o status apenas informativo.
  final VoidCallback? onPress;

  static GjaIconTone _iconTone(GjaValueState state) => switch (state) {
    GjaValueState.none => GjaIconTone.standard,
    GjaValueState.success => GjaIconTone.success,
    GjaValueState.warning => GjaIconTone.warning,
    GjaValueState.error => GjaIconTone.error,
    GjaValueState.information => GjaIconTone.information,
  };

  /// Rótulo do leitor de tela: "título: texto", só o texto ou só o título.
  String get _label {
    final text = this.text;
    final title = this.title;
    if (text != null && text != '') {
      return title == null ? text : '$title: $text';
    }
    return title ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors.stateColors(state);
    final foreground = state == GjaValueState.none
        ? theme.colors.text
        : colors.foreground;
    final body = theme.typography.base;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(body.fontSize!) *
        (body.height ?? 1);
    final iconSide = MediaQuery.textScalerOf(context).scale(theme.icons.inline);

    Widget content(bool underline) {
      final text = this.text;
      final icon = this.icon;
      final title = this.title;
      Widget row = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacing.xs,
        children: [
          if (title != null) GjaLabel(title, showColon: true, wrapping: true),
          if (icon != null)
            // Recuo para centrar o ícone na primeira linha do texto.
            Padding(
              padding: EdgeInsets.only(
                top: lineHeight > iconSide ? (lineHeight - iconSide) / 2 : 0,
              ),
              child: GjaIcon(
                icon,
                size: GjaIconSize.inline,
                tone: _iconTone(state),
              ),
            ),
          if (text != null && text != '')
            Flexible(
              child: Text(
                text,
                style: body.copyWith(
                  color: foreground,
                  decoration: underline
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: foreground,
                ),
                softWrap: true,
              ),
            ),
        ],
      );
      if (inverted) {
        row = DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            // Linha fina padrão do framework, como no GjaContainer.
            border: Border.all(
              color: colors.border,
              width: const BorderSide().width,
            ),
            borderRadius: BorderRadius.circular(theme.radius.s),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
            child: row,
          ),
        );
      }
      // O rótulo é anunciado pelo nó do status; o conteúdo é visual.
      return ExcludeSemantics(child: row);
    }

    final onPress = this.onPress;
    if (onPress == null) {
      return Semantics(container: true, label: _label, child: content(false));
    }
    // Um só nó: o foco e o toque do detector se juntam ao status rotulado.
    return MergeSemantics(
      child: GjaInteractable(
        semanticLabel: _label,
        onPressed: onPress,
        focusRingBorderRadius: BorderRadius.circular(theme.radius.s),
        builder: (context, states) => content(
          states.contains(GjaInteractionState.hovered) ||
              states.contains(GjaInteractionState.pressed),
        ),
      ),
    );
  }
}
