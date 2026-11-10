import 'package:gjamobile/src/imports/imports.dart';

import '../bi_format.dart';
import '../bi_palette.dart';
import '../models/ranking_item.dart';

/// Ranking (ex.: "Sistemas mais ofensores"): posição, rótulo, valor e uma barra
/// proporcional ao percentual.
class RankingList extends StatelessWidget {
  const RankingList({super.key, required this.itens, this.sufixoValor = ''});

  final List<RankingItem> itens;

  /// Sufixo do valor exibido (ex.: "" para contagem).
  final String sufixoValor;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    if (itens.isEmpty) {
      return Text('Sem dados no período.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant));
    }
    return Column(
      children: [
        for (var i = 0; i < itens.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          _RankingRow(item: itens[i], cor: BiPalette.serie(i), sufixo: sufixoValor),
        ],
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.item, required this.cor, required this.sufixo});

  final RankingItem item;
  final Color cor;
  final String sufixo;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final valor = BiFormat.contagem(item.valor);
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text('${item.posicao}',
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.rotulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text('$valor$sufixo',
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              SizedBox(height: AppSpacing.xxs),
              ClipRRect(
                borderRadius: AppBorders.full,
                child: LinearProgressIndicator(
                  value: (item.percentual / 100).clamp(0, 1).toDouble(),
                  minHeight: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
