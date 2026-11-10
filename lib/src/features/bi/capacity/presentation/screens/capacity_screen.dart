import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../data/models/capacity_dashboard.dart';
import '../controllers/capacity_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Painel de Capacity (`/bi/capacity`). Renderiza só o que o BFF
/// `GET /dashboards/capacity` entrega (cards, horas por squad/colaborador, insights).
class CapacityScreen extends StatefulWidget {
  const CapacityScreen({super.key});

  @override
  State<CapacityScreen> createState() => _CapacityScreenState();
}

class _CapacityScreenState extends State<CapacityScreen> {
  late final CapacityController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<CapacityController>();
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
                titulo: 'Capacity',
                subtitulo: 'Capacidade e consumo de horas por squad e colaborador',
              ),
              BiFilterBar(
                controller: _filtro,
                onApply: _controller.load,
                mostrarSquad: true,
              ),
              if (data == null)
                const AppEmptyState(
                  icon: GjaIcons.performance,
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

  final CapacityDashboard data;

  @override
  Widget build(BuildContext context) {
    const chartH = 300.0;
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'Horas Consumidas por Squad',
        altura: chartH,
        child: BiBarChart(dados: data.horasPorSquad, colorirPorPonto: true),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Horas Consumidas por Colaborador',
        altura: chartH,
        child: BiBarChart(dados: data.horasPorTecnico, horizontal: true),
      ),
      BiPanel(
        numero: 3,
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
