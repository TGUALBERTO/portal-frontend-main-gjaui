import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/charts/bi_bar_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../../shared/widgets/ranking_list.dart';
import '../../data/models/sap_dashboard.dart';
import '../controllers/sap_controller.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela única "Visão SAP e Multiplataforma"
/// (`GET /dashboards/sap-multiplataforma`, Grafico4.png). A mesma resposta do
/// BFF alimenta todos os painéis — chamados por módulo SAP e por sistema
/// multiplataforma, SLA por sistema, ofensores e riscos — numa só tela, uma
/// única chamada.
class SapScreen extends StatefulWidget {
  const SapScreen({super.key});

  @override
  State<SapScreen> createState() => _SapScreenState();
}

class _SapScreenState extends State<SapScreen> {
  late final SapController _controller;
  late final BiFilterController _filtro;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<SapController>();
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
                titulo: 'Visão SAP e Multiplataforma',
                subtitulo: 'Operação por módulos SAP, legados e integrações',
              ),
              BiFilterBar(controller: _filtro, onApply: _controller.load),
              if (data == null)
                const AppEmptyState(
                  icon: GjaIcons.widgets,
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

  final SapDashboard data;

  static const double chartH = 300;

  @override
  Widget build(BuildContext context) {
    // Painéis combinados (SAP + Multiplataforma) na ordem do Grafico4.png.
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'Chamados por Módulo SAP',
        altura: chartH,
        child: BiBarChart(dados: data.chamadosPorSistemaSap, colorirPorPonto: true),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Chamados por Sistemas Multiplataforma',
        altura: chartH,
        child: BiBarChart(
            dados: data.chamadosPorMultiplataforma, colorirPorPonto: true),
      ),
      BiPanel(
        numero: 3,
        titulo: 'SLA por Sistema',
        altura: chartH,
        child: BiBarChart(
          dados: data.slaPorSistema,
          percentual: true,
          horizontal: true,
        ),
      ),
      BiPanel(
        numero: 4,
        titulo: 'Top Ofensores Operacionais',
        child: RankingList(itens: data.ofensores),
      ),
      BiPanel(
        numero: 5,
        titulo: 'Riscos e Recomendações',
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
