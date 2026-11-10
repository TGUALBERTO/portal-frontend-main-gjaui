import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Ficha de identificação do item em contagem.
///
/// Traz descrição do SAP e do XML lado a lado, mais os quatro campos que o
/// conferente cruza com a etiqueta do volume. **Não** mostra a quantidade da
/// NF — é isso que faz a contagem ser cega.
class IdentificacaoItemCard extends StatelessWidget {
  const IdentificacaoItemCard({super.key, required this.item});

  final ContagemItem item;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.descricaoPrincipal,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          // A descrição do fornecedor só entra quando difere da de cima. Quando
          // o SAP não tem nome para o item, a de cima JÁ é a do XML — e a mesma
          // frase duas vezes só empurra o resto do card para fora da tela do
          // coletor.
          if (item.descricaoSecundaria case final descricaoXml?) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              descricaoXml,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Campo(
                  rotulo: 'Material SAP',
                  valor: item.materialSapLabel,
                ),
              ),
              Expanded(
                child: _Campo(rotulo: 'Cód. XML', valor: item.materialXml),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Campo(rotulo: 'Pedido', valor: item.pedidoCompleto),
              ),
              Expanded(
                child: _Campo(rotulo: 'Unidade', valor: item.unidade),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$rotulo '),
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
