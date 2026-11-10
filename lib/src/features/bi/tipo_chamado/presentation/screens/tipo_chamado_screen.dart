import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/charts/bi_donut_chart.dart';
import '../../../shared/widgets/charts/bi_line_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../data/models/tipo_chamado_dashboard.dart';
import '../../data/repositories/tipo_chamado_repository.dart';
import '../controllers/tipo_chamado_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Painel genérico por tipo de chamado — usado por Incidentes
/// (`/dashboards/incidents`), Requisições (`/dashboards/requests`) e Mudanças/GMUD
/// (`/dashboards/change`), que compartilham o mesmo contrato. Screen-scoped: cria
/// seu controller com o [path] da tela.
class TipoChamadoScreen extends StatefulWidget {
  const TipoChamadoScreen({
    super.key,
    required this.path,
    required this.titulo,
    required this.subtitulo,
    this.icon = GjaIcons.task,
  });

  final String path;
  final String titulo;
  final String subtitulo;
  final IconData icon;

  @override
  State<TipoChamadoScreen> createState() => _TipoChamadoScreenState();
}

class _TipoChamadoScreenState extends State<TipoChamadoScreen> {
  late final TipoChamadoController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _filtro = AppInjector.get<BiFilterController>();
    _controller = TipoChamadoController(
      repository: AppInjector.get<TipoChamadoRepository>(),
      filtro: _filtro,
      path: widget.path,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              BiPageHeader(titulo: widget.titulo, subtitulo: widget.subtitulo),
              BiFilterBar(controller: _filtro, onApply: _controller.load),
              if (data == null)
                AppEmptyState(
                  icon: widget.icon,
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

  final TipoChamadoDashboard data;

  @override
  Widget build(BuildContext context) {
    const chartH = 280.0;
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'Tendência Mensal',
        altura: chartH,
        child: BiLineChart(series: data.tendencia),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Volume por Empresa',
        altura: chartH,
        child: BiBarChart(dados: data.porEmpresa, colorirPorPonto: true),
      ),
      BiPanel(
        numero: 3,
        titulo: 'Distribuição por Prioridade',
        altura: chartH,
        child: BiDonutChart(fatias: data.porPrioridade),
      ),
      BiPanel(
        numero: 4,
        titulo: 'Recomendações',
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
