import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaShellBar": a barra completa, a barra só com título e uma
/// barra estreita com os títulos truncados.
class GjaShellBarPage extends StatefulWidget {
  /// Cria a página.
  const GjaShellBarPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaShellBar';

  /// Rota nomeada.
  static const route = '/gja-shell-bar';

  /// Chave da barra completa.
  static const fullKey = Key('shell-bar-full');

  /// Chave da barra só com título.
  static const titleOnlyKey = Key('shell-bar-title-only');

  /// Chave da barra estreita.
  static const narrowKey = Key('shell-bar-narrow');

  /// Mensagem mostrada pelo botão de menu da barra completa.
  static const menuMessage = 'Botão de menu acionado';

  @override
  State<GjaShellBarPage> createState() => _GjaShellBarPageState();
}

class _GjaShellBarPageState extends State<GjaShellBarPage> {
  String _message = '';

  void _show(String message) => setState(() => _message = message);

  @override
  Widget build(BuildContext context) {
    final spacing = GjaTheme.of(context).spacing;
    Widget heading(String text) => GjaTitle(
      text,
      level: GjaTitleLevel.h2,
      titleStyle: GjaTitleLevel.h3,
    );
    return ListView(
      padding: EdgeInsets.all(spacing.pageMargin),
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Semantics(button: true, child: const GjaText('← Voltar')),
        ),
        SizedBox(height: spacing.stackGap),
        const GjaTitle(
          GjaShellBarPage.title,
          level: GjaTitleLevel.h1,
          titleStyle: GjaTitleLevel.h2,
        ),
        SizedBox(height: spacing.sectionGap),
        heading('Barra completa'),
        SizedBox(height: spacing.s),
        GjaShellBar(
          key: GjaShellBarPage.fullKey,
          title: 'Compras',
          secondTitle: 'Pedidos de compra',
          homeIcon: const GjaIcon(GjaIcons.home, tone: GjaIconTone.brand),
          showNavButton: true,
          showMenuButton: true,
          showSearch: true,
          showNotifications: true,
          notificationsNumber: 4,
          showProductSwitcher: true,
          profile: const GjaAvatar(initials: 'TA'),
          menu: [
            GjaMenuItem(
              text: 'Compras',
              onPress: () => _show('Área: Compras'),
            ),
            GjaMenuItem(
              text: 'Contratos',
              onPress: () => _show('Área: Contratos'),
            ),
          ],
          onHomeIconPressed: () => _show('Ícone inicial acionado'),
          onNavButtonPressed: () => _show('Botão de voltar acionado'),
          onMenuButtonPressed: () => _show(GjaShellBarPage.menuMessage),
          onSearchButtonPressed: () => _show('Pesquisa acionada'),
          onNotificationsPressed: () => _show('Notificações acionadas'),
          onAvatarPressed: () => _show('Perfil acionado'),
          onProductSwitcherPressed: () => _show('Seletor de produtos acionado'),
        ),
        SizedBox(height: spacing.s),
        GjaText(_message),
        SizedBox(height: spacing.sectionGap),
        heading('Só com título'),
        SizedBox(height: spacing.s),
        const GjaShellBar(
          key: GjaShellBarPage.titleOnlyKey,
          title: 'Compras',
        ),
        SizedBox(height: spacing.sectionGap),
        heading('Barra estreita'),
        SizedBox(height: spacing.s),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 360,
            child: GjaShellBar(
              key: GjaShellBarPage.narrowKey,
              title: 'Compras e suprimentos corporativos',
              secondTitle: 'Pedidos de compra em aberto no período',
              showMenuButton: true,
              showNotifications: true,
              notificationsNumber: 4,
              additionalContent: [
                GjaButton(
                  icon: GjaIcons.sysHelp,
                  tooltip: 'Ajuda',
                  type: GjaButtonType.transparent,
                  onPress: () => _show('Ajuda acionada'),
                ),
              ],
              profile: const GjaAvatar(initials: 'TA'),
              onMenuButtonPressed: () => _show(GjaShellBarPage.menuMessage),
              onNotificationsPressed: () => _show('Notificações acionadas'),
              onAvatarPressed: () => _show('Perfil acionado'),
            ),
          ),
        ),
      ],
    );
  }
}
