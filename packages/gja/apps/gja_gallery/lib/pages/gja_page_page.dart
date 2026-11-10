import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaPage": construída com `GjaPage`, com voltar, conteúdo do
/// cabeçalho, subcabeçalho, conteúdo rolável e rodapé, que pode flutuar, e a
/// escolha do fundo.
class GjaPagePage extends StatefulWidget {
  /// Cria a página.
  const GjaPagePage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaPage';

  /// Rota nomeada.
  static const route = '/gja-page';

  /// Chave do botão que alterna o rodapé flutuante.
  static const floatingKey = Key('gja-page-floating');

  /// Chave do botão de cada fundo.
  static Key designKey(GjaPageBackgroundDesign design) =>
      Key('gja-page-design-${design.name}');

  @override
  State<GjaPagePage> createState() => _GjaPagePageState();
}

class _GjaPagePageState extends State<GjaPagePage> {
  var _design = GjaPageBackgroundDesign.standard;
  var _floating = false;

  @override
  Widget build(BuildContext context) {
    void back() => Navigator.of(context).maybePop();
    return GjaPage(
      title: GjaPagePage.title,
      showNavButton: true,
      onNavButtonPress: back,
      headerContent: [
        GjaButton(
          icon: GjaIcons.sysHelp,
          tooltip: 'Ajuda',
          onPress: () {},
          type: GjaButtonType.transparent,
        ),
      ],
      subHeader: const GjaBar(
        contentMiddle: [GjaLabel('Cabeçalho, conteúdo e rodapé')],
      ),
      backgroundDesign: _design,
      contentPadding: GjaContentPadding.responsive,
      floatingFooter: _floating,
      footer: GjaBar(
        contentRight: [
          GjaButton(text: 'Cancelar', onPress: back),
          GjaButton(
            text: 'Salvar',
            type: GjaButtonType.emphasized,
            onPress: back,
          ),
        ],
      ),
      content: [
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Quando usar',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            const GjaText(
              'Use GjaPage como conteúdo principal do GjaToolPage ou como '
              'página de uma rota. O botão de voltar aparece com '
              'showNavButton, e o rodapé, com footer.',
            ),
            const GjaTitle(
              'Fundo',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                for (final design in GjaPageBackgroundDesign.values)
                  GjaButton(
                    key: GjaPagePage.designKey(design),
                    text: design.name,
                    type: design == _design
                        ? GjaButtonType.emphasized
                        : GjaButtonType.standard,
                    onPress: () => setState(() => _design = design),
                  ),
              ],
            ),
            const GjaTitle(
              'Rodapé',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaButton(
              key: GjaPagePage.floatingKey,
              text: _floating ? 'Rodapé fixo' : 'Rodapé flutuante',
              onPress: () => setState(() => _floating = !_floating),
            ),
            const GjaTitle(
              'Rolagem',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            const GjaText(
              'O conteúdo rola entre o cabeçalho e o rodapé, que ficam fixos. '
              'Para listas e tabelas com rolagem própria, use '
              'enableScrolling: false.',
            ),
          ],
        ),
      ],
    );
  }
}
