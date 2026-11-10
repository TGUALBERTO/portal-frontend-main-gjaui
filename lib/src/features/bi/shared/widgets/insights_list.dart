import 'package:gjamobile/src/imports/imports.dart';

import '../bi_palette.dart';
import '../models/insight.dart';

/// Lista de recomendações/insights com ícone por severidade.
class InsightsList extends StatelessWidget {
  const InsightsList({super.key, required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    if (insights.isEmpty) {
      return Text('Sem recomendações no período.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < insights.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          _InsightTile(insight: insights[i]),
        ],
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final cor = BiPalette.severidade(context, insight.severidade);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(BiPalette.severidadeIcon(insight.severidade), size: 18, color: cor),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.titulo,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (insight.descricao.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xxs),
                Text(insight.descricao,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
