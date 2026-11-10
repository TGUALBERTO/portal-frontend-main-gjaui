import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaTitle": os sete estilos, um título de nível H1 com estilo H5
/// e os títulos truncado e com quebra.
class GjaTitlePage extends StatelessWidget {
  /// Cria a página.
  const GjaTitlePage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaTitle';

  /// Rota nomeada.
  static const route = '/gja-title';

  /// Título longo dos exemplos de quebra.
  static const longTitle =
      'Pedidos de compra em aberto aguardando aprovação do centro de custo';

  /// Chave do exemplo de nível diferente do estilo.
  static const levelKey = Key('gja-title-level');

  /// Chave do exemplo truncado.
  static const truncatedKey = Key('gja-title-truncated');

  /// Chave do exemplo com quebra.
  static const wrappingKey = Key('gja-title-wrapping');

  /// Texto do exemplo de cada estilo.
  static String styleLabel(GjaTitleLevel style) => 'Estilo ${style.name}';

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
        const GjaTitle(
          'Estilos',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        for (final style in GjaTitleLevel.values)
          GjaTitle(styleLabel(style), titleStyle: style),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Nível diferente do estilo',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        const GjaTitle(
          'Nível H1 com estilo H5',
          key: levelKey,
          level: GjaTitleLevel.h1,
          titleStyle: GjaTitleLevel.h5,
        ),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Quebra de linhas',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 240,
            child: GjaTitle(longTitle, key: truncatedKey),
          ),
        ),
        SizedBox(height: spacing.s),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 240,
            child: GjaTitle(longTitle, key: wrappingKey, wrapping: true),
          ),
        ),
      ],
    );
  }
}
