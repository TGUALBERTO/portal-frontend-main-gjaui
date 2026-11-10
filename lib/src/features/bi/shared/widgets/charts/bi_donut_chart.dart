import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../bi_format.dart';
import '../../bi_palette.dart';
import '../../models/ponto.dart';

/// Gráfico de rosca (Syncfusion) com legenda; texto opcional no centro.
class BiDonutChart extends StatelessWidget {
  const BiDonutChart({super.key, required this.fatias, this.centro});

  final List<Ponto> fatias;
  final String? centro;

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      margin: EdgeInsets.zero,
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.right,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: <CircularSeries<Ponto, String>>[
        DoughnutSeries<Ponto, String>(
          dataSource: fatias,
          xValueMapper: (p, _) => p.rotulo,
          yValueMapper: (p, _) => p.valor,
          pointColorMapper: (p, i) => BiPalette.serie(i),
          innerRadius: '64%',
          dataLabelMapper: (p, _) => BiFormat.contagem(p.valor),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
      annotations: centro == null
          ? const <CircularChartAnnotation>[]
          : <CircularChartAnnotation>[
              CircularChartAnnotation(
                widget: Text(
                  centro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
    );
  }
}
