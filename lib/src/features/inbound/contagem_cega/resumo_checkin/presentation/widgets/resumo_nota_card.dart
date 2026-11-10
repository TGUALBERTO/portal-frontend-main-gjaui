import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Linha do resumo: o desfecho de uma NF-e e, quando houver, quais itens a
/// condenaram — é o que o conferente lê para o motorista antes de devolver.
class ResumoNotaCard extends StatelessWidget {
  const ResumoNotaCard({super.key, required this.nota});

  final ContagemNotaFiscal nota;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
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
              ContagemTag.nota(nota.status, resumo: true),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            '${nota.fornecedor} · ${nota.progressoLabel} itens conferidos',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          for (final item in nota.itensDivergentes) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(GjaIcons.decline, size: 14, color: cs.error),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${item.descricaoPrincipal} · lote NF '
                    '${item.loteNf.isEmpty ? 's/ lote' : item.loteNf}',
                    style: tt.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
