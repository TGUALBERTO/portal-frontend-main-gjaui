import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaContainer": superfícies, raios, sombras e um cartão de
/// exemplo.
///
/// A página fica sobre `background`, para que as superfícies `base` e as
/// sombras apareçam. Todo o layout usa `GjaSpacing` e `GjaText`.
class GjaContainerPage extends StatelessWidget {
  /// Cria a página.
  const GjaContainerPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaContainer';

  /// Rota nomeada.
  static const route = '/gja-container';

  /// Chave do cartão de exemplo.
  static const cardKey = Key('gja-container-card');

  @override
  Widget build(BuildContext context) {
    Widget sample(String label, GjaContainer box) => GjaSpacing.padding(
      end: GjaSpace.l,
      bottom: GjaSpace.l,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          box,
          const GjaSpacing.vertical(GjaSpace.xs),
          GjaLabel(label),
        ],
      ),
    );

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
                'Superfícies',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const GjaSpacing.vertical(GjaSpace.s),
              Wrap(
                children: [
                  for (final surface in GjaSurface.values)
                    sample(
                      surface.name,
                      GjaContainer(
                        surface: surface,
                        border: true,
                        padding: GjaSpace.xl,
                      ),
                    ),
                ],
              ),
              const GjaSpacing.vertical(GjaSpace.sectionGap),
              const GjaTitle(
                'Raios',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const GjaSpacing.vertical(GjaSpace.s),
              Wrap(
                children: [
                  for (final radius in GjaRadius.values)
                    sample(
                      radius.name,
                      GjaContainer(
                        surface: GjaSurface.base,
                        border: true,
                        radius: radius,
                        padding: GjaSpace.xl,
                      ),
                    ),
                ],
              ),
              const GjaSpacing.vertical(GjaSpace.sectionGap),
              const GjaTitle(
                'Sombras',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const GjaSpacing.vertical(GjaSpace.s),
              Wrap(
                children: [
                  for (final shadow in GjaShadow.values)
                    sample(
                      shadow.name,
                      GjaContainer(
                        surface: GjaSurface.base,
                        radius: GjaRadius.tile,
                        shadow: shadow,
                        padding: GjaSpace.xl,
                      ),
                    ),
                ],
              ),
              const GjaSpacing.vertical(GjaSpace.sectionGap),
              const GjaTitle(
                'Cartão',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const GjaSpacing.vertical(GjaSpace.s),
              const Align(
                alignment: Alignment.centerLeft,
                child: GjaContainer(
                  key: cardKey,
                  surface: GjaSurface.base,
                  border: true,
                  radius: GjaRadius.tile,
                  shadow: GjaShadow.card,
                  padding: GjaSpace.l,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GjaTitle(
                        'Pedido 4711',
                        level: GjaTitleLevel.h2,
                        titleStyle: GjaTitleLevel.h3,
                      ),
                      GjaSpacing.vertical(GjaSpace.xs),
                      GjaLabel('Aguardando aprovação'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
