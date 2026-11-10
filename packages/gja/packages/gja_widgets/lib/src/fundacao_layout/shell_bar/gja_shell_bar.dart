import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../acoes_navegacao/button/gja_button.dart';
import '../../acoes_navegacao/menu/gja_menu.dart';
import '../../exibicao_dados/avatar/gja_avatar.dart';
import '../../exibicao_dados/badge/gja_badge.dart';
import '../../exibicao_dados/tooltip/gja_tooltip.dart';
import '../../feedback_sobreposicoes/popover/gja_popover.dart';
import '../container/gja_container.dart';
import '../title/gja_title.dart';

/// Barra superior da aplicação, como o `sap.f.ShellBar` do SAPUI5.
///
/// No início ficam os botões de voltar ([showNavButton]) e de menu
/// ([showMenuButton]), o ícone inicial ([homeIcon]), o [title] e o
/// [secondTitle]; no fim, a pesquisa ([showSearch]), as notificações
/// ([showNotifications]), o [additionalContent], o [profile] e o seletor de
/// produtos ([showProductSwitcher]). Cada elemento avisa a aplicação pelo seu
/// callback; um botão visível sem callback fica desabilitado. Quando falta
/// espaço, o segundo título e depois o título terminam com reticências.
///
/// Com [menu], o título vira um botão que abre um menu com esses itens. Em
/// larguras pequenas (classe S), as notificações e os `GjaButton` de
/// [additionalContent] vão para um menu "mais", como no `OverflowToolbar` do
/// `sap.f.ShellBar`.
///
/// Em geral é o `header` de um `GjaToolPage`, com o botão de menu ligado ao
/// conteúdo lateral:
///
/// ```dart
/// GjaShellBar(
///   title: 'Compras',
///   showMenuButton: true,
///   onMenuButtonPressed: () => GjaToolPage.toggleSideContentMode(context),
///   showNotifications: true,
///   notificationsNumber: 4,
///   onNotificationsPressed: openNotifications,
///   profile: const GjaAvatar(initials: 'TA'),
///   onAvatarPressed: openProfile,
/// )
/// ```
class GjaShellBar extends StatelessWidget {
  /// Cria a barra.
  const GjaShellBar({
    this.title,
    this.secondTitle,
    this.homeIcon,
    this.homeIconTooltip,
    this.showNavButton = false,
    this.showMenuButton = false,
    this.showSearch = false,
    this.showNotifications = false,
    this.notificationsNumber = 0,
    this.showProductSwitcher = false,
    this.profile,
    this.additionalContent = const [],
    this.menu = const [],
    this.onHomeIconPressed,
    this.onNavButtonPressed,
    this.onMenuButtonPressed,
    this.onSearchButtonPressed,
    this.onNotificationsPressed,
    this.onProductSwitcherPressed,
    this.onAvatarPressed,
    super.key,
  }) : assert(
         notificationsNumber >= 0,
         '"notificationsNumber" não pode ser negativo',
       );

  /// Título principal, anunciado como cabeçalho de nível 1.
  final String? title;

  /// Segundo título, depois do principal.
  final String? secondTitle;

  /// Ícone inicial, como o logotipo da aplicação.
  final Widget? homeIcon;

  /// Dica do ícone inicial; nula usa o texto `logo` do núcleo.
  final String? homeIconTooltip;

  /// Se mostra o botão de voltar.
  final bool showNavButton;

  /// Se mostra o botão de menu.
  final bool showMenuButton;

  /// Se mostra o botão de pesquisa.
  final bool showSearch;

  /// Se mostra o botão de notificações.
  final bool showNotifications;

  /// Número no contador do botão de notificações; zero oculta o contador.
  final int notificationsNumber;

  /// Se mostra o botão do seletor de produtos.
  final bool showProductSwitcher;

  /// Perfil do usuário, exibido no tamanho `xs` e com [onAvatarPressed]; o
  /// `onPress` e o tamanho do próprio avatar são ignorados.
  final GjaAvatar? profile;

  /// Conteúdo adicional, entre as notificações e o perfil. Em larguras
  /// pequenas, os `GjaButton` daqui vão para o menu "mais".
  final List<Widget> additionalContent;

  /// Itens do menu aberto pelo título, como o `menu` do `sap.f.ShellBar`;
  /// vazio deixa o título como texto.
  final List<GjaMenuItem> menu;

  /// Toque no ícone inicial; nulo o deixa não interativo.
  final VoidCallback? onHomeIconPressed;

  /// Toque no botão de voltar; nulo o desabilita.
  final VoidCallback? onNavButtonPressed;

  /// Toque no botão de menu; nulo o desabilita.
  final VoidCallback? onMenuButtonPressed;

  /// Toque no botão de pesquisa; nulo o desabilita.
  final VoidCallback? onSearchButtonPressed;

  /// Toque no botão de notificações; nulo o desabilita.
  final VoidCallback? onNotificationsPressed;

