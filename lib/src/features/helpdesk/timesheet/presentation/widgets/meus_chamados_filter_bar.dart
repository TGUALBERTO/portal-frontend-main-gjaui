import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/bi/shared/controllers/filtros_reference_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/meus_chamados_filtro.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/tipo_vinculo.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/meus_chamados_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Filtros do painel "Meus chamados": busca livre, período de abertura,
/// empresa, vínculo, status e urgência.
///
/// Empilhados, os filtros comem ~300 px do topo do painel e empurram os
/// chamados para fora da tela — por isso tudo **abaixo da busca** vive numa
/// seção recolhível, fechada por padrão. A busca fica de fora: digitar o número
/// do chamado é a ação mais frequente aqui, e escondê-la custaria um clique
/// toda vez.
///
/// As empresas vêm do mesmo `GET /dashboards/filtros` que alimenta o BI (nomes
/// já normalizados, um rótulo por grupo de entidades). Urgência, status e
/// vínculo são listas fixas: são códigos do GLPI, sem tabela de referência.
class MeusChamadosFilterBar extends StatefulWidget {
  const MeusChamadosFilterBar({super.key, required this.controller});

  final MeusChamadosController controller;

  @override
  State<MeusChamadosFilterBar> createState() => _MeusChamadosFilterBarState();
}

class _MeusChamadosFilterBarState extends State<MeusChamadosFilterBar> {
  late final FiltrosReferenceController _ref;
  final _buscaCtrl = TextEditingController();

  /// Sentinelas de "sem filtro" para os dropdowns tipados.
  static const _semEmpresa = '';
  static const _semUrgencia = 0;
  static const _semVinculo = 0;

  /// Valores do dropdown de status. `-1` (em aberto) é o padrão da tela e não
  /// corresponde a um código do GLPI: liga `apenasAbertos`. `0` = todos.
  static const _statusEmAberto = -1;
  static const _statusTodos = 0;

  MeusChamadosController get _controller => widget.controller;

  /// Estado do recolhimento. Fica no State (não no controller) porque é
  /// preferência de visualização, não filtro: reabrir a gaveta no mobile
  /// remonta o painel e volta ao padrão fechado, que é o desejado.
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _ref = AppInjector.get<FiltrosReferenceController>();
    // Best-effort: sem opções, o seletor de empresa simplesmente não aparece.
    _ref.load();
    _buscaCtrl.text = _controller.filtroSignal.peek().termo;
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPeriodo(MeusChamadosFiltro f) async {
    final escolhido = await pickDatePeriod(
      context,
      inicio: f.dataIni,
      fim: f.dataFim,
    );
    if (escolhido == null) return;
    _controller.aplicarFiltro(
      f.copyWith(dataIni: escolhido.start, dataFim: escolhido.end),
    );
  }

