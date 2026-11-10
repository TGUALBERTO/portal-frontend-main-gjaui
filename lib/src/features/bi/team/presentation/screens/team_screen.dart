import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/bi_format.dart';
import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_heat_table.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../data/models/team_dashboard.dart';
import '../controllers/team_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Painel "Performance do Time" (`/bi/team`, ver Grafico5.png). Renderiza só o
/// que o BFF `GET /dashboards/team` entrega (cards, ocupação/horas por squad,
/// consolidado por squad, insights).
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final TeamController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<TeamController>();
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
                titulo: 'Performance do Time',
                subtitulo: 'Produtividade, capacity, qualidade e equilíbrio operacional',
              ),
              BiFilterBar(
                controller: _filtro,
                onApply: _controller.load,
                mostrarSquad: true,
              ),
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

  final TeamDashboard data;

  @override
  Widget build(BuildContext context) {
    const chartH = 280.0;
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'Ocupação por Squad',
        altura: chartH,
        child: BiBarChart(dados: data.ocupacaoPorSquad, percentual: true),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Distribuição de Horas por Squad',
        altura: chartH,
        child: BiBarChart(dados: data.horasPorSquad, colorirPorPonto: true),
      ),
      BiPanel(
        numero: 3,
        titulo: 'Visão Consolidada por Squad',
        child: BiHeatTable(
          colunas: const [
            'Squad',
            'Colaboradores',
            'Horas',
            'Ocupação',
            'SLA Médio',
          ],
          linhas: [
            for (final l in data.consolidadoPorSquad)
              BiHeatRow(l.squad, [
                BiCell(BiFormat.inteiro(l.colaboradores)),
                BiCell(BiFormat.decimal(l.horas)),
                BiCell(BiFormat.pct(l.ocupacao)),
                BiCell(BiFormat.pct(l.slaMedio), heat: l.slaMedio),
              ]),
          ],
        ),
      ),
      BiPanel(
        numero: 4,
        titulo: 'Direcionamentos do Gestor',
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