  /// Toque no botão do seletor de produtos; nulo o desabilita.
  final VoidCallback? onProductSwitcherPressed;

  /// Toque no perfil; nulo o deixa não interativo.
  final VoidCallback? onAvatarPressed;

  /// Margem horizontal pela classe da largura da barra, como os paddings
  /// Phone, Tablet e Desktop do `sap.f.ShellBar`.
  static double _margin(GjaSpacingTokens spacing, GjaSizeClass size) =>
      switch (size) {
        GjaSizeClass.small => spacing.pageMargin,
        GjaSizeClass.medium => spacing.xxl,
        GjaSizeClass.large || GjaSizeClass.extraLarge => spacing.xxxl,
      };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final texts = GjaLocalizations.of(context);
    final homeIcon = this.homeIcon;
    final profile = this.profile;
    final title = this.title;
    final secondTitle = this.secondTitle;

    final start = <Widget>[
      if (showNavButton)
        GjaButton(
          icon: GjaIcons.navBack,
          tooltip: texts.back,
          onPress: onNavButtonPressed,
          enabled: onNavButtonPressed != null,
          type: GjaButtonType.transparent,
        ),
      if (showMenuButton)
        GjaButton(
          icon: GjaIcons.menu2,
          tooltip: texts.menu,
          onPress: onMenuButtonPressed,
          enabled: onMenuButtonPressed != null,
          type: GjaButtonType.transparent,
        ),
      if (homeIcon != null)
        _HomeIcon(
          tooltip: homeIconTooltip ?? texts.logo,
          onPressed: onHomeIconPressed,
          child: homeIcon,
        ),
    ];
    final search = <Widget>[
      if (showSearch)
        GjaButton(
          icon: GjaIcons.search,
          tooltip: texts.search,
          onPress: onSearchButtonPressed,
          enabled: onSearchButtonPressed != null,
          type: GjaButtonType.transparent,
        ),
    ];
    final notifications = <Widget>[
      if (showNotifications)
        GjaBadge(
          count: notificationsNumber,
          child: GjaButton(
            icon: GjaIcons.bell,
            tooltip: texts.notifications,
            onPress: onNotificationsPressed,
            enabled: onNotificationsPressed != null,
            type: GjaButtonType.transparent,
          ),
        ),
    ];
    final trailing = <Widget>[
      if (profile != null)
        GjaAvatar(
          image: profile.image,
          initials: profile.initials,
          icon: profile.icon,
          size: GjaAvatarSize.xs,
          shape: profile.shape,
          semanticLabel: profile.semanticLabel ?? texts.profile,
          onPress: onAvatarPressed,
        ),
      if (showProductSwitcher)
        GjaButton(
          icon: GjaIcons.grid,
          tooltip: texts.products,
          onPress: onProductSwitcherPressed,
          enabled: onProductSwitcherPressed != null,
          type: GjaButtonType.transparent,
        ),
    ];

    /// Itens do menu "mais": as notificações e os botões adicionais.
    List<GjaMenuItem> overflowItems() => [
      if (showNotifications)
        GjaMenuItem(
          text: notificationsNumber > 0
              ? '${texts.notifications} '
                    '(${texts.formatInteger(notificationsNumber)})'
              : texts.notifications,
          icon: GjaIcons.bell,
          enabled: onNotificationsPressed != null,
          onPress: onNotificationsPressed,
        ),
      for (final widget in additionalContent)
        if (widget is GjaButton)
          GjaMenuItem(
            text: widget.text ?? widget.tooltip ?? '',
            icon: widget.icon,
            enabled: widget.enabled && widget.onPress != null,
            onPress: widget.onPress,
          ),
    ];

