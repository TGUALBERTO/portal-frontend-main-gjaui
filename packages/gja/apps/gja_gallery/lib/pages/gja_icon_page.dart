import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaIcon": tamanhos, tons, um ícone com rótulo e um direcional em
/// LTR e RTL.
///
/// O catálogo completo de ícones fica na página "Ícones" (fundamento); esta
/// página mostra o widget.
class GjaIconPage extends StatelessWidget {
  /// Cria a página.
  const GjaIconPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaIcon';

  /// Rota nomeada.
  static const route = '/gja-icon';

  /// Chave do direcional em LTR.
  static const ltrKey = Key('gja-icon-ltr');

  /// Chave do direcional em RTL.
  static const rtlKey = Key('gja-icon-rtl');

  @override
  Widget build(BuildContext context) {
    final spacing = GjaTheme.of(context).spacing;

    Widget labeled(Widget icon, String label) => Padding(
      padding: EdgeInsets.only(right: spacing.l, bottom: spacing.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(height: spacing.xs),
          GjaLabel(label),
        ],
      ),
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
          title,
          level: GjaTitleLevel.h1,
          titleStyle: GjaTitleLevel.h2,
        ),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Tamanhos',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final size in GjaIconSize.values)
              labeled(GjaIcon(GjaIcons.search, size: size), size.name),
          ],
        ),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Tons',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        Wrap(
          children: [
            for (final tone in GjaIconTone.values)
              labeled(
                GjaIcon(
                  GjaIcons.information,
                  size: GjaIconSize.large,
                  tone: tone,
                ),
                tone.name,
              ),
          ],
        ),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Com rótulo',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        Row(
          children: [
            const GjaIcon(
              GjaIcons.warning,
              tone: GjaIconTone.warning,
              semanticLabel: 'Aviso',
            ),
            SizedBox(width: spacing.s),
            const GjaText('O leitor de tela anuncia "Aviso".'),
          ],
        ),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Direcional em LTR e RTL',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        Row(
          children: [
            labeled(
              const GjaIcon(
                GjaIcons.slimArrowRight,
                key: ltrKey,
                size: GjaIconSize.large,
              ),
              'LTR',
            ),
            labeled(
              const Directionality(
                textDirection: TextDirection.rtl,
                child: GjaIcon(
                  GjaIcons.slimArrowRight,
                  key: rtlKey,
                  size: GjaIconSize.large,
                ),
              ),
              'RTL',
            ),
          ],
        ),
      ],
    );
  }
}
