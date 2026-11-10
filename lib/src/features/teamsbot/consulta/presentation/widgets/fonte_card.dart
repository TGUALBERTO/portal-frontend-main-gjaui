import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/consulta/data/models/fonte.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Card de uma fonte (trecho de ATA) citada numa resposta do RAG.
class FonteCard extends StatelessWidget {
  const FonteCard({super.key, required this.fonte, this.onTap});

  final Fonte fonte;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return AppCard(
      onTap: onTap,
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fonte.tituloReuniao,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(GjaIcons.popupWindow, size: 16.sp, color: cs.primary),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Icon(GjaIcons.appointment,
                  size: 14.sp, color: cs.onSurfaceVariant),
              SizedBox(width: AppSpacing.xs),
              Text(
                AtaFormat.dataIso(fonte.dataReuniao),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (fonte.secao.isNotEmpty) ...[
                Text('  •  ',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                Flexible(
                  child: Text(
                    fonte.secao,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: AppBorders.sm,
              border: Border(left: BorderSide(color: cs.primary, width: 3)),
            ),
            child: Text(
              fonte.trecho,
              style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppBorders.full,
                  child: LinearProgressIndicator(
                    value: fonte.score.clamp(0, 1).toDouble(),
                    minHeight: 6.h,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '${fonte.scorePercent}% de similaridade',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