    final gap = theme.spacing.xs;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: texts.shellBar,
      child: GjaContainer(
        surface: GjaSurface.shell,
        shadow: GjaShadow.header,
        child: SizedBox(
          height: theme.spacing.xxxl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sizeClass = theme.breakpoints.classify(
                constraints.maxWidth,
              );
              final margin = _margin(theme.spacing, sizeClass);
              final overflow = sizeClass == GjaSizeClass.small
                  ? overflowItems()
                  : const <GjaMenuItem>[];
              final end = <Widget>[
                ...search,
                if (overflow.isEmpty) ...[
                  ...notifications,
                  ...additionalContent,
                ] else ...[
                  for (final widget in additionalContent)
                    if (widget is! GjaButton) widget,
                  _MoreMenu(items: overflow, tooltip: texts.more),
                ],
                ...trailing,
              ];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: margin),
                child: Row(
                  spacing: gap,
                  children: [
                    ...start,
                    // Os títulos ocupam o espaço livre e levam o fim da barra
                    // à borda final.
                    Expanded(
                      child: CustomMultiChildLayout(
                        delegate: _TitlesLayout(
                          gap: gap,
                          direction: Directionality.of(context),
                        ),
                        children: [
                          if (title != null)
                            LayoutId(
                              id: _TitleSlot.title,
                              child: menu.isEmpty
                                  ? GjaTitle(
                                      title,
                                      level: GjaTitleLevel.h1,
                                      titleStyle: GjaTitleLevel.h5,
                                    )
                                  : _TitleMenu(title: title, items: menu),
                            ),
                          if (secondTitle != null)
                            LayoutId(
                              id: _TitleSlot.second,
                              child: Text(
                                secondTitle,
                                style: theme.typography.small.copyWith(
                                  color: theme.colors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...end,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _TitleSlot { title, second }

/// Título que abre um menu, como o `menu` do `sap.f.ShellBar`.
class _TitleMenu extends StatefulWidget {
  const _TitleMenu({required this.title, required this.items});

  final String title;
  final List<GjaMenuItem> items;

  @override
  State<_TitleMenu> createState() => _TitleMenuState();
}

class _TitleMenuState extends State<_TitleMenu> {
  final _controller = GjaPopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final family = GjaControlColors.of(
      GjaControlFamily.transparent,
      theme.colors,
    );
    final corners = BorderRadius.circular(theme.radius.button);
    return GjaMenu(
      controller: _controller,
      semanticLabel: widget.title,
      items: widget.items,
      child: MergeSemantics(
        child: GjaInteractable(
          semanticLabel: widget.title,
          onPressed: _controller.toggle,
          focusRingBorderRadius: corners,
          builder: (context, states) => ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: family.resolve(states).background,
                borderRadius: corners,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.xs,
                  vertical: theme.spacing.xxs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.spacing.xs,
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.header5.copyWith(
                          color: theme.colors.text,
                        ),
                      ),
                    ),
                    Icon(
                      GjaIcons.slimArrowDown,
                      size: theme.icons.control,
                      color: theme.colors.text,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão "mais" com os elementos que não cabem na barra.
class _MoreMenu extends StatefulWidget {
  const _MoreMenu({required this.items, required this.tooltip});

  final List<GjaMenuItem> items;
  final String tooltip;

  @override
  State<_MoreMenu> createState() => _MoreMenuState();
}

class _MoreMenuState extends State<_MoreMenu> {
  final _controller = GjaPopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GjaMenu(
    controller: _controller,
    semanticLabel: widget.tooltip,
    items: widget.items,
    child: GjaButton(
      icon: GjaIcons.overflow,
      tooltip: widget.tooltip,
      type: GjaButtonType.transparent,
      onPress: _controller.toggle,
    ),
  );
}

/// Dispõe o título com toda a largura e o segundo título com o que sobrar,
/// para que o segundo encolha primeiro; os dois ficam centrados na altura.
class _TitlesLayout extends MultiChildLayoutDelegate {
  _TitlesLayout({required this.gap, required this.direction});

  final double gap;
  final TextDirection direction;

  @override
  void performLayout(Size size) {
    var used = 0.0;
    Size? titleSize;
    if (hasChild(_TitleSlot.title)) {
      titleSize = layoutChild(_TitleSlot.title, BoxConstraints.loose(size));
      used = titleSize.width;
    }
    Size? secondSize;
    if (hasChild(_TitleSlot.second)) {
      final offset = titleSize == null ? 0.0 : gap;
      final available = (size.width - used - offset).clamp(0.0, size.width);
      secondSize = layoutChild(
        _TitleSlot.second,
        BoxConstraints.loose(Size(available, size.height)),
      );
      used += offset;
    }
    double x(double start, double width) =>
        direction == TextDirection.ltr ? start : size.width - start - width;
    if (titleSize != null) {
      positionChild(
        _TitleSlot.title,
        Offset(x(0, titleSize.width), (size.height - titleSize.height) / 2),
      );
    }
    if (secondSize != null) {
      positionChild(
        _TitleSlot.second,
        Offset(
          x(used, secondSize.width),
          (size.height - secondSize.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_TitlesLayout oldDelegate) =>
      gap != oldDelegate.gap || direction != oldDelegate.direction;
}

/// Ícone inicial: interativo com [onPressed], como o `homeIcon` do ShellBar.
class _HomeIcon extends StatelessWidget {
  const _HomeIcon({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onPressed = this.onPressed;
    if (onPressed == null) {
      return Semantics(
        label: tooltip,
        image: true,
        child: ExcludeSemantics(child: child),
      );
    }
    final theme = GjaThemeData.of(context);
    final family = GjaControlColors.of(
      GjaControlFamily.transparent,
      theme.colors,
    );
    final corners = BorderRadius.circular(theme.radius.button);
    return GjaTooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: MergeSemantics(
        child: GjaInteractable(
          semanticLabel: tooltip,
          onPressed: onPressed,
          focusRingBorderRadius: corners,
          builder: (context, states) => ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: family.resolve(states).background,
                borderRadius: corners,
              ),
              child: Padding(
                padding: EdgeInsets.all(theme.spacing.xxs),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
