import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../bi_format.dart';
import '../../bi_palette.dart';
import '../../models/ponto.dart';

/// Gráfico de barras (Syncfusion): colunas (vertical) por padrão ou barras
/// (horizontal). Uma série de [Ponto]. Eixo de valor opcionalmente em %.
class BiBarChart extends StatelessWidget {
  const BiBarChart({
    super.key,
    required this.dados,
    this.percentual = false,
    this.horizontal = false,
    this.colorirPorPonto = false,
  });

  final List<Ponto> dados;
  final bool percentual;
  final bool horizontal;

  /// Quando true, cada barra recebe uma cor da paleta (útil p/ categorias).
  final bool colorirPorPonto;

  /// Rótulo de cada barra em pt-BR: percentual com 2 casas (ex.: "84,73%") ou
  /// contagem (inteiro quando redondo, senão 2 casas).
  String _rotuloValor(Ponto p, int _) =>
      percentual ? BiFormat.pct(p.valor) : BiFormat.contagem(p.valor);

  @override
  Widget build(BuildContext context) {
    final valueFormat = percentual ? '{value}%' : null;
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      primaryXAxis: const CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
        labelIntersectAction: AxisLabelIntersectAction.wrap,
      ),
      primaryYAxis: NumericAxis(
        labelFormat: valueFormat,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<Ponto, String>>[
        if (horizontal)
          BarSeries<Ponto, String>(
            dataSource: dados,
            xValueMapper: (p, _) => p.rotulo,
            yValueMapper: (p, _) => p.valor,
            color: BiPalette.serie(0),
            pointColorMapper: colorirPorPonto ? (p, i) => BiPalette.serie(i) : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            dataLabelMapper: _rotuloValor,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          )
        else
          ColumnSeries<Ponto, String>(
            dataSource: dados,
            xValueMapper: (p, _) => p.rotulo,
            yValueMapper: (p, _) => p.valor,
            color: BiPalette.serie(0),
            pointColorMapper: colorirPorPonto ? (p, i) => BiPalette.serie(i) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            dataLabelMapper: _rotuloValor,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
      ],
    );
  }
}
