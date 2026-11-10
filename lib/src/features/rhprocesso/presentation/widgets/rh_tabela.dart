import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Coluna de [RhTabela]. [numerica] alinha à direita (valores e quantidades).
class RhColuna {
  const RhColuna(this.titulo, {this.numerica = false});

  final String titulo;
  final bool numerica;
}

/// Tabela paginada das telas do RH Processo.
///
/// Paginada porque o detalhe de um supervisor passa de milhares de linhas: só
/// as linhas da página visível são montadas. Diferente da `PaginatedDataTable`,
/// a última página tem só as linhas que existem (sem linhas vazias de
/// preenchimento) e a paginação pode aparecer também acima da tabela.
class RhTabela<T> extends StatefulWidget {
  const RhTabela({
    super.key,
    required this.colunas,
    required this.itens,
    required this.celulas,
    this.titulo,
    this.acoes,
    this.linhasPorPagina = 20,
    this.paginacaoNoTopo = false,
  });

  final List<RhColuna> colunas;
  final List<T> itens;

  /// Uma célula por coluna, na mesma ordem de [colunas].
  final List<Widget> Function(T item) celulas;
  final String? titulo;

  /// Ações no cabeçalho da tabela (ex.: busca).
  final List<Widget>? acoes;
  final int linhasPorPagina;

  /// Repete a paginação acima da tabela (listas longas).
  final bool paginacaoNoTopo;

  @override
  State<RhTabela<T>> createState() => _RhTabelaState<T>();
}

class _RhTabelaState<T> extends State<RhTabela<T>> {
  int _pagina = 0;

  int get _total => widget.itens.length;
  int get _paginas =>
      _total == 0 ? 1 : (_total + widget.linhasPorPagina - 1) ~/ widget.linhasPorPagina;

  @override
  void didUpdateWidget(covariant RhTabela<T> antigo) {
    super.didUpdateWidget(antigo);
    // Lista de outro tamanho (nova consulta, busca): volta para a primeira
    // página. Mesmo tamanho (ex.: uma rota editada) mantém a página.
    if (antigo.itens.length != widget.itens.length) _pagina = 0;
    if (_pagina >= _paginas) _pagina = _paginas - 1;
  }

  void _irPara(int pagina) => setState(() => _pagina = pagina.clamp(0, _paginas - 1));

  @override
  Widget build(BuildContext context) {
    final inicio = _pagina * widget.linhasPorPagina;
    final fim = (inicio + widget.linhasPorPagina).clamp(0, _total);
    final pagina = widget.itens.sublist(inicio, fim);
    final paginada = _total > widget.linhasPorPagina;
    final barra = _BarraPaginacao(
      inicio: inicio,
      fim: fim,
      total: _total,
      pagina: _pagina,
      paginas: _paginas,
      irPara: _irPara,
    );
    final temCabecalho = widget.titulo != null || (widget.acoes?.isNotEmpty ?? false);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (temCabecalho)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: widget.titulo == null
                        ? const SizedBox.shrink()
                        : Text(widget.titulo!, style: context.textTheme.titleMedium),
                  ),
                  ...?widget.acoes,
                ],
              ),
            ),
          if (paginada && widget.paginacaoNoTopo) ...[
            barra,
            const Divider(height: 1),
          ],
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: AppSpacing.lg,
                  horizontalMargin: AppSpacing.md,
                  columns: [
                    for (final c in widget.colunas)
                      DataColumn(label: Text(c.titulo), numeric: c.numerica),
                  ],
                  rows: [
                    for (final item in pagina)
                      DataRow(cells: [
                        for (final w in widget.celulas(item)) DataCell(w),
                      ]),
                  ],
                ),
              ),
            ),
          ),
          if (paginada) ...[
            const Divider(height: 1),
            barra,
          ],
        ],
      ),
    );
  }
}

/// "1 – 20 de 311" com primeira, anterior, próxima e última página.
class _BarraPaginacao extends StatelessWidget {
  const _BarraPaginacao({
    required this.inicio,
    required this.fim,
    required this.total,
    required this.pagina,
    required this.paginas,
    required this.irPara,
  });

  final int inicio;
  final int fim;
  final int total;
  final int pagina;
  final int paginas;
  final ValueChanged<int> irPara;

  @override
  Widget build(BuildContext context) {
    final primeira = pagina == 0;
    final ultima = pagina >= paginas - 1;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.xs,
        children: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Text('${inicio + 1} – $fim de $total', style: context.textTheme.bodySmall),
          ),
          IconButton(
            tooltip: 'Primeira página',
            icon: const Icon(GjaIcons.sysFirstPage),
            onPressed: primeira ? null : () => irPara(0),
          ),
          IconButton(
            tooltip: 'Página anterior',
            icon: const Icon(GjaIcons.slimArrowLeft),
            onPressed: primeira ? null : () => irPara(pagina - 1),
          ),
          IconButton(
            tooltip: 'Próxima página',
            icon: const Icon(GjaIcons.slimArrowRight),
            onPressed: ultima ? null : () => irPara(pagina + 1),
          ),
          IconButton(
            tooltip: 'Última página',
            icon: const Icon(GjaIcons.sysLastPage),
            onPressed: ultima ? null : () => irPara(paginas - 1),
          ),
        ],
      ),
    );
  }
}
