import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaText": um parágrafo livre, o mesmo truncado em duas linhas e
/// em uma linha sem quebra.
class GjaTextPage extends StatelessWidget {
  /// Cria a página.
  const GjaTextPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaText';

  /// Rota nomeada.
  static const route = '/gja-text';

  /// Texto longo dos exemplos.
  static const longText =
      'O pedido de compra 4711 aguarda aprovação do centro de custo antes de '
      'ser enviado ao fornecedor, e a entrega prevista depende da confirmação '
      'do estoque no depósito central.';

  /// Chave do exemplo livre.
  static const freeKey = Key('gja-text-free');

  /// Chave do exemplo truncado em duas linhas.
  static const truncatedKey = Key('gja-text-truncated');

  /// Chave do exemplo sem quebra.
  static const noWrapKey = Key('gja-text-no-wrap');

  @override
  Widget build(BuildContext context) {
    final spacing = GjaTheme.of(context).spacing;
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
        for (final (heading, example) in const [
          ('Texto livre', GjaText(longText, key: freeKey)),
          (
            'Limite de duas linhas',
            GjaText(longText, key: truncatedKey, maxLines: 2),
          ),
          ('Sem quebra', GjaText(longText, key: noWrapKey, wrapping: false)),
        ]) ...[
          GjaTitle(
            heading,
            level: GjaTitleLevel.h2,
            titleStyle: GjaTitleLevel.h3,
          ),
          SizedBox(height: spacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(width: 320, child: example),
          ),
          SizedBox(height: spacing.sectionGap),
        ],
      ],
    );
  }
}
