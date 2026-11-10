import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Fundo de um [GjaPanel], como o `backgroundDesign` do `sap.m.Panel`.
enum GjaPanelBackgroundDesign {
  /// Fundo sólido (`colors.base`).
  solid,

  /// Sem fundo: o painel mostra o que está atrás dele.
  transparent,
}

/// Contêiner com cabeçalho, como o `sap.m.Panel` do SAPUI5.
///
/// Mostra o título [headerText] e, abaixo, os itens de [content]
/// empilhados. Com [expandable], o cabeçalho tem uma seta e abre ou fecha o
/// conteúdo. É controlado: acionar o cabeçalho (toque, Enter ou Espaço)
/// chama [onExpand] com o estado oposto a [expanded], sem mudar sozinho;
/// sem [onExpand], o cabeçalho fica desabilitado.
///
/// Fechado, o conteúdo sai da tela, da semântica e do foco, mas mantém o
/// estado (o texto digitado num campo, por exemplo). Abre e fecha com a
/// animação do tema.
///
/// O Fiori não tem acordeão: empilhe painéis expansíveis.
///
/// ```dart
/// GjaPanel(
///   headerText: 'Pagamento',
///   expandable: true,
///   expanded: aberto,
///   onExpand: (value) => setState(() => aberto = value),
///   content: const [GjaText('Boleto em 30 dias')],
/// )
/// ```
class GjaPanel extends StatelessWidget {
  /// Cria o painel.
  const GjaPanel({
    this.headerText,
    this.content = const [],
    this.expandable = false,
    this.expanded = false,
    this.onExpand,
    this.backgroundDesign = GjaPanelBackgroundDesign.solid,
    super.key,
  });

  /// Título do cabeçalho; sem ele, o painel fixo não tem cabeçalho.
  final String? headerText;

  /// Conteúdo, empilhado na vertical.
  final List<Widget> content;

  /// Se o cabeçalho abre e fecha o conteúdo.
  final bool expandable;

  /// Se o conteúdo do painel expansível aparece.
  final bool expanded;

  /// Chamado com o novo estado quando o cabeçalho é acionado, como o evento
  /// `expand` do UI5.
  final ValueChanged<bool>? onExpand;

  /// Fundo do painel.
  final GjaPanelBackgroundDesign backgroundDesign;

  @override
  Widget build(BuildContext context) {
    final text = headerText;
    assert(
      !expandable || (text != null && text.isNotEmpty),
      'o painel expansível precisa de headerText',
    );
    final theme = GjaThemeData.of(context);
    final open = !expandable || expanded;
    final hasContent = content.isNotEmpty;

    Widget? header;
    if (text != null) {
      header = expandable
          ? _ExpandHeader(
              text: text,
              expanded: expanded,
              onPress: onExpand == null ? null : () => onExpand!(!expanded),
            )
          : Semantics(
              header: true,
              child: SizedBox(
                height: theme.density.listItemHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.l),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _Title(text),
                  ),
                ),
              ),
            );
      if (open && hasContent) {
        header = DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colors.separator,
                width: const BorderSide().width,
              ),
            ),
          ),
          child: header,
        );
      }
    }

    final body = AnimatedSize(
      duration: theme.motion.medium,
      curve: theme.motion.standard,
      alignment: AlignmentDirectional.topStart,
      child: ExcludeFocus(
        excluding: !open,
        child: Visibility(
          visible: open,
          maintainState: true,
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: switch (backgroundDesign) {
            GjaPanelBackgroundDesign.solid => theme.colors.base,
            GjaPanelBackgroundDesign.transparent => null,
          },
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?header, if (hasContent) body],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.header6.copyWith(color: theme.colors.text),
    );
  }
}

class _ExpandHeader extends StatelessWidget {
  const _ExpandHeader({
    required this.text,
    required this.expanded,
    required this.onPress,
  });

  final String text;
  final bool expanded;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MergeSemantics(
      child: Semantics(
        expanded: expanded,
        child: GjaInteractable(
          semanticLabel: text,
          onPressed: onPress,
          focusRingBorderRadius: BorderRadius.zero,
          builder: (context, states) {
            final active =
                states.contains(GjaInteractionState.hovered) ||
                states.contains(GjaInteractionState.pressed);
            return ExcludeSemantics(
              child: Opacity(
                opacity: theme.interaction.opacity(states),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: active ? theme.colors.hoverBackground : null,
                  ),
                  child: SizedBox(
                    height: theme.density.listItemHeight,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: theme.spacing.s,
                        end: theme.spacing.l,
                      ),
                      child: Row(
                        spacing: theme.spacing.s,
                        children: [
                          AnimatedRotation(
                            turns: expanded ? (rtl ? -0.25 : 0.25) : 0,
                            duration: theme.motion.medium,
                            curve: theme.motion.standard,
                            child: Icon(
                              GjaIcons.slimArrowRight,
                              size: theme.icons.control,
                              color: theme.colors.label,
                            ),
                          ),
                          Expanded(child: _Title(text)),
                        ],
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
}
