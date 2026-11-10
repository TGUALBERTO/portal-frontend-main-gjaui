import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/charts/bi_funnel_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../data/models/quality_dashboard.dart';
import '../controllers/quality_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Painel de Qualidade (`/bi/quality`). Renderiza só o que o BFF
/// `GET /dashboards/quality` entrega (cards, SLA por tipo, backlog por aging,
/// insights). Reabertura/satisfação não existem no espelho e ficam de fora.
class QualityScreen extends StatefulWidget {
  const QualityScreen({super.key});

  @override
  State<QualityScreen> createState() => _QualityScreenState();
}

class _QualityScreenState extends State<QualityScreen> {
  late final QualityController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<QualityController>();
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
                titulo: 'Qualidade',
                subtitulo: 'Indicadores de qualidade operacional (SLA, aging, inatividade)',
              ),
              BiFilterBar(controller: _filtro, onApply: _controller.load),
              if (data == null)
                const AppEmptyState(
                  icon: GjaIcons.checklist,
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

  final QualityDashboard data;

  @override
  Widget build(BuildContext context) {
    const chartH = 300.0;
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'SLA por Tipo de Chamado',
        altura: chartH,
        child: BiBarChart(
          dados: data.slaPorTipo,
          percentual: true,
          horizontal: true,
        ),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Backlog por Faixa de Aging',
        altura: chartH,
        child: BiFunnelChart(dados: data.backlogPorFaixaAging),
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
