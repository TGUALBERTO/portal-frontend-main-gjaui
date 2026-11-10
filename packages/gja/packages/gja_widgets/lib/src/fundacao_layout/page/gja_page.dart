import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../acoes_navegacao/button/gja_button.dart';
import '../bar/gja_bar.dart';
import '../container/gja_container.dart';
import '../title/gja_title.dart';

/// Fundo de uma [GjaPage], como o `sap.m.PageBackgroundDesign` do SAPUI5.
enum GjaPageBackgroundDesign {
  /// Fundo da aplicação (`colors.background`).
  standard,

  /// Fundo sólido da aplicação (`colors.background`).
  solid,

  /// Fundo de lista (`colors.base`).
  list,

  /// Sem fundo.
  transparent,
}

/// Espaçamento do conteúdo de uma [GjaPage], como as classes de padding do
/// SAPUI5.
enum GjaContentPadding {
  /// Sem espaçamento (`sapUiNoContentPadding`, o padrão da página).
  none,

  /// `spacing.l` nos quatro lados (`sapUiContentPadding`).
  standard,

  /// Pela classe da tela: nenhum em `small`, `spacing.l` em `medium` e
  /// `spacing.l` por `spacing.xxl` a partir de `large`
  /// (`sapUiResponsiveContentPadding`).
  responsive,
}

/// Página de conteúdo, como o `sap.m.Page` do SAPUI5.
///
/// O cabeçalho é uma `GjaBar` com o botão de voltar ([showNavButton]), o
/// [title] e o [headerContent], ou o [customHeader]. Abaixo vêm o
/// [subHeader], o [content], que rola com [enableScrolling] ou divide a altura
/// disponível sem ela, e o [footer], fixo ou flutuante ([floatingFooter]). O
/// fundo segue [backgroundDesign], e o espaçamento do conteúdo,
/// [contentPadding]. Barras com desenho `auto` no subcabeçalho e no rodapé
/// recebem o desenho da área.
///
/// Precisa de altura limitada: use-a como conteúdo principal do
/// `GjaToolPage` ou como página de uma rota.
///
/// ```dart
/// GjaPage(
///   title: 'Pedido 4711',
///   showNavButton: true,
///   onNavButtonPress: () => Navigator.of(context).maybePop(),
///   headerContent: [EditarAction()],
///   contentPadding: GjaContentPadding.responsive,
///   content: const [DetalhesDoPedido()],
///   footer: GjaBar(contentRight: [CancelarAction(), SalvarAction()]),
/// )
/// ```
class GjaPage extends StatelessWidget {
  /// Cria a página.
  const GjaPage({
    this.title,
    this.titleLevel = GjaTitleLevel.auto,
    this.titleAlignment = GjaTitleAlignment.auto,
    this.showNavButton = false,
    this.navButtonTooltip,
    this.onNavButtonPress,
    this.headerContent = const [],
    this.customHeader,
    this.showHeader = true,
    this.subHeader,
    this.showSubHeader = true,
    this.content = const [],
    this.enableScrolling = true,
    this.backgroundDesign = GjaPageBackgroundDesign.standard,
    this.contentPadding = GjaContentPadding.none,
    this.footer,
    this.showFooter = true,
    this.floatingFooter = false,
    super.key,
  });

  /// Título no cabeçalho, anunciado como cabeçalho com [titleLevel].
  final String? title;

  /// Nível semântico do título.
  final GjaTitleLevel titleLevel;

  /// Alinhamento do título no cabeçalho.
  final GjaTitleAlignment titleAlignment;

  /// Se mostra o botão de voltar.
  final bool showNavButton;

  /// Dica do botão de voltar; nula usa o texto `back` do núcleo.
  final String? navButtonTooltip;

  /// Toque no botão de voltar; nulo o desabilita.
  final VoidCallback? onNavButtonPress;

  /// Conteúdo no fim do cabeçalho.
  final List<Widget> headerContent;

  /// Cabeçalho próprio, no lugar do interno.
  final Widget? customHeader;

  /// Se mostra o cabeçalho.
  final bool showHeader;

  /// Subcabeçalho, logo abaixo do cabeçalho.
  final Widget? subHeader;

