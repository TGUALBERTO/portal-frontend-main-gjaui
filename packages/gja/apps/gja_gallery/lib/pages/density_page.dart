import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "Densidade": controles simulados nas duas densidades, lado a lado.
///
/// Cada coluna usa as dimensões e o espaçamento da própria densidade; a
/// tipografia é a mesma nas duas. A largura da coluna é literal da galeria.
class DensityPage extends StatelessWidget {
  /// Cria a página.
  const DensityPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Densidade';

  /// Rota nomeada.
  static const route = '/density';

  /// Chave do controle simulado de [density].
  static Key controlKey(GjaDensity density) =>
      ValueKey('density-control-${density.name}');

  /// Medidas de [tokens] no formato exibido na página.
  static String measures(GjaDensityTokens tokens) =>
      'controle ${tokens.controlHeight.toStringAsFixed(0)}'
      ' · item ${tokens.listItemHeight.toStringAsFixed(0)}'
      ' · alvo ${tokens.minTargetSize.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final colors = GjaThemeData.of(context).colors;
    final spacing = GjaThemeData.of(context).spacing;
    final typography = GjaThemeData.of(context).typography;

    return ColoredBox(
      color: colors.base,
      child: DefaultTextStyle(
        style: typography.base.copyWith(color: colors.text),
        child: ListView(
          padding: EdgeInsets.all(spacing.pageMargin),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Semantics(button: true, child: const Text('← Voltar')),
            ),
            SizedBox(height: spacing.stackGap),
            Text(title, style: typography.header2),
            SizedBox(height: spacing.sectionGap),
            Wrap(
              spacing: spacing.xl,
              runSpacing: spacing.xl,
              children: [
                for (final density in GjaDensity.values)
                  _DensityColumn(tokens: GjaDensityTokens.of(density)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DensityColumn extends StatelessWidget {
  const _DensityColumn({required this.tokens});

  final GjaDensityTokens tokens;

  @override
  Widget build(BuildContext context) {
    final colors = GjaThemeData.of(context).colors;
    final radius = GjaThemeData.of(context).radius;
    final typography = GjaThemeData.of(context).typography;
    final spacing = tokens.spacing;

    return Container(
      width: 320,
      padding: EdgeInsets.all(spacing.l),
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tokens.density.name, style: typography.header3),
          Text(
            DensityPage.measures(tokens),
            style: typography.small.copyWith(color: colors.label),
          ),
          SizedBox(height: spacing.stackGap),
          Container(
            key: DensityPage.controlKey(tokens.density),
            height: tokens.controlHeight,
            padding: EdgeInsets.symmetric(horizontal: spacing.m),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colors.base,
              border: Border.all(color: colors.fieldBorder),
              borderRadius: BorderRadius.circular(radius.button),
            ),
            child: Text('Campo', style: typography.base),
          ),
          SizedBox(height: spacing.stackGap),
          for (final item in ['Item 1', 'Item 2'])
            Container(
              height: tokens.listItemHeight,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.separator)),
              ),
              child: Text(item),
            ),
        ],
      ),
    );
  }
}
