import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../acoes_navegacao/button/gja_button.dart';
import '../../acoes_navegacao/link/gja_link.dart';

/// Faixa de mensagem dentro da página, como o `sap.m.MessageStrip` do SAPUI5.
///
/// Mostra [text] com as cores do [type] (o `MessageType` do UI5), o ícone do
/// tipo antes dele com [showIcon] e o [link] depois. Com [showCloseButton],
/// mostra um botão de fechar que chama [onClose]; o pai remove a faixa. O
/// texto quebra em várias linhas, e a faixa é anunciada pelo leitor de tela
/// quando aparece.
///
/// ```dart
/// GjaMessageStrip(
///   text: 'Pedido 4711 salvo.',
///   type: GjaValueState.success,
///   showIcon: true,
/// )
/// ```
class GjaMessageStrip extends StatelessWidget {
  /// Cria a faixa com [text].
  const GjaMessageStrip({
    required this.text,
    this.type = GjaValueState.information,
    this.showIcon = false,
    this.showCloseButton = false,
    this.onClose,
    this.link,
    super.key,
  }) : assert(text != '', 'text não pode ser vazio');

  /// Texto da mensagem.
  final String text;

  /// Tipo da mensagem, que define as cores e o ícone.
  final GjaValueState type;

  /// Se mostra o ícone do tipo antes do texto.
  final bool showIcon;

  /// Se mostra o botão de fechar.
  final bool showCloseButton;

  /// Chamado pelo botão de fechar, como o evento `close` do UI5.
  final VoidCallback? onClose;

  /// Link depois do texto.
  final GjaLink? link;

  IconData get _icon => switch (type) {
    GjaValueState.none ||
    GjaValueState.information => GjaIcons.information,
    GjaValueState.success => GjaIcons.sysEnter2,
    GjaValueState.warning => GjaIcons.warning,
    GjaValueState.error => GjaIcons.error,
  };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final state = theme.colors.stateColors(type);
    final spacing = theme.spacing;
    final link = this.link;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: state.background,
          border: Border.all(
            color: state.border,
            width: const BorderSide().width,
          ),
          borderRadius: BorderRadius.circular(theme.radius.popover),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: spacing.l,
            end: showCloseButton ? spacing.xs : spacing.l,
            top: spacing.s,
            bottom: spacing.s,
          ),
          child: Row(
            spacing: spacing.xs,
            children: [
              if (showIcon)
                ExcludeSemantics(
                  child: Icon(
                    _icon,
                    size: theme.icons.control,
                    color: state.foreground,
                  ),
                ),
              Expanded(
                child: Wrap(
                  spacing: spacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      text,
                      style: theme.typography.base.copyWith(
                        color: theme.colors.text,
                      ),
                    ),
                    ?link,
                  ],
                ),
              ),
              if (showCloseButton)
                GjaButton(
                  icon: GjaIcons.decline,
                  tooltip: GjaLocalizations.of(context).close,
                  type: GjaButtonType.transparent,
                  onPress: onClose,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
