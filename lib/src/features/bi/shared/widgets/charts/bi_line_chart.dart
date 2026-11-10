import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../bi_palette.dart';
import '../../models/ponto.dart';
import '../../models/serie.dart';

/// Gráfico de linhas (Syncfusion) com 1..n séries. Eixo Y opcionalmente em %.
class BiLineChart extends StatelessWidget {
  const BiLineChart({super.key, required this.series, this.percentual = false});

  final List<Serie> series;
  final bool percentual;

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      legend: Legend(
        isVisible: series.length > 1,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      primaryXAxis: const CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelFormat: percentual ? '{value}%' : null,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<Ponto, String>>[
        for (var i = 0; i < series.length; i++)
          LineSeries<Ponto, String>(
            name: series[i].nome,
            dataSource: series[i].pontos,
            xValueMapper: (p, _) => p.rotulo,
            yValueMapper: (p, _) => p.valor,
            color: BiPalette.serie(i),
            width: 2.5,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
      ],
    );
  }
}