  /// Se mostra o [subHeader].
  final bool showSubHeader;

  /// Conteúdo da página, empilhado.
  final List<Widget> content;

  /// Se o conteúdo rola; sem rolagem, os itens dividem a altura disponível.
  final bool enableScrolling;

  /// Fundo da página.
  final GjaPageBackgroundDesign backgroundDesign;

  /// Espaçamento do conteúdo.
  final GjaContentPadding contentPadding;

  /// Rodapé, em geral uma `GjaBar` com as ações no fim.
  final Widget? footer;

  /// Se mostra o [footer].
  final bool showFooter;

  /// Se o rodapé flutua sobre o conteúdo.
  final bool floatingFooter;

  EdgeInsets _padding(GjaSpacingTokens spacing, GjaSizeClass size) =>
      switch (contentPadding) {
        GjaContentPadding.none => EdgeInsets.zero,
        GjaContentPadding.standard => EdgeInsets.all(spacing.l),
        GjaContentPadding.responsive => switch (size) {
          GjaSizeClass.small => EdgeInsets.zero,
          GjaSizeClass.medium => EdgeInsets.all(spacing.l),
          GjaSizeClass.large || GjaSizeClass.extraLarge =>
            EdgeInsets.symmetric(horizontal: spacing.xxl, vertical: spacing.l),
        },
      };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final spacing = theme.spacing;
    final title = this.title;
    final subHeader = this.subHeader;
    final footer = showFooter ? this.footer : null;
    final floating = footer != null && floatingFooter;

    Widget? header;
    if (showHeader) {
      header =
          customHeader ??
          GjaBar(
            design: GjaBarDesign.header,
            titleAlignment: titleAlignment,
            contentLeft: [
              if (showNavButton)
                GjaButton(
                  icon: GjaIcons.navBack,
                  tooltip:
                      navButtonTooltip ?? GjaLocalizations.of(context).back,
                  onPress: onNavButtonPress,
                  enabled: onNavButtonPress != null,
                  type: GjaButtonType.transparent,
                ),
            ],
            contentMiddle: [
              if (title != null) GjaTitle(title, level: titleLevel),
            ],
            contentRight: headerContent,
          );
    }

    var padding = _padding(spacing, GjaResponsive.screenSizeClassOf(context));
    if (floating) {
      // O fim do conteúdo fica acima do rodapé flutuante.
      padding += EdgeInsets.only(
        bottom: theme.density.barHeight + spacing.s * 2,
      );
    }
    final Widget body = enableScrolling
        ? SingleChildScrollView(
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            ),
          )
        : Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final item in content) Expanded(child: item)],
            ),
          );

    final page = LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedHeight,
          'GjaPage precisa de altura limitada: use-a como conteúdo '
          'principal do GjaToolPage ou como página de uma rota, não '
          'dentro de uma rolagem',
        );
        // O cabeçalho vem por último para ser pintado sobre o conteúdo, com a
        // sombra visível; `up` o mantém no topo. Foco e semântica seguem a
        // geometria.
        return Column(
          verticalDirection: VerticalDirection.up,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (footer != null && !floating)
              GjaBarScope(design: GjaBarDesign.footer, child: footer),
            Expanded(child: body),
            if (subHeader != null && showSubHeader)
              GjaBarScope(design: GjaBarDesign.subHeader, child: subHeader),
            ?header,
          ],
        );
      },
    );

    return GjaContainer(
      surface: switch (backgroundDesign) {
        GjaPageBackgroundDesign.standard ||
        GjaPageBackgroundDesign.solid => GjaSurface.background,
        GjaPageBackgroundDesign.list => GjaSurface.base,
        GjaPageBackgroundDesign.transparent => GjaSurface.none,
      },
      child: !floating
          ? page
          : Stack(
              children: [
                Positioned.fill(child: page),
                PositionedDirectional(
                  start: spacing.s,
                  end: spacing.s,
                  bottom: spacing.s,
                  child: GjaBarScope(
                    design: GjaBarDesign.floatingFooter,
                    child: footer,
                  ),
                ),
              ],
            ),
    );
  }
}
