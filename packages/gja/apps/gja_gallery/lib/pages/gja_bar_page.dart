import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaBar": uma barra de cada desenho e os alinhamentos `none` e
/// `start` do conteúdo central.
class GjaBarPage extends StatelessWidget {
  /// Cria a página.
  const GjaBarPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaBar';

  /// Rota nomeada.
  static const route = '/gja-bar';

  /// Desenhos exibidos, cada um numa barra.
  static const designs = [
    GjaBarDesign.header,
    GjaBarDesign.subHeader,
    GjaBarDesign.footer,
    GjaBarDesign.floatingFooter,
  ];

  /// Chave da barra de [design].
  static Key designKey(GjaBarDesign design) =>
      Key('gja-bar-${design.name}');

  /// Chave da barra com o alinhamento [alignment].
  static Key alignmentKey(GjaTitleAlignment alignment) =>
      Key('gja-bar-alignment-${alignment.name}');

  @override
  Widget build(BuildContext context) {
    Widget sample({
      required Key key,
      required String label,
      GjaBarDesign design = GjaBarDesign.header,
      GjaTitleAlignment alignment = GjaTitleAlignment.none,
    }) => GjaBar(
      key: key,
      design: design,
      titleAlignment: alignment,
      contentLeft: [
        GjaButton(
          icon: GjaIcons.navBack,
          tooltip: 'Voltar',
          onPress: () {},
          type: GjaButtonType.transparent,
        ),
      ],
      contentMiddle: [GjaTitle(label)],
      contentRight: [
        GjaButton(
          icon: GjaIcons.edit,
          tooltip: 'Editar',
          onPress: () {},
          type: GjaButtonType.transparent,
        ),
      ],
    );
    return GjaPage(
      title: title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Desenhos',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            for (final design in designs)
              sample(
                key: designKey(design),
                label: design.name,
                design: design,
              ),
            const GjaTitle(
              'Alinhamento do conteúdo central',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            for (final alignment in const [
              GjaTitleAlignment.none,
              GjaTitleAlignment.start,
            ])
              sample(
                key: alignmentKey(alignment),
                label: 'titleAlignment ${alignment.name}',
                alignment: alignment,
              ),
          ],
        ),
      ],
    );
  }
}
