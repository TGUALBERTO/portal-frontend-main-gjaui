import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/teamsbot/custos/data/models/custo.dart';
import 'package:gjamobile/src/features/teamsbot/custos/presentation/controllers/custos_controller.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — Relatório de custos de IA (`/teamsbot/custos`).
class CustosScreen extends StatefulWidget {
  const CustosScreen({super.key});

  @override
  State<CustosScreen> createState() => _CustosScreenState();
}

class _CustosScreenState extends State<CustosScreen> {
  late final CustosController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<CustosController>();
    if (_controller.relatorio.value == null) _controller.load();
  }

  Future<void> _pickPeriodo() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _controller.dataInicio.value != null &&
              _controller.dataFim.value != null
          ? DateTimeRange(
              start: _controller.dataInicio.value!,
              end: _controller.dataFim.value!)
          : null,
    );
    if (range != null) {
      _controller.aplicarPeriodo(inicio: range.start, fim: range.end);
    }
  }

  void _open(int ataId) =>
      context.push(AppRoutes.teamsbotAtaDetalhePath(ataId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de custos'),
        automaticallyImplyLeading: false,
      ),
      body: AppResponsiveContainer(
        child: RefreshIndicator(
          onRefresh: () => _controller.load(showLoading: false),
          child: SignalBuilder(builder: (context) {
            // Custos de IA são restritos a administradores (a aba some do menu,
            // mas a rota ainda pode ser acessada por URL direta).
            if (!AppInjector.get<AccessController>().isAdminSignal.value) {
              return const AppEmptyState(
                icon: GjaIcons.locked,
                title: 'Acesso restrito',
                subtitle:
                    'O relatório de custos está disponível apenas para administradores.',
              );
            }
            final relatorio = _controller.relatorio.value;
            final isLoading = _controller.isLoading.value;
            final error = _controller.error.value;
            final inicio = _controller.dataInicio.value;
            final fim = _controller.dataFim.value;

            if (isLoading && relatorio == null) {
              return const AppLoading(message: 'Carregando custos…');
            }
            if (error != null && relatorio == null) {
              return AppErrorWidget(
                title: 'Não foi possível carregar os custos',
                message: error.message,
                onRetry: _controller.load,
              );
            }
            return ListView(
              padding: EdgeInsets.all(AppSpacing.md),
              children: [
                _PeriodoBar(
                  inicio: inicio,
                  fim: fim,
                  onPick: _pickPeriodo,
                  onClear: () => _controller.aplicarPeriodo(),
                ),
                SizedBox(height: AppSpacing.md),
                if (relatorio != null) ...[
                  _Resumo(relatorio: relatorio),
                  SizedBox(height: AppSpacing.lg),
                  _SecaoTabela(
                      title: 'Custo por fase', linhas: relatorio.porFase),
                  SizedBox(height: AppSpacing.lg),
                  _SecaoTabela(
                      title: 'Custo por provedor',
                      linhas: relatorio.porProvedor),
                  SizedBox(height: AppSpacing.lg),
                  _PorAtaTabela(itens: relatorio.porAta, onOpen: _open),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _PeriodoBar extends StatelessWidget {
  const _PeriodoBar({
    required this.inicio,
    required this.fim,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? inicio;
  final DateTime? fim;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final temPeriodo = inicio != null && fim != null;
    final label = temPeriodo
        ? '${AtaFormat.data(inicio)} – ${AtaFormat.data(fim)}'
        : 'Todo o período';
    return Row(
      children: [
        const Icon(GjaIcons.calendar),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
        TextButton(onPressed: onPick, child: const Text('Selecionar período')),
        if (temPeriodo)
          TextButton(onPressed: onClear, child: const Text('Limpar')),
      ],
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.relatorio});
  final CustoRelatorio relatorio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ResumoCard(
            icon: GjaIcons.currency,
            label: 'Custo total (IA)',
            value: AtaFormat.custo(relatorio.totalUsd),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ResumoCard(
            icon: GjaIcons.moneyBills,
            label: 'Total de tokens',
            value: AtaFormat.inteiro(relatorio.totalTokens),
          ),
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 20.sp),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(label,
                    style:
                        tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(value,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Tabela de linhas agregadas com barra proporcional ao custo.
class _SecaoTabela extends StatelessWidget {
  const _SecaoTabela({required this.title, required this.linhas});
  final String title;
  final List<CustoLinha> linhas;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final maxCusto =
        linhas.fold<double>(0, (m, l) => l.custoUsd > m ? l.custoUsd : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: AppSpacing.sm),
        AppCard(
          child: linhas.isEmpty
              ? Text('Sem dados.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
              : Column(
                  children: [
                    for (final l in linhas) ...[
                      _LinhaCusto(linha: l, maxCusto: maxCusto),
                      if (l != linhas.last) const Divider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _LinhaCusto extends StatelessWidget {
  const _LinhaCusto({required this.linha, required this.maxCusto});
  final CustoLinha linha;
  final double maxCusto;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final fracao =
        maxCusto <= 0 ? 0.0 : (linha.custoUsd / maxCusto).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(linha.chave,
                    style:
                        tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(AtaFormat.custo(linha.custoUsd),
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          ClipRRect(
            borderRadius: AppBorders.full,
            child: LinearProgressIndicator(
              value: fracao,
              minHeight: 6.h,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            'in ${AtaFormat.inteiro(linha.inputTokens)} · out ${AtaFormat.inteiro(linha.outputTokens)} · cache ${AtaFormat.inteiro(linha.cacheTokens)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PorAtaTabela extends StatefulWidget {
  const _PorAtaTabela({required this.itens, required this.onOpen});
  final List<CustoPorAta> itens;
  final ValueChanged<int> onOpen;

  @override
  State<_PorAtaTabela> createState() => _PorAtaTabelaState();
}

class _PorAtaTabelaState extends State<_PorAtaTabela> {
  int _sortColumn = 2;
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final itens = [...widget.itens];
    itens.sort((a, b) {
      final cmp = switch (_sortColumn) {
        0 => a.assunto.toLowerCase().compareTo(b.assunto.toLowerCase()),
        1 => a.totalTokens.compareTo(b.totalTokens),
        _ => a.custoUsd.compareTo(b.custoUsd),
      };
      return _ascending ? cmp : -cmp;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Custo por ATA',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumn,
            sortAscending: _ascending,
            showCheckboxColumn: false,
            columns: [
              DataColumn(
                label: const Text('Assunto'),
                onSort: (i, asc) => setState(() {
                  _sortColumn = i;
                  _ascending = asc;
                }),
              ),
              DataColumn(
                label: const Text('Tokens'),
                numeric: true,
                onSort: (i, asc) => setState(() {
                  _sortColumn = i;
                  _ascending = asc;
                }),
              ),
              DataColumn(
                label: const Text('Custo'),
                numeric: true,
                onSort: (i, asc) => setState(() {
                  _sortColumn = i;
                  _ascending = asc;
                }),
              ),
            ],
            rows: [
              for (final a in itens)
                DataRow(
                  onSelectChanged: (_) => widget.onOpen(a.ataId),
                  cells: [
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(a.assunto, overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(Text(AtaFormat.inteiro(a.totalTokens))),
                    DataCell(Text(AtaFormat.custo(a.custoUsd))),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
