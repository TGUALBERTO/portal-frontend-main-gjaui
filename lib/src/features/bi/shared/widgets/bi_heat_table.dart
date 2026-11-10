import 'package:gjamobile/src/imports/imports.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Célula de uma [BiHeatRow]. Quando [heat] (0..100) não é nulo, a célula é
/// pintada num degradê semáforo (vermelho→amarelo→verde).
class BiCell {
  const BiCell(this.texto, {this.heat});
  final String texto;
  final double? heat;
}

/// Linha de [BiHeatTable]: rótulo + células (uma por coluna de dados).
class BiHeatRow {
  const BiHeatRow(this.rotulo, this.celulas);
  final String rotulo;
  final List<BiCell> celulas;
}

/// Tabela/heatmap (Syncfusion `SfDataGrid`): primeira coluna é o rótulo; as
/// demais são valores com fundo em cor de semáforo conforme o `heat`.
class BiHeatTable extends StatefulWidget {
  const BiHeatTable({
    super.key,
    required this.colunas,
    required this.linhas,
  });

  /// Cabeçalhos; o primeiro é a coluna de rótulo.
  final List<String> colunas;
  final List<BiHeatRow> linhas;

  @override
  State<BiHeatTable> createState() => _BiHeatTableState();
}

class _BiHeatTableState extends State<BiHeatTable> {
  late _HeatSource _source;

  @override
  void initState() {
    super.initState();
    _source = _HeatSource(widget.colunas, widget.linhas);
  }

  @override
  void didUpdateWidget(covariant BiHeatTable old) {
    super.didUpdateWidget(old);
    if (old.linhas != widget.linhas || old.colunas != widget.colunas) {
      _source = _HeatSource(widget.colunas, widget.linhas);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SfDataGridTheme(
      data: SfDataGridThemeData(
        headerColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        gridLineColor: cs.outlineVariant,
      ),
      child: SfDataGrid(
        source: _source,
        shrinkWrapRows: true,
        columnWidthMode: ColumnWidthMode.fill,
        gridLinesVisibility: GridLinesVisibility.horizontal,
        headerGridLinesVisibility: GridLinesVisibility.none,
        columns: [
          for (var i = 0; i < widget.colunas.length; i++)
            GridColumn(
              columnName: 'c$i',
              width: i == 0 ? 168 : double.nan,
              label: Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                alignment: i == 0 ? Alignment.centerLeft : Alignment.center,
                child: Text(
                  widget.colunas[i],
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeatSource extends DataGridSource {
  _HeatSource(this.colunas, this.linhas) {
    _rows = linhas.map((r) {
      final cells = <DataGridCell>[
        DataGridCell<String>(columnName: 'c0', value: r.rotulo),
        for (var i = 0; i < r.celulas.length; i++)
          DataGridCell<BiCell>(columnName: 'c${i + 1}', value: r.celulas[i]),
      ];
      return DataGridRow(cells: cells);
    }).toList();
  }

  final List<String> colunas;
  final List<BiHeatRow> linhas;
  late final List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  static Color? _heatColor(double? pct) {
    if (pct == null) return null;
    if (pct >= 90) return FioriColors.green6.withValues(alpha: 0.20);
    if (pct >= 80) return FioriColors.green5.withValues(alpha: 0.18);
    if (pct >= 70) return FioriColors.mango5.withValues(alpha: 0.20);
    if (pct >= 60) return FioriColors.mango6.withValues(alpha: 0.20);
    return FioriColors.red5.withValues(alpha: 0.20);
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final cells = row.getCells();
    return DataGridRowAdapter(
      cells: [
        for (var i = 0; i < cells.length; i++) _buildCell(cells[i], first: i == 0),
      ],
    );
  }

  Widget _buildCell(DataGridCell cell, {required bool first}) {
    final value = cell.value;
    if (value is BiCell) {
      return Container(
        alignment: Alignment.center,
        color: _heatColor(value.heat),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(value.texto, overflow: TextOverflow.ellipsis),
      );
    }
    return Container(
      alignment: first ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text('$value',
          overflow: TextOverflow.ellipsis,
          style: first ? const TextStyle(fontWeight: FontWeight.w600) : null),
    );
  }
}