  void _selecionarStatus(MeusChamadosFiltro f, int valor) {
    _controller.aplicarFiltro(switch (valor) {
      _statusEmAberto => f.copyWith(limparStatus: true, apenasAbertos: true),
      _statusTodos => f.copyWith(limparStatus: true, apenasAbertos: false),
      _ => f.copyWith(status: valor, apenasAbertos: false),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final f = _controller.filtroSignal.value;
      final empresas = _ref.empresas.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Buscar',
            hint: 'Título ou nº do chamado',
            controller: _buscaCtrl,
            onChanged: _controller.buscar,
            prefixIcon: const Icon(GjaIcons.search, size: 18),
          ),
          SizedBox(height: AppSpacing.sm),
          _Cabecalho(
            expandido: _expandido,
            ativos: f.filtrosAtivos,
            onToggle: () => setState(() => _expandido = !_expandido),
            onLimpar: () {
              _buscaCtrl.clear();
              _controller.limparFiltros();
            },
          ),
          // Recolhido, o conteudo sai da arvore: mante-lo montado com altura
          // zero ainda reservaria espaco no Column do painel.
          if (_expandido) SizedBox(height: AppSpacing.sm),
          if (_expandido)
          // Coluna, nao Wrap: o painel e estreito, e larguras fixas lado a
          // lado quebrariam de forma irregular conforme o texto de cada opcao.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickPeriodo(f),
                icon: const Icon(GjaIcons.calendar, size: 16),
                label: Text(_periodoLabel(f)),
              ),
              AppFilterDropdown<int>(
                rotulo: 'Vínculo',
                todosLabel: 'Todos os vínculos',
                todosValue: _semVinculo,
                valor: f.tipoVinculo?.codigo ?? _semVinculo,
                opcoes: [
                  for (final v in TipoVinculo.values)
                    (valor: v.codigo, label: v.label),
                ],
                onChanged: (v) => _controller.aplicarFiltro(
                  v == _semVinculo
                      ? f.copyWith(limparVinculo: true)
                      : f.copyWith(tipoVinculo: TipoVinculo.fromCodigo(v)),
                ),
              ),
              AppFilterDropdown<int>(
                rotulo: 'Status',
                todosLabel: 'Em aberto',
                todosValue: _statusEmAberto,
                valor: f.status ??
                    (f.apenasAbertos ? _statusEmAberto : _statusTodos),
                opcoes: const [
                  (valor: _statusTodos, label: 'Todos os status'),
                  (valor: 1, label: 'Novo'),
                  (valor: 2, label: 'Em atendimento'),
                  (valor: 3, label: 'Em atendimento (planejado)'),
                  (valor: 4, label: 'Pendente'),
                  (valor: 5, label: 'Solucionado'),
                  (valor: 6, label: 'Fechado'),
                ],
                onChanged: (v) => _selecionarStatus(f, v),
              ),
              AppFilterDropdown<int>(
                rotulo: 'Urgência',
                todosLabel: 'Todas as urgências',
                todosValue: _semUrgencia,
                valor: f.urgencia ?? _semUrgencia,
                opcoes: const [
                  (valor: 5, label: 'Muito alta'),
                  (valor: 4, label: 'Alta'),
                  (valor: 3, label: 'Média'),
                  (valor: 2, label: 'Baixa'),
                  (valor: 1, label: 'Muito baixa'),
                ],
                onChanged: (v) => _controller.aplicarFiltro(
                  v == _semUrgencia
                      ? f.copyWith(limparUrgencia: true)
                      : f.copyWith(urgencia: v),
                ),
              ),
              if (empresas.isNotEmpty)
                AppFilterDropdown<String>(
                  rotulo: 'Empresa',
                  todosLabel: 'Todas as empresas',
                  todosValue: _semEmpresa,
                  valor: f.empresaNome ?? _semEmpresa,
                  opcoes: [for (final e in empresas) (valor: e, label: e)],
                  onChanged: (v) => _controller.aplicarFiltro(
                    v.isEmpty
                        ? f.copyWith(limparEmpresa: true)
                        : f.copyWith(empresaNome: v),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }

  static String _periodoLabel(MeusChamadosFiltro f) {
    final ini = f.dataIni;
    final fim = f.dataFim;
    if (ini == null || fim == null) return 'Período';
    return '${_curta(ini)} – ${_curta(fim)}';
  }

  static String _curta(DateTime d) =>
      '${_dois(d.day)}/${_dois(d.month)}/${d.year % 100}';

  static String _dois(int n) => n.toString().padLeft(2, '0');
}

/// Linha que abre/fecha os filtros. Recolhida, é o único sinal de que existe
/// algo aplicado ali dentro — daí o contador ao lado do rótulo.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.expandido,
    required this.ativos,
    required this.onToggle,
    required this.onLimpar,
  });

  final bool expandido;
  final int ativos;
  final VoidCallback onToggle;

  /// Limpa os filtros. Fica no cabeçalho, e não junto dos campos, para
  /// continuar alcançável com a seção recolhida — senão quem tem filtro de pé
  /// precisaria abrir a seção só para desfazê-lo.
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final temAtivos = ativos > 0;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              GjaIcons.filter,
              size: 18,
              color: temAtivos ? cs.primary : cs.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Filtros',
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: temAtivos ? cs.primary : cs.onSurface,
              ),
            ),
            if (temAtivos) ...[
              SizedBox(width: AppSpacing.xs),
              // Contador, não um ponto: recolhido, "3" evita abrir a seção só
              // para descobrir quantos filtros estão de pé.
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  '$ativos',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (temAtivos)
              IconButton(
                onPressed: onLimpar,
                tooltip: 'Limpar filtros',
                icon: const Icon(GjaIcons.clearFilter, size: 18),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.all(AppSpacing.xs),
              ),
            SizedBox(width: AppSpacing.xs),
            Icon(
              expandido ? GjaIcons.slimArrowUp : GjaIcons.slimArrowDown,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
