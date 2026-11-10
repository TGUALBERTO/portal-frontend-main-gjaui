import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../bi_palette.dart';
import '../../models/ponto.dart';

/// Funil (Syncfusion `SfFunnelChart`) para faixas ordenadas do melhor ao pior —
/// ex.: "Backlog por Faixa de Aging" (0–7 → >60 dias). Cores em rampa semáforo
/// (verde→vermelho) conforme a posição da faixa.
class BiFunnelChart extends StatelessWidget {
  const BiFunnelChart({super.key, required this.dados});

  final List<Ponto> dados;

  @override
  Widget build(BuildContext context) {
    final n = dados.length;
    return SfFunnelChart(
      margin: EdgeInsets.zero,
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: FunnelSeries<Ponto, String>(
        dataSource: dados,
        xValueMapper: (p, _) => p.rotulo,
        yValueMapper: (p, _) => p.valor,
        pointColorMapper: (p, i) => BiPalette.aging(i, n),
        dataLabelSettings: const DataLabelSettings(
          isVisible: true,
          labelPosition: ChartDataLabelPosition.inside,
          textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
