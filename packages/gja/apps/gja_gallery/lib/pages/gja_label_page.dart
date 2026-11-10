import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaLabel": os desenhos `standard` e `bold`, os dois-pontos, o
/// obrigatório e um rótulo truncado.
class GjaLabelPage extends StatelessWidget {
  /// Cria a página.
  const GjaLabelPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaLabel';

  /// Rota nomeada.
  static const route = '/gja-label';

  /// Chave do rótulo `standard`.
  static const standardKey = Key('gja-label-standard');

  /// Chave do rótulo `bold`.
  static const boldKey = Key('gja-label-bold');

  /// Chave do rótulo com dois-pontos.
  static const colonKey = Key('gja-label-colon');

  /// Chave do rótulo obrigatório.
  static const requiredKey = Key('gja-label-required');

  /// Chave do rótulo truncado.
  static const truncatedKey = Key('gja-label-truncated');

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
          'Desenhos',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        const GjaLabel('Fornecedor', key: standardKey),
        const GjaLabel(
          'Fornecedor',
          key: boldKey,
          design: GjaLabelDesign.bold,
        ),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Dois-pontos e obrigatório',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        const GjaLabel('Centro de custo', key: colonKey, showColon: true),
        const GjaLabel(
          'Data de entrega',
          key: requiredKey,
          showColon: true,
          required: true,
        ),
        SizedBox(height: spacing.sectionGap),
        const GjaTitle(
          'Rótulo truncado',
          level: GjaTitleLevel.h2,
          titleStyle: GjaTitleLevel.h3,
        ),
        SizedBox(height: spacing.s),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 200,
            child: GjaLabel(
              'Fornecedor responsável pela entrega no depósito central',
              key: truncatedKey,
              showColon: true,
              required: true,
            ),
          ),
        ),
      ],
    );
  }
}
