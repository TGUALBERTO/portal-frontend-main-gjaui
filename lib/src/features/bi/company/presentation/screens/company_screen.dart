import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/bi_format.dart';
import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_heat_table.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/charts/bi_line_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../data/models/company_dashboard.dart';
import '../controllers/company_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Painel Comparativo por Empresa (`/bi/company`, ver Grafico2.png). Renderiza só
/// o que o BFF `GET /dashboards/company` entrega (cards, comparativo, volume,
/// evolução do SLA e insights); painéis do PNG sem fonte no contrato ficam de fora.
class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  late final CompanyController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<CompanyController>();
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
                titulo: 'Painel Comparativo por Empresa',
                subtitulo: 'Análise consolidada e segregada das operações',
              ),
              BiFilterBar(controller: _filtro, onApply: _controller.load),
              if (data == null)
                const AppEmptyState(
                  icon: GjaIcons.verticalBarChart,
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

  final CompanyDashboard data;

  @override
  Widget build(BuildContext context) {
    const chartH = 280.0;
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'Comparativo de Indicadores por Empresa',
        child: BiHeatTable(
          colunas: const [
            'Empresa',
            'Chamados',
            'SLA Médio',
            'Backlog',
            'Aging Médio',
            'SEV1',
          ],
          linhas: [
            for (final l in data.comparativo)
              BiHeatRow(l.empresa, [
                BiCell(BiFormat.inteiro(l.chamados)),
                BiCell(BiFormat.pct(l.slaMedio), heat: l.slaMedio),
                BiCell(BiFormat.inteiro(l.backlog)),
                BiCell(BiFormat.dias(l.agingMedio)),
                BiCell(BiFormat.inteiro(l.incidentesSev1)),
              ]),
          ],
        ),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Volume de Chamados por Empresa',
        altura: chartH,
        child: BiBarChart(dados: data.volumePorEmpresa, colorirPorPonto: true),
      ),
      BiPanel(
        numero: 3,
        titulo: 'Evolução do SLA por Empresa',
        altura: chartH,
        child: BiLineChart(series: data.evolucaoSla, percentual: true),
      ),
      BiPanel(
        numero: 4,
        titulo: 'Insights Gerenciais',
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
}
