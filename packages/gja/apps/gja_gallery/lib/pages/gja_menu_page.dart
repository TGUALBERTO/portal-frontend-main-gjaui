import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaMenu": um menu de ações com atalhos e seções sob o botão
/// "Ações", e um menu curto sob um botão de ícone.
class GjaMenuPage extends StatefulWidget {
  /// Cria a página.
  const GjaMenuPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaMenu';

  /// Rota nomeada.
  static const route = '/gja-menu';

  /// Rótulo do botão que abre o menu de ações.
  static const actions = 'Ações';

  /// Mensagem com a última ação acionada.
  static String lastAction(String label) => 'Última ação: $label';

  @override
  State<GjaMenuPage> createState() => _GjaMenuPageState();
}

class _GjaMenuPageState extends State<GjaMenuPage> {
  final _actions = GjaPopoverController();
  final _more = GjaPopoverController();
  String? _last;

  @override
  void dispose() {
    _actions.dispose();
    _more.dispose();
    super.dispose();
  }

  VoidCallback _record(String label) =>
      () => setState(() => _last = label);

  @override
  Widget build(BuildContext context) {
    final last = _last;
    return GjaPage(
      title: GjaMenuPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Menus de ações no modelo do sap.m.Menu'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaText(
              'Os atalhos são só exibidos; seções começam com um divisor.',
            ),
            GjaHBox(
              gap: GjaSpace.m,
              items: [
                GjaMenu(
                  controller: _actions,
                  semanticLabel: GjaMenuPage.actions,
                  items: [
                    GjaMenuItem(
                      text: 'Editar',
                      icon: GjaIcons.edit,
                      shortcutText: 'Ctrl+E',
                      onPress: _record('Editar'),
                    ),
                    GjaMenuItem(
                      text: 'Copiar',
                      icon: GjaIcons.copy,
                      shortcutText: 'Ctrl+C',
                      onPress: _record('Copiar'),
                    ),
                    const GjaMenuItem(
                      text: 'Exportar',
                      icon: GjaIcons.download,
                      enabled: false,
                    ),
                    GjaMenuItem(
                      text: 'Excluir',
                      icon: GjaIcons.delete,
                      startsSection: true,
                      onPress: _record('Excluir'),
                    ),
                  ],
                  child: GjaButton(
                    text: GjaMenuPage.actions,
                    onPress: _actions.toggle,
                  ),
                ),
                GjaMenu(
                  controller: _more,
                  semanticLabel: 'Mais ações',
                  items: [
                    GjaMenuItem(
                      text: 'Atualizar',
                      icon: GjaIcons.refresh,
                      onPress: _record('Atualizar'),
                    ),
                    GjaMenuItem(
                      text: 'Configurações',
                      icon: GjaIcons.actionSettings,
                      onPress: _record('Configurações'),
                    ),
                  ],
                  child: GjaButton(
                    icon: GjaIcons.overflow,
                    tooltip: 'Mais ações',
                    onPress: _more.toggle,
                    type: GjaButtonType.transparent,
                  ),
                ),
              ],
            ),
            if (last != null) GjaText(GjaMenuPage.lastAction(last)),
          ],
        ),
      ],
    );
  }
}
