import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaBadge": contadores por estado, sobre botões de ícone e um
/// contador de notificações que aumenta ao tocar "Nova notificação".
class GjaBadgePage extends StatefulWidget {
  /// Cria a página.
  const GjaBadgePage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaBadge';

  /// Rota nomeada.
  static const route = '/gja-badge';

  /// Chave do contador sobre o sino.
  static const bellKey = Key('badge-bell');

  @override
  State<GjaBadgePage> createState() => _GjaBadgePageState();
}

class _GjaBadgePageState extends State<GjaBadgePage> {
  int _notifications = 0;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaBadgePage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Contadores avulsos e sobre elementos'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Por estado',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                for (final state in GjaValueState.values)
                  GjaBadge(count: 12, state: state),
                const GjaBadge(count: 1500),
              ],
            ),
            const GjaTitle(
              'Sobre botões de ícone',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              gap: GjaSpace.xxl,
              items: [
                GjaBadge(
                  key: GjaBadgePage.bellKey,
                  count: _notifications,
                  semanticLabel: '$_notifications notificações',
                  child: GjaButton(
                    icon: GjaIcons.bell,
                    tooltip: 'Notificações',
                    onPress: () {},
                    type: GjaButtonType.transparent,
                  ),
                ),
                GjaBadge(
                  count: 42,
                  state: GjaValueState.information,
                  semanticLabel: '42 pedidos',
                  child: GjaButton(
                    icon: GjaIcons.document,
                    tooltip: 'Pedidos',
                    onPress: () {},
                    type: GjaButtonType.transparent,
                  ),
                ),
              ],
            ),
            GjaButton(
              text: 'Nova notificação',
              onPress: () => setState(() => _notifications++),
            ),
          ],
        ),
      ],
    );
  }
}
