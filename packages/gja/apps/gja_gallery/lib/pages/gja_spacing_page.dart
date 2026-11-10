import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaSpacing": cada passo e papel em escala, e o mesmo padding nas
/// densidades cozy e compacta.
///
/// Todo o espaço da página vem de `GjaSpacing`; a altura das barras é a do
/// passo `s`, e a largura, o próprio valor exibido.
class GjaSpacingPage extends StatelessWidget {
  /// Cria a página.
  const GjaSpacingPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaSpacing';

  /// Rota nomeada.
  static const route = '/gja-spacing';

  /// Chave da barra de [space].
  static Key barKey(GjaSpace space) =>
      ValueKey('gja-spacing-${space.name}');

  /// Chave do conteúdo do exemplo de padding na densidade [density].
  static Key paddedKey(GjaDensity density) =>
      ValueKey('gja-spacing-padded-${density.name}');

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GjaSpacing.padding(
          all: GjaSpace.pageMargin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Semantics(
                  button: true,
                  child: const GjaText('← Voltar'),
                ),
              ),
              const GjaSpacing.vertical(GjaSpace.stackGap),
              const GjaTitle(
                title,
                level: GjaTitleLevel.h1,
                titleStyle: GjaTitleLevel.h2,
              ),
              const GjaSpacing.vertical(GjaSpace.sectionGap),
              const GjaTitle(
                'Passos e papéis',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const GjaSpacing.vertical(GjaSpace.s),
              for (final space in GjaSpace.values) _Bar(space),
              const GjaSpacing.vertical(GjaSpace.sectionGap),
              const GjaTitle(
                'Densidades',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const GjaSpacing.vertical(GjaSpace.s),
              const Wrap(
                children: [
                  _PaddedSample(GjaDensity.cozy),
                  GjaSpacing.horizontal(GjaSpace.l),
                  GjaTheme.density(
                    density: GjaDensity.compact,
                    child: _PaddedSample(GjaDensity.compact),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra com a largura de [space], o nome e o valor.
class _Bar extends StatelessWidget {
  const _Bar(this.space);

  final GjaSpace space;

  @override
  Widget build(BuildContext context) {
    final theme = GjaTheme.of(context);
    final value = GjaSpacing.resolve(theme.spacing, space);
    return GjaSpacing.padding(
      bottom: GjaSpace.xs,
      child: Row(
        children: [
          SizedBox(
            width: theme.spacing.xxxl * 2,
            child: GjaLabel(space.name),
          ),
          ColoredBox(
            key: GjaSpacingPage.barKey(space),
            color: theme.colors.selectionBackground,
            child: SizedBox(width: value, height: theme.spacing.s),
          ),
          const GjaSpacing.horizontal(GjaSpace.s),
          GjaLabel(value.toStringAsFixed(0)),
        ],
      ),
    );
  }
}

/// Cartão com padding `l` em volta de um texto, na densidade ativa.
class _PaddedSample extends StatelessWidget {
  const _PaddedSample(this.density);

  final GjaDensity density;

  @override
  Widget build(BuildContext context) {
    final colors = GjaTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.headerBackground,
        border: Border.all(color: colors.separator),
      ),
      child: GjaSpacing.padding(
        all: GjaSpace.l,
        child: GjaText(
          density.name,
          key: GjaSpacingPage.paddedKey(density),
        ),
      ),
    );
  }
}
