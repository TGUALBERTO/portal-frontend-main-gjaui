import 'package:gjamobile/src/imports/imports.dart';

import '../bi_format.dart';
import '../models/ponto.dart';

/// Lista simples "rótulo → valor" para faixas (ex.: "Chamados Sem Movimentação"
/// por faixa de inatividade). Renderiza exatamente o que o BFF entrega — sem
/// somar/derivar total no cliente (guardrail §27 do BI_GUIDE). Se o backend
/// mandar uma linha "Total", ela aparece como uma faixa qualquer.
class BiFaixaList extends StatelessWidget {
  const BiFaixaList({super.key, required this.itens, this.inteiro = true});

  final List<Ponto> itens;

  /// Quando true, formata o valor como inteiro com milhar; senão, com 1 casa.
  final bool inteiro;

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
          if (i > 0) Divider(height: AppSpacing.md, color: cs.outlineVariant),
          Row(
            children: [
              Expanded(
                child: Text(itens[i].rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                inteiro
                    ? BiFormat.inteiro(itens[i].valor)
                    : BiFormat.decimal(itens[i].valor),
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
