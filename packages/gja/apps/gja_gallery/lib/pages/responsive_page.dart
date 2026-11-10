import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "Responsividade": classe da tela, classe de um painel estreito,
/// um valor responsivo de colunas e a densidade recomendada.
///
/// A classe da tela vem do `GjaScreenSizeScope` que a galeria coloca em
/// volta das rotas. As dimensões do painel e dos blocos são literais da
/// galeria.
class ResponsivePage extends StatelessWidget {
  /// Cria a página.
  const ResponsivePage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Responsividade';

  /// Rota nomeada.
  static const route = '/responsive';

  /// Chave do texto com a classe da tela.
  static const screenKey = Key('responsive-screen');

  /// Chave do texto com a classe do painel.
  static const panelKey = Key('responsive-panel');

  /// Colunas por classe de tamanho.
  static const columns = GjaResponsiveValue(
    small: 1,
    medium: 2,
    large: 3,
    extraLarge: 4,
  );

  @override
  Widget build(BuildContext context) {
    final theme = GjaTheme.of(context);
    final colors = theme.colors;
    final spacing = theme.spacing;
    final typography = theme.typography;
    final screen = GjaResponsive.screenSizeClassOf(context);
    final count = columns.resolve(screen);

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
            Text('Classe da tela: ${screen.name}', key: screenKey),
            SizedBox(height: spacing.xs),
            Text(
              'Densidade recomendada: '
              '${GjaResponsive.recommendedDensity().name}',
            ),
            SizedBox(height: spacing.sectionGap),
            Text('Colunas pela tela: $count', style: typography.header3),
            SizedBox(height: spacing.s),
            Row(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) SizedBox(width: spacing.s),
                  Expanded(
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      color: colors.selectionBackground,
                      child: Text('${i + 1}'),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            Text('Painel de 320', style: typography.header3),
            SizedBox(height: spacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 320,
                padding: EdgeInsets.all(spacing.m),
                decoration: BoxDecoration(
                  color: colors.headerBackground,
                  border: Border.all(color: colors.separator),
                ),
                child: GjaResponsiveBuilder(
                  builder: (context, sizeClass) => Text(
                    'Classe do painel: ${sizeClass.name} · colunas: '
                    '${columns.resolve(sizeClass)}',
                    key: panelKey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
