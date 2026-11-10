import 'package:gjamobile/src/imports/imports.dart';

import '../models/kpi_card.dart';

/// Faixa escura de KPIs (assinatura visual dos dashboards, ver PNGs): fundo
/// navy fixo independente do tema, cartões com rótulo, valor grande e um traço
/// de acento na cor do tom. Vira carrossel horizontal em telas estreitas.
class KpiBanner extends StatelessWidget {
  const KpiBanner({super.key, required this.cards});

  final List<KpiCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        borderRadius: AppBorders.lg,
        gradient: LinearGradient(
          colors: [FioriColors.grey9, FioriColors.grey11],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 720) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: AppSpacing.sm),
                Expanded(child: _KpiTile(card: cards[i])),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: AppSpacing.sm),
                SizedBox(width: 150, child: _KpiTile(card: cards[i])),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.card});

  final KpiCard card;

  static Color _accent(String tom) => switch (tom) {
        'success' => FioriColors.green5,
        'warning' => FioriColors.mango5,
        'error' || 'critical' => FioriColors.red5,
        _ => FioriColors.blue5,
      };

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.rotulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelMedium?.copyWith(color: Colors.white70),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            card.valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: _accent(card.tom),
              borderRadius: AppBorders.full,
            ),
          ),
        ],
      ),
    );
  }
}
