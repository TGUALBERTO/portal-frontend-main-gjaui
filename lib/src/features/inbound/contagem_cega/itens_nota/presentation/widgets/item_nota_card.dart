import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_kicker.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Card de um item da NF-e na lista de conferência.
///
/// Mostra os dois códigos do material (SAP e XML) porque eles quase nunca
/// coincidem — é o par que garante que a peça na mão é a peça da linha.
class ItemNotaCard extends StatelessWidget {
  const ItemNotaCard({
    super.key,
    required this.item,
    required this.bloqueado,
    this.onTap,
  });

  final ContagemItem item;

  /// A NF-e já foi condenada à devolução: este item não será mais contado.
  final bool bloqueado;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final contado = item.quantidadeContadaLabel;

    return Opacity(
      opacity: bloqueado ? 0.5 : 1,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.descricaoPrincipal,
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      ContagemCodigo(
                        'SAP ${item.materialSapLabel} · XML '
                        '${item.materialXml}',
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                ContagemTag.item(item.status, bloqueado: bloqueado),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xxs,
              children: [
                _Meta(rotulo: 'Lote NF', valor: item.loteNfLabel),
                _Meta(rotulo: 'Pedido', valor: item.pedidoCompleto),
              ],
            ),
            if (contado != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Contado: '),
                    TextSpan(
                      text: contado,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: ' · lote lido ${item.loteLidoLabel}'),
                  ],
                ),
                style: tt.bodySmall?.copyWith(
                  color: item.status == ContagemItemStatus.divergente
                      ? cs.error
                      : cs.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$rotulo: '),
          TextSpan(
            text: valor,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      style: context.textTheme.bodySmall
          ?.copyWith(color: context.colors.onSurfaceVariant),
    );
  }
}
