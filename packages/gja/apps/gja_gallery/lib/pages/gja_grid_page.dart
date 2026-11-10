import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaGrid": cartões no `defaultSpan` padrão, pela classe da tela,
/// e uma grade com um item de destaque em `GjaGridData`.
class GjaGridPage extends StatelessWidget {
  /// Cria a página.
  const GjaGridPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaGrid';

  /// Rota nomeada.
  static const route = '/gja-grid';

  /// Chave do cartão de índice [index] da primeira grade.
  static Key cardKey(int index) => ValueKey('grid-card-$index');

  /// Chave da célula de destaque.
  static const highlightKey = Key('grid-highlight');

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GjaSpacing.padding(
          all: GjaSpace.pageMargin,
          child: GjaVBox(
            gap: GjaSpace.l,
            items: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Semantics(
                  button: true,
                  child: const GjaText('← Voltar'),
                ),
              ),
              const GjaTitle(
                title,
                level: GjaTitleLevel.h1,
                titleStyle: GjaTitleLevel.h2,
              ),
              const GjaTitle(
                'Span padrão XL3 L3 M6 S12 (1, 2, 4 e 4 por linha), pela tela',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              GjaGrid(
                content: [
                  for (var i = 0; i < 6; i++)
                    _Card(key: cardKey(i), label: 'Pedido ${4711 + i}'),
                ],
              ),
              const GjaTitle(
                'Item de destaque com GjaGridData (small 12, large 6)',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const GjaGrid(
                content: [
                  GjaGridData(
                    span: GjaResponsiveValue(small: 12, large: 6),
                    child: _Card(key: highlightKey, label: 'Resumo do mês'),
                  ),
                  _Card(label: 'Atalhos'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cartão de exemplo.
class _Card extends StatelessWidget {
  const _Card({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GjaContainer(
      surface: GjaSurface.base,
      border: true,
      radius: GjaRadius.tile,
      shadow: GjaShadow.card,
      padding: GjaSpace.l,
      child: GjaVBox(
        gap: GjaSpace.xs,
        items: [
          GjaTitle(
            label,
            level: GjaTitleLevel.h3,
            titleStyle: GjaTitleLevel.h4,
          ),
          const GjaLabel('Aguardando aprovação'),
        ],
      ),
    );
  }
}
