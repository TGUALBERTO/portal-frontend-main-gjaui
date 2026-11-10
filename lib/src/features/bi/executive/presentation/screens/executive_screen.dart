import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/bi_format.dart';
import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_heat_table.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/charts/bi_donut_chart.dart';
import '../../../shared/widgets/charts/bi_line_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../../shared/widgets/ranking_list.dart';
import '../../data/models/executive_dashboard.dart';
import '../controllers/executive_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Cockpit Executivo ITSM (`/bi/executive`, ver Grafico1.png).
class ExecutiveScreen extends StatefulWidget {
  const ExecutiveScreen({super.key});

  @override
  State<ExecutiveScreen> createState() => _ExecutiveScreenState();
}

class _ExecutiveScreenState extends State<ExecutiveScreen> {
  late final ExecutiveController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<ExecutiveController>();
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
                titulo: 'Cockpit Executivo ITSM',
                subtitulo: 'AMS SAP e Multiplataforma',
              ),
              BiFilterBar(controller: _filtro, onApply: _controller.load),
              if (data == null)
                const AppEmptyState(
                  icon: GjaIcons.trendUp,
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

  final ExecutiveDashboard data;

  @override
  Widget build(BuildContext context) {
    const chartH = 280.0;
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'Tendência Mensal de Chamados',
        altura: chartH,
        child: BiLineChart(series: data.tendencia),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Volume por Empresa',
        altura: chartH,
        child: BiBarChart(dados: data.volumePorEmpresa, colorirPorPonto: true),
      ),
      BiPanel(
        numero: 3,
        titulo: 'Distribuição por Tipo de Demanda',
        altura: chartH,
        child: BiDonutChart(fatias: data.tiposDemanda),
      ),
      BiPanel(
        numero: 4,
        titulo: 'SLA por Empresa',
        child: BiHeatTable(
          colunas: const ['Empresa', 'SLA Geral', 'Incidentes', 'Requisições'],
          linhas: [
            for (final l in data.slaPorEmpresa)
              BiHeatRow(l.empresa, [
                BiCell(_pct(l.slaGeral), heat: l.slaGeral),
                BiCell(_pct(l.slaIncidentes), heat: l.slaIncidentes),
                BiCell(_pct(l.slaRequisicoes), heat: l.slaRequisicoes),
              ]),
          ],
        ),
      ),
      BiPanel(
        numero: 5,
        titulo: 'Sistemas Mais Ofensores',
        child: RankingList(itens: data.ofensores),
      ),
      BiPanel(
        numero: 6,
        titulo: 'Recomendações Executivas',
        child: InsightsList(insights: data.insights),
      ),
    ];

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

  static String _pct(double v) => BiFormat.pct(v);
}
