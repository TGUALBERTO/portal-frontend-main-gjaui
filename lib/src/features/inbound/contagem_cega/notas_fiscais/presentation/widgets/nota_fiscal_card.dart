import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_kicker.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Card de uma NF-e na listagem do check-in: número, situação, fornecedor,
/// chave resumida e o avanço da conferência.
class NotaFiscalCard extends StatelessWidget {
  const NotaFiscalCard({super.key, required this.nota, this.onTap});

  final ContagemNotaFiscal nota;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NF-e ${nota.numero}',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              ContagemTag.nota(nota.status),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            nota.fornecedor,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: AppSpacing.sm),
          ContagemCodigo('Chave ${nota.chaveResumida}'),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppBorders.full,
                  child: LinearProgressIndicator(
                    value: nota.progresso,
                    minHeight: 5,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.ms),
              Text(
                '${nota.progressoLabel} itens',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
