import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_faixa_list.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_heat_table.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/charts/bi_funnel_chart.dart';
import '../../../shared/widgets/charts/bi_line_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../../shared/widgets/ranking_list.dart';
import '../../data/models/sla_backlog_dashboard.dart';
import '../controllers/sla_backlog_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela única "SLA e Backlog" (`GET /dashboards/sla-backlog`, Grafico3.png).
/// A mesma resposta do BFF alimenta todos os painéis — evolução do SLA, SLA por
/// tipo e ofensores (SLA) junto do funil de aging, backlog por empresa e sem
/// movimentação (Backlog) — numa só tela, uma única chamada.
class SlaBacklogScreen extends StatefulWidget {
  const SlaBacklogScreen({super.key});

  @override
  State<SlaBacklogScreen> createState() => _SlaBacklogScreenState();
}

class _SlaBacklogScreenState extends State<SlaBacklogScreen> {
  late final SlaBacklogController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<SlaBacklogController>();
    _filtro = AppInjector.get<BiFilterController>();
    if (_controller.data.value == null) {
      _controller.load();
    } else {
      _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: SignalBuilder(builder: (context) {
          final data = _controller.data.value;
          final isLoading = _controller.isLoading.value;
          final error = _controller.error.value;

          if (isLoading && data == null) {
            return const AppLoading(message: 'Carregando dashboard…');
          }
          if (error != null && data == null) {
            return AppErrorWidget(
              title: 'Não foi possível carregar o dashboard',
              message: error.message,
              onRetry: _controller.load,
            );
          }

          return ListView(
            padding: EdgeInsets.all(AppSpacing.md),
            children: [
              const BiPageHeader(
                titulo: 'SLA e Backlog',
                subtitulo: 'Desempenho operacional e envelhecimento da fila',
              ),
              BiFilterBar(controller: _filtro, onApply: _controller.load),
              if (data == null)
                const AppEmptyState(
                  icon: GjaIcons.verified,
                  title: 'Sem dados',
                  subtitle: 'Nenhum dado para os filtros selecionados.',
                )
              else ...[
                KpiBanner(cards: data.cards),
                _Grade(data: data),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _Grade extends StatelessWidget {
  const _Grade({required this.data});

  final SlaBacklogDashboard data;

  static const double chartH = 300;

  @override
  Widget build(BuildContext context) {
    final panels = _panels();

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 700 ? 2 : 1);
      final gap = AppSpacing.md;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final p in panels) SizedBox(width: w, child: p),
        ],
      );
    });
  }

  /// Painéis combinados (SLA + Backlog e Aging) na ordem do Grafico3.png.
  List<Widget> _panels() => [
        BiPanel(
          numero: 1,
          titulo: 'Evolução Mensal do SLA',
          altura: chartH,
          child: BiLineChart(series: data.evolucaoSla, percentual: true),
        ),
        BiPanel(
          numero: 2,
          titulo: 'Backlog por Faixa de Aging',
          altura: chartH,
          child: BiFunnelChart(dados: data.backlogPorFaixaAging),
        ),
        BiPanel(
          numero: 3,
          titulo: 'SLA por Tipo de Chamado',
          altura: chartH,
          child: BiBarChart(
            dados: data.slaPorTipo,
            percentual: true,
            horizontal: true,
          ),
        ),
        BiPanel(
          numero: 4,
          titulo: 'Backlog por Empresa e Prioridade',
          child: BiHeatTable(
            colunas: const ['Empresa', 'Alta', 'Média', 'Baixa', 'Total'],
            linhas: [
              for (final l in data.backlogPorEmpresaPrioridade)
                BiHeatRow(l.empresa, [
                  BiCell(l.alta.toString()),
                  BiCell(l.media.toString()),
                  BiCell(l.baixa.toString()),
                  BiCell(l.total.toString()),
                ]),
            ],
          ),
        ),
        BiPanel(
          numero: 5,
          titulo: 'Principais Ofensores de SLA',
          child: RankingList(itens: data.ofensores),
        ),
        BiPanel(
          numero: 6,
          titulo: 'Chamados Sem Movimentação',
          child: BiFaixaList(itens: data.semMovimentacao),
        ),
        BiPanel(
          numero: 7,
          titulo: 'Plano de Ação Sugerido',
          child: InsightsList(insights: data.insights),
        ),
      ];
}
