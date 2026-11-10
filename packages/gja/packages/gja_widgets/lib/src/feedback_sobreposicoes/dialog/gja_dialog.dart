import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../acoes_navegacao/button/gja_button.dart';
import '../../fundacao_layout/container/gja_container.dart';
import '../../fundacao_layout/separator/gja_separator.dart';
import '../../fundacao_layout/spacing/gja_spacing.dart';
import '../../fundacao_layout/title/gja_title.dart';

/// Largura de um [GjaDialog], igual entre diálogos do mesmo tipo.
enum GjaDialogWidth {
  /// 8 passos `spacing.xxxl` (384 nos tokens de referência).
  standard(8),

  /// 12 passos `spacing.xxxl` (576 nos tokens de referência), para
  /// conteúdos largos.
  wide(12);

  const GjaDialogWidth(this._steps);

  final int _steps;
}

/// Diálogo modal, como o `sap.m.Dialog` do SAPUI5.
///
/// É o painel: [title] (com o ícone do [state] nas mensagens), [content]
/// rolável e, no rodapé, [buttons], [beginButton] e [endButton]. Abra com
/// [GjaDialog.open], que usa o modal do núcleo: a camada de bloqueio cobre
/// a tela, o foco fica preso no diálogo e volta a quem o abriu, e Esc fecha
/// quando `dismissible`. Os botões fecham com
/// `Navigator.of(context).pop(resultado)`.
///
/// ```dart
/// final excluir = await GjaDialog.open<bool>(
///   context,
///   builder: (context) => GjaDialog(
///     title: 'Excluir pedido',
///     state: GjaValueState.warning,
///     content: const GjaText('O pedido 4711 será excluído.'),
///     beginButton: GjaButton(
///       text: 'Excluir',
///       type: GjaButtonType.emphasized,
///       onPress: () => Navigator.of(context).pop(true),
///     ),
///     endButton: GjaButton(
///       text: 'Cancelar',
///       onPress: () => Navigator.of(context).pop(false),
///     ),
///   ),
/// );
/// ```
class GjaDialog extends StatelessWidget {
  /// Cria o painel do diálogo com [content].
  const GjaDialog({
    required this.content,
    this.title,
    this.semanticLabel,
    this.state = GjaValueState.none,
    this.beginButton,
    this.endButton,
    this.buttons = const [],
    this.width = GjaDialogWidth.standard,
    super.key,
  }) : assert(
         (title != null && title != '') ||
             (semanticLabel != null && semanticLabel != ''),
         'GjaDialog precisa de title ou semanticLabel não vazio',
       );

  /// Abre o diálogo de [builder] como modal e espera o resultado.
  ///
  /// Com [dismissible], Esc fecha com resultado nulo; a camada de bloqueio
  /// nunca fecha o diálogo.
  static Future<T?> open<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
  }) => GjaModal.show<T>(context, builder: builder, dismissible: dismissible);

  /// Conteúdo do diálogo, que rola quando não cabe.
  final Widget content;

  /// Título, também o nome do diálogo para o leitor de tela.
  final String? title;

  /// Nome do diálogo quando não há [title].
  final String? semanticLabel;

  /// Estado da mensagem, que põe o ícone dele antes do título.
  final GjaValueState state;

  /// Botão antes do [endButton] no rodapé.
  final GjaButton? beginButton;

  /// Último botão do rodapé.
  final GjaButton? endButton;

  /// Botões do rodapé antes de [beginButton] e [endButton].
  final List<GjaButton> buttons;

  /// Largura do painel.
  final GjaDialogWidth width;

  IconData? get _stateIcon => switch (state) {
    GjaValueState.none => null,
    GjaValueState.success => GjaIcons.sysEnter2,
    GjaValueState.warning => GjaIcons.warning,
    GjaValueState.error => GjaIcons.error,
    GjaValueState.information => GjaIcons.information,
  };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final title = this.title;
    final icon = _stateIcon;
    final footer = [...buttons, ?beginButton, ?endButton];
    final screen = MediaQuery.sizeOf(context).width - 2 * theme.spacing.l;
    final panelWidth = math.min(
      theme.spacing.xxxl * width._steps,
      math.max(screen, theme.spacing.none),
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title ?? semanticLabel,
      child: SizedBox(
        width: panelWidth,
        child: GjaContainer(
          surface: GjaSurface.base,
          radius: GjaRadius.element,
          shadow: GjaShadow.dialog,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                GjaSpacing.padding(
                  all: GjaSpace.l,
                  child: Row(
                    spacing: theme.spacing.xs,
                    children: [
                      if (icon != null)
                        ExcludeSemantics(
                          child: Icon(
                            icon,
                            size: theme.icons.control,
                            color: theme.colors.stateColors(state).foreground,
                          ),
                        ),
                      Expanded(
                        child: GjaTitle(
                          title,
                          titleStyle: GjaTitleLevel.h4,
                          wrapping: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const GjaSeparator(),
              ],
              Flexible(
                child: SingleChildScrollView(
                  child: GjaSpacing.padding(
                    all: GjaSpace.l,
                    child: content,
                  ),
                ),
              ),
              if (footer.isNotEmpty) ...[
                const GjaSeparator(),
                GjaSpacing.padding(
                  all: GjaSpace.s,
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: theme.spacing.xs,
                    overflowSpacing: theme.spacing.xs,
                    children: footer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
