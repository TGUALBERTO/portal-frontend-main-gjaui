import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaAvatar": tamanhos, formas, iniciais, ícone e um avatar ativo
/// que mostra uma mensagem.
class GjaAvatarPage extends StatefulWidget {
  /// Cria a página.
  const GjaAvatarPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaAvatar';

  /// Rota nomeada.
  static const route = '/gja-avatar';

  /// Nome da pessoa do avatar ativo.
  static const person = 'Maria Barros';

  /// Mensagem mostrada ao acionar o avatar ativo.
  static const opened = 'Perfil de Maria Barros';

  @override
  State<GjaAvatarPage> createState() => _GjaAvatarPageState();
}

class _GjaAvatarPageState extends State<GjaAvatarPage> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaAvatarPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Imagem, iniciais ou ícone, como o sap.m.Avatar'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Tamanhos',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                for (final size in GjaAvatarSize.values)
                  GjaAvatar(initials: 'MB', size: size),
              ],
            ),
            const GjaTitle(
              'Formas e ícones',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            const GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                GjaAvatar(initials: 'JS', shape: GjaAvatarShape.square),
                GjaAvatar(),
                GjaAvatar(icon: GjaIcons.folderBlank),
                GjaAvatar(
                  icon: GjaIcons.document,
                  shape: GjaAvatarShape.square,
                ),
              ],
            ),
            const GjaTitle(
              'Ativo',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaAvatar(
              initials: 'MB',
              size: GjaAvatarSize.m,
              semanticLabel: GjaAvatarPage.person,
              onPress: () => setState(() => _opened = true),
            ),
            if (_opened) const GjaText(GjaAvatarPage.opened),
          ],
        ),
      ],
    );
  }
}
