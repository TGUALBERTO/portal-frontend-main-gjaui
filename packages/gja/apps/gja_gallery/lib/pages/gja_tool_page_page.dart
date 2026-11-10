import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaToolPage": a página é uma página de ferramentas de
/// demonstração, com `GjaShellBar`, navegação no estado automático e
/// conteúdo principal.
class GjaToolPagePage extends StatelessWidget {
  /// Cria a página.
  const GjaToolPagePage({super.key});

  /// Título no índice.
  static const title = 'GjaToolPage';

  /// Rota nomeada.
  static const route = '/gja-tool-page';

  /// Chave da navegação de demonstração.
  static const navigationKey = Key('tool-page-navigation');

  /// Chave do conteúdo principal.
  static const mainKey = Key('tool-page-main');

  /// Texto do conteúdo principal.
  static const bodyText =
      'A navegação começa expandida, exceto em telas pequenas, e depois só '
      'muda pelo botão de menu da barra. Em telas pequenas, ela cobre o '
      'conteúdo principal.';

  @override
  Widget build(BuildContext context) {
    return GjaToolPage(
      header: Builder(
        builder: (context) => GjaShellBar(
          title: 'Compras',
          homeIcon: const GjaIcon(GjaIcons.home, tone: GjaIconTone.brand),
          showNavButton: true,
          onNavButtonPressed: () => Navigator.of(context).maybePop(),
          showMenuButton: true,
          onMenuButtonPressed: () =>
              GjaToolPage.toggleSideContentMode(context),
        ),
      ),
      sideContent: const _DemoNavigation(key: navigationKey),
      mainContents: [
        ListView(
          key: mainKey,
          children: const [
            GjaSpacing.padding(
              all: GjaSpace.pageMargin,
              child: GjaVBox(
                gap: GjaSpace.l,
                items: [
                  GjaTitle(
                    title,
                    level: GjaTitleLevel.h1,
                    titleStyle: GjaTitleLevel.h2,
                  ),
                  GjaText(bodyText),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Navegação de demonstração: ícones com rótulo quando expandida e só ícones
/// quando recolhida, sobre a superfície `base`, como a `SideNavigation`.
class _DemoNavigation extends StatelessWidget {
  const _DemoNavigation({super.key});

  static const _items = [
    (GjaIcons.home, 'Início'),
    (GjaIcons.document, 'Pedidos'),
    (GjaIcons.personPlaceholder, 'Fornecedores'),
    (GjaIcons.actionSettings, 'Configurações'),
  ];

  @override
  Widget build(BuildContext context) {
    final expanded = GjaToolPage.sideExpandedOf(context) ?? true;
    return GjaContainer(
      surface: GjaSurface.base,
      child: GjaSpacing.padding(
        vertical: GjaSpace.s,
        child: GjaVBox(
          gap: GjaSpace.none,
          items: [
            for (final (icon, label) in _items)
              GjaSpacing.padding(
                horizontal: GjaSpace.m,
                vertical: GjaSpace.s,
                child: GjaHBox(
                  items: [
                    GjaIcon(icon, semanticLabel: expanded ? null : label),
                    if (expanded) GjaText(label),
                    // Largura da navegação expandida, como a da Fiori.
                    if (expanded)
                      const GjaSpacing.horizontal(GjaSpace.xxxl),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
