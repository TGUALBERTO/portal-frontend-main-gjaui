import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaButton": um botão de cada tipo, com e sem ícone, uma barra
/// de ações só com ícone, um desabilitado e "Enviar", que fica ocupado ao
/// ser tocado.
class GjaButtonPage extends StatefulWidget {
  /// Cria a página.
  const GjaButtonPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaButton';

  /// Rota nomeada.
  static const route = '/gja-button';

  /// Chave do botão "Enviar".
  static const sendKey = Key('button-send');

  /// Ações da barra só com ícone.
  static const actions = [
    (GjaIcons.edit, 'Editar pedido'),
    (GjaIcons.delete, 'Excluir pedido'),
    (GjaIcons.download, 'Baixar PDF'),
    (GjaIcons.overflow, 'Mais ações'),
  ];

  @override
  State<GjaButtonPage> createState() => _GjaButtonPageState();
}

class _GjaButtonPageState extends State<GjaButtonPage> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaButtonPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Tipos Fiori, ícone, só ícone, desabilitado e ocupado'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Tipos',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                for (final type in GjaButtonType.values)
                  GjaButton(text: type.name, type: type, onPress: () {}),
              ],
            ),
            const GjaTitle(
              'Com ícone',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                GjaButton(
                  text: 'Salvar',
                  type: GjaButtonType.emphasized,
                  icon: GjaIcons.accept,
                  onPress: () {},
                ),
                GjaButton(
                  text: 'Editar',
                  icon: GjaIcons.edit,
                  onPress: () {},
                ),
                GjaButton(
                  text: 'Excluir',
                  type: GjaButtonType.reject,
                  icon: GjaIcons.delete,
                  onPress: () {},
                ),
              ],
            ),
            const GjaTitle(
              'Barra de ações só com ícone',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              gap: GjaSpace.xs,
              items: [
                for (final (icon, tooltip) in GjaButtonPage.actions)
                  GjaButton(
                    icon: icon,
                    tooltip: tooltip,
                    type: GjaButtonType.transparent,
                    onPress: () {},
                  ),
              ],
            ),
            const GjaTitle(
              'Tipos só com ícone',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                for (final type in GjaButtonType.values)
                  GjaButton(
                    icon: GjaIcons.accept,
                    tooltip: type.name,
                    type: type,
                    onPress: () {},
                  ),
              ],
            ),
            const GjaTitle(
              'Desabilitado e ocupado',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                const GjaButton(text: 'Aprovar', enabled: false),
                GjaButton(
                  key: GjaButtonPage.sendKey,
                  text: 'Enviar',
                  type: GjaButtonType.emphasized,
                  icon: GjaIcons.upload,
                  busy: _sending,
                  onPress: () => setState(() => _sending = true),
                ),
                if (_sending)
                  GjaButton(
                    text: 'Concluir envio',
                    type: GjaButtonType.transparent,
                    onPress: () => setState(() => _sending = false),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
