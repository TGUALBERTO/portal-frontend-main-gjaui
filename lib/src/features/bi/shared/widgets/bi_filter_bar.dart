import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:intl/intl.dart';

import '../controllers/bi_filter_controller.dart';
import '../controllers/filtros_reference_controller.dart';
import '../models/models.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Barra de filtros do BI: **Período** (calendário `flutter_date_pickers`),
/// **Empresa** (todos os dashboards, filtra pelo NOME normalizado — um rótulo
/// cobre todos os `entidade_id` iguais) e **Squad** (só onde o backend filtra por
/// grupo — Time/Capacity, via [mostrarSquad]), além de **Limpar filtros**.
///
/// Opções vêm de `GET /dashboards/filtros` (dados de referência, app-scoped).
/// Sem opções (carregando/erro), o seletor simplesmente não aparece.
class BiFilterBar extends StatefulWidget {
  const BiFilterBar({
    super.key,
    required this.controller,
    required this.onApply,
    this.mostrarSquad = false,
  });

  final BiFilterController controller;
  final VoidCallback onApply;

  /// Exibe o seletor de Squad. Só faz sentido nos dashboards de tarefa
  /// (Time/Capacity), onde o backend aplica `grupo` (grupo_tecnico_id).
  final bool mostrarSquad;

  @override
  State<BiFilterBar> createState() => _BiFilterBarState();
}

class _BiFilterBarState extends State<BiFilterBar> {
  static final _fmt = DateFormat('dd/MM/yy');

  late final FiltrosReferenceController _ref;

  BiFilterController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _ref = AppInjector.get<FiltrosReferenceController>();
    _ref.load();
  }

  Future<void> _pickPeriodo(DashboardFilter f) async {
    final confirmado = await pickDatePeriod(
      context,
      inicio: f.inicio,
      fim: f.fim,
    );
    if (confirmado != null) {
      _controller.aplicar(
          f.copyWith(inicio: confirmado.start, fim: confirmado.end));
      widget.onApply();
    }
  }

  void _selecionarEmpresa(DashboardFilter f, String nome) {
    _controller.aplicar(nome.isEmpty
        ? f.copyWith(limparEmpresa: true)
        : f.copyWith(empresaNome: nome));
    widget.onApply();
  }

  void _selecionarSquad(DashboardFilter f, int id) {
    _controller.aplicar(
        id <= 0 ? f.copyWith(limparGrupo: true) : f.copyWith(grupo: id));
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final f = _controller.filtro.value;
      final empresas = _ref.empresas.value;
      final squads = _ref.squads.value;

      final periodo = (f.inicio != null && f.fim != null)
          ? '${_fmt.format(f.inicio!)} – ${_fmt.format(f.fim!)}'
          : 'Período: mês atual';

      return Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickPeriodo(f),
              icon: const Icon(GjaIcons.calendar, size: 16),
              label: Text(periodo),
            ),
            if (empresas.isNotEmpty)
              AppFilterDropdown<String>(
                largura: 230,
                rotulo: 'Empresa',
                todosLabel: 'Todas as empresas',
                todosValue: '',
                valor: f.empresaNome ?? '',
                opcoes: [for (final e in empresas) (valor: e, label: e)],
                onChanged: (v) => _selecionarEmpresa(f, v),
              ),
            if (widget.mostrarSquad && squads.isNotEmpty)
              AppFilterDropdown<int>(
                largura: 230,
                rotulo: 'Squad',
                todosLabel: 'Todos os squads',
                todosValue: 0,
                valor: f.grupo ?? 0,
                opcoes: [for (final s in squads) (valor: s.id, label: s.nome)],
                onChanged: (v) => _selecionarSquad(f, v),
              ),
            if (_controller.temFiltroAtivo)
              TextButton.icon(
                onPressed: () {
                  _controller.limpar();
                  widget.onApply();
                },
                icon: const Icon(GjaIcons.clearFilter, size: 16),
                label: const Text('Limpar filtros'),
              ),
          ],
        ),
      );
    });
  }
}
