import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/ata_status.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/widgets/status_badges.dart';
import 'package:gjamobile/src/features/teamsbot/fila/presentation/widgets/fila_status_badge.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/controllers/reunioes_list_controller.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/widgets/reuniao_badges.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — Reuniões monitoradas (`/teamsbot/reunioes`).
///
/// Segue o padrão da lista de ATAs: painel de indicadores (KPIs), busca
/// instantânea, ordenação por coluna, chips de filtros ativos e layout
/// responsivo (tabela em telas largas, cards em telas estreitas).
class ReunioesListScreen extends StatefulWidget {
  const ReunioesListScreen({super.key});

  @override
  State<ReunioesListScreen> createState() => _ReunioesListScreenState();
}

class _ReunioesListScreenState extends State<ReunioesListScreen> {
  late final ReunioesListController _controller;
  late final TextEditingController _usuario;
  late final TextEditingController _busca;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<ReunioesListController>();
    _usuario = TextEditingController(text: _controller.usuario.value);
    _busca = TextEditingController(text: _controller.busca.value);
    // Busca no backend apenas na primeira entrada (lista vazia). Ao voltar para
    // a tela, reusa o que está em memória — atualizar é manual (botão/puxar)
    // ou automático via polling quando há reuniões em andamento.
    if (_controller.reunioes.value.isEmpty) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _usuario.dispose();
    _busca.dispose();
    super.dispose();
  }

  void _open(int id) => context.push(AppRoutes.teamsbotReuniaoDetalhePath(id));

  Future<void> _pickPeriodo() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _controller.de.value != null && _controller.ate.value != null
              ? DateTimeRange(
                  start: _controller.de.value!, end: _controller.ate.value!)
              : null,
    );
    if (range != null) {
      _controller.setPeriodo(de: range.start, ate: range.end);
      _controller.load();
    }
  }

  void _filtrar() {
    _controller.setUsuario(_usuario.text.trim());
    _controller.load();
  }

  void _limpar() {
    _usuario.clear();
    _busca.clear();
    _controller.clearFilters();
  }

  // Remoção individual de filtros (chips).
  void _removeBusca() {
    _busca.clear();
    _controller.setBusca('');
  }

  void _removePeriodo() {
    _controller.setPeriodo(de: null, ate: null);
    _controller.load();
  }

  void _removeUsuario() {
    _usuario.clear();
    _controller.setUsuario('');
    _controller.load();
  }

  void _removeStatusReuniao() {
    _controller.setStatusReuniao(null);
    _controller.load();
  }

  void _removeStatusAta() {
    _controller.setStatusAta(null);
    _controller.load();
  }

  void _removeTranscricao() {
    _controller.setComTranscricao(null);
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuniões monitoradas'),
        automaticallyImplyLeading: false,
        actions: [
          SignalBuilder(builder: (context) {
            if (_controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(GjaIcons.refresh),
              onPressed: _controller.refresh,
            );
          }),
        ],
      ),
      body: AppResponsiveContainer(
        child: LayoutBuilder(builder: (context, constraints) {
          // Largo: cabeçalho fixo + tabela rolável (Expanded). Estreito: tudo
          // rola junto num único scroll — no mobile os filtros empilhados
          // ficavam mais altos que o viewport e estouravam o Expanded da lista.
          return constraints.maxWidth >= 820 ? _wideBody() : _narrowBody();
        }),
      ),
    );
  }

  // ── Cabeçalho compartilhado (KPIs, filtros e chips de filtros ativos) ──────

  Widget _statsBar() => SignalBuilder(builder: (context) {
        final all = _controller.reunioes.value;
        if (all.isEmpty) return const SizedBox.shrink();
        return _StatsBar(
          reunioes: all,
          comTranscricaoFilter: _controller.comTranscricao.value,
          onTranscricao: _controller.alternarTranscricao,
        );
      });

  Widget _filtros() => _Filtros(
        controller: _controller,
        usuario: _usuario,
        busca: _busca,
        onPickPeriodo: _pickPeriodo,
        onFiltrar: _filtrar,
        onLimpar: _limpar,
      );

  Widget _activeFilters() => SignalBuilder(builder: (context) {
        return _ActiveFilters(
          busca: _controller.busca.value,
          de: _controller.de.value,
          ate: _controller.ate.value,
          usuario: _controller.usuario.value,
          statusReuniao: _controller.statusReuniao.value,
          statusAta: _controller.statusAta.value,
          comTranscricao: _controller.comTranscricao.value,
          onRemoveBusca: _removeBusca,
          onRemovePeriodo: _removePeriodo,
          onRemoveUsuario: _removeUsuario,
          onRemoveStatusReuniao: _removeStatusReuniao,
          onRemoveStatusAta: _removeStatusAta,
          onRemoveTranscricao: _removeTranscricao,
        );
      });

  /// Telas largas: cabeçalho fixo e a tabela ocupa o resto com rolagem própria.
  Widget _wideBody() {
    return Column(
      children: [
        _statsBar(),
        _filtros(),
        _activeFilters(),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: SignalBuilder(builder: (context) {
              final all = _controller.reunioes.value;
              final visible = _controller.visibleReunioes.value;
              final isLoading = _controller.isLoading.value;
              final error = _controller.error.value;

              if (isLoading && all.isEmpty) {
                return const AppLoading(message: 'Carregando reuniões…');
              }
              if (error != null && all.isEmpty) {
                return AppErrorWidget(
                  title: 'Não foi possível carregar as reuniões',
                  message: error.message,
                  onRetry: _controller.load,
                );
              }
              if (all.isEmpty) {
                return ListView(children: [
                  SizedBox(height: context.height * 0.12),
                  const AppEmptyState(
                    icon: GjaIcons.timeOff,
                    title: 'Nenhuma reunião encontrada',
                    subtitle:
                        'Ajuste os filtros ou aguarde a próxima coleta do calendário.',
                  ),
                ]);
              }
              if (visible.isEmpty) {
                return _NoMatches(onClear: _limpar);
              }
              return Column(
                children: [
                  _ResultCount(visible: visible.length, total: all.length),
                  Expanded(
                    child: _Tabela(
                      reunioes: visible,
                      sortColumn: _controller.sortColumn.value,
                      sortAscending: _controller.sortAscending.value,
                      onSort: _controller.ordenarPor,
                      onOpen: _open,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Telas estreitas: cabeçalho e cards rolam juntos num único scroll, evitando
  /// o overflow do cabeçalho e mantendo a lista sempre acessível.
  Widget _narrowBody() {
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _statsBar()),
          SliverToBoxAdapter(child: _filtros()),
          SliverToBoxAdapter(child: _activeFilters()),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          // Seletor de ordenação (só quando há lista visível).
          SignalBuilder(builder: (context) {
            final all = _controller.reunioes.value;
            final visible = _controller.visibleReunioes.value;
            final isLoading = _controller.isLoading.value;
            final error = _controller.error.value;
            final temLista = !(isLoading && all.isEmpty) &&
                !(error != null && all.isEmpty) &&
                all.isNotEmpty &&
                visible.isNotEmpty;
            if (!temLista) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: _MobileSortBar(
                column: _controller.sortColumn.value,
                ascending: _controller.sortAscending.value,
                onSort: _controller.ordenarPor,
                count: _ResultCount(visible: visible.length, total: all.length),
              ),
            );
          }),
          SignalBuilder(builder: (context) {
            final all = _controller.reunioes.value;
            final visible = _controller.visibleReunioes.value;
            final isLoading = _controller.isLoading.value;
            final error = _controller.error.value;

            if (isLoading && all.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoading(message: 'Carregando reuniões…'),
              );
            }
            if (error != null && all.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorWidget(
                  title: 'Não foi possível carregar as reuniões',
                  message: error.message,
                  onRetry: _controller.load,
                ),
              );
            }
            if (all.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: GjaIcons.timeOff,
                  title: 'Nenhuma reunião encontrada',
                  subtitle:
                      'Ajuste os filtros ou aguarde a próxima coleta do calendário.',
                ),
              );
            }
            if (visible.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: GjaIcons.sysFind,
                  title: 'Nenhuma reunião para estes filtros',
                  subtitle: 'Ajuste a busca ou limpe os filtros.',
                  actionLabel: 'Limpar filtros',
                  onAction: _limpar,
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.all(AppSpacing.md),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (_, i) =>
                    _ReuniaoTile(r: visible[i], onOpen: _open),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicadores (KPIs)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.reunioes,
    required this.comTranscricaoFilter,
    required this.onTranscricao,
  });

  final List<MonitoredMeetingResumo> reunioes;
  final bool? comTranscricaoFilter;
  final VoidCallback onTranscricao;

  static bool _isErro(MonitoredMeetingResumo r) =>
      r.statusProcessamento ==
          ReuniaoProcessamentoStatus.transcriptionSaveError ||
      r.statusProcessamento ==
          ReuniaoProcessamentoStatus.minutesCreationError ||
      (r.statusFila?.isErro ?? false);

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ac = context.appColors;

    final total = reunioes.length;
    final andamento = reunioes.where((r) => r.emAndamento).length;
    final comTranscricao = reunioes.where((r) => r.temTranscricao).length;
    final comAta = reunioes.where((r) => r.ataId != null).length;
    final erros = reunioes.where(_isErro).length;

    final cards = <Widget>[
      _StatCard(
        icon: GjaIcons.notes,
        label: 'Total',
        value: '$total',
        color: cs.primary,
      ),
      _StatCard(
        icon: GjaIcons.refresh,
        label: 'Em andamento',
        value: '$andamento',
        color: ac.warning,
      ),
      _StatCard(
        icon: GjaIcons.text,
        label: 'Com transcrição',
        value: '$comTranscricao',
        color: ac.info,
        selected: comTranscricaoFilter ?? false,
        onTap: onTranscricao,
      ),
      _StatCard(
        icon: GjaIcons.documentText,
        label: 'Com ATA',
        value: '$comAta',
        color: ac.success,
      ),
      _StatCard(
        icon: GjaIcons.error,
        label: 'Erros',
        value: '$erros',
        color: cs.error,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: AppSpacing.sm),
                SizedBox(width: 132, child: cards[i]),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return AppCard(
      onTap: onTap,
      color: selected ? color.withValues(alpha: 0.14) : null,
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: AppBorders.md,
                ),
                child: Icon(icon, size: 16.sp, color: color),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  selected ? GjaIcons.filter : GjaIcons.filter,
                  size: 14.sp,
                  color: selected ? color : cs.onSurfaceVariant,
                ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista / tabela
// ─────────────────────────────────────────────────────────────────────────────

typedef OnSortReuniao = void Function(
    ReuniaoSortColumn coluna, bool ascendente);

const Map<ReuniaoSortColumn, String> _sortLabels = {
  ReuniaoSortColumn.assunto: 'Assunto',
  ReuniaoSortColumn.organizador: 'Organizador',
  ReuniaoSortColumn.inicio: 'Início',
  ReuniaoSortColumn.online: 'Online',
  ReuniaoSortColumn.participantes: 'Part.',
  ReuniaoSortColumn.status: 'Status',
  ReuniaoSortColumn.transcricao: 'Transcrição',
  ReuniaoSortColumn.fila: 'Fila',
  ReuniaoSortColumn.ata: 'ATA',
};

bool _isNumeric(ReuniaoSortColumn c) => c == ReuniaoSortColumn.participantes;

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.visible, required this.total});

  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final texto = visible == total
        ? '$total ${total == 1 ? 'reunião' : 'reuniões'}'
        : '$visible de $total reuniões';
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
        child: Text(texto,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ),
    );
  }
}

class _Tabela extends StatelessWidget {
  const _Tabela({
    required this.reunioes,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onOpen,
  });

  final List<MonitoredMeetingResumo> reunioes;
  final ReuniaoSortColumn sortColumn;
  final bool sortAscending;
  final OnSortReuniao onSort;
  final ValueChanged<int> onOpen;

  static const _cols = ReuniaoSortColumn.values;

  DataCell _cell(BuildContext context, MonitoredMeetingResumo r,
      ReuniaoSortColumn coluna) {
    final cs = context.colors;
    return switch (coluna) {
      ReuniaoSortColumn.assunto => DataCell(ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(r.assunto ?? '(sem assunto)',
              overflow: TextOverflow.ellipsis),
        )),
      ReuniaoSortColumn.organizador => DataCell(ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(r.organizador ?? '—', overflow: TextOverflow.ellipsis),
        )),
      ReuniaoSortColumn.inicio => DataCell(Text(AtaFormat.dataHora(r.inicio))),
      ReuniaoSortColumn.online => DataCell(Icon(
          r.online ? GjaIcons.video : GjaIcons.unwired,
          size: 18,
          color: r.online ? cs.primary : cs.onSurfaceVariant,
        )),
      ReuniaoSortColumn.participantes =>
        DataCell(Text('${r.totalParticipantes}')),
      ReuniaoSortColumn.status =>
        DataCell(ReuniaoStatusBadge(status: r.statusProcessamento)),
      ReuniaoSortColumn.transcricao => DataCell(Icon(
          r.temTranscricao ? GjaIcons.sysEnter2 : GjaIcons.less,
          size: 18,
          color: r.temTranscricao ? context.appColors.success : cs.onSurfaceVariant,
        )),
      ReuniaoSortColumn.fila => DataCell(r.statusFila == null
          ? const Text('—')
          : FilaStatusBadge(status: r.statusFila!)),
      ReuniaoSortColumn.ata =>
        DataCell(_AtaCell(ataId: r.ataId, statusAta: r.statusAta)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final sortIndex = _cols.indexOf(sortColumn);

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              sortColumnIndex: sortIndex >= 0 ? sortIndex : null,
              sortAscending: sortAscending,
              headingRowColor: WidgetStatePropertyAll(
                  cs.surfaceContainerHighest.withValues(alpha: 0.4)),
              columns: [
                for (final c in _cols)
                  DataColumn(
                    label: Text(_sortLabels[c]!),
                    numeric: _isNumeric(c),
                    onSort: (columnIndex, ascending) =>
                        onSort(_cols[columnIndex], ascending),
                  ),
              ],
              rows: [
                for (final r in reunioes)
                  DataRow(
                    onSelectChanged: (_) => onOpen(r.id),
                    cells: [for (final c in _cols) _cell(context, r, c)],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _MobileSortBar extends StatelessWidget {
  const _MobileSortBar({
    required this.column,
    required this.ascending,
    required this.onSort,
    required this.count,
  });

  final ReuniaoSortColumn column;
  final bool ascending;
  final OnSortReuniao onSort;
  final Widget count;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: count),
          Icon(GjaIcons.sort, size: 16.sp, color: cs.onSurfaceVariant),
          SizedBox(width: AppSpacing.xs),
          DropdownButtonHideUnderline(
            child: DropdownButton<ReuniaoSortColumn>(
              value: column,
              isDense: true,
              items: [
                for (final entry in _sortLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (col) {
                if (col != null) onSort(col, ascending);
              },
            ),
          ),
          IconButton(
            tooltip: ascending ? 'Crescente' : 'Decrescente',
            icon: Icon(ascending ? GjaIcons.arrowTop : GjaIcons.arrowBottom,
                size: 18.sp),
            onPressed: () => onSort(column, !ascending),
          ),
        ],
      ),
    );
  }
}

class _AtaCell extends StatelessWidget {
  const _AtaCell({required this.ataId, required this.statusAta});
  final int? ataId;
  final AtaStatus? statusAta;

  @override
  Widget build(BuildContext context) {
    if (ataId == null) return const Text('—');
    return InkWell(
      onTap: () => context.push(AppRoutes.teamsbotAtaDetalhePath(ataId!)),
      child: statusAta != null
          ? AtaStatusBadge(status: statusAta!)
          : Text('#$ataId', style: TextStyle(color: context.colors.primary)),
    );
  }
}

class _ReuniaoTile extends StatelessWidget {
  const _ReuniaoTile({required this.r, required this.onOpen});
  final MonitoredMeetingResumo r;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return AppCard(
      onTap: () => onOpen(r.id),
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.assunto ?? '(sem assunto)',
                    style:
                        tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Icon(
                r.online ? GjaIcons.video : GjaIcons.unwired,
                size: 16.sp,
                color: r.online ? cs.primary : cs.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
              '${r.organizador ?? '—'} · ${AtaFormat.dataHora(r.inicio)} · ${r.totalParticipantes} part.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ReuniaoStatusBadge(status: r.statusProcessamento),
              if (r.statusFila != null) FilaStatusBadge(status: r.statusFila!),
              if (r.statusAta != null) AtaStatusBadge(status: r.statusAta!),
              Icon(
                r.temTranscricao
                    ? GjaIcons.text
                    : GjaIcons.strikethrough,
                size: 16.sp,
                color: r.temTranscricao ? cs.primary : cs.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: context.height * 0.12),
        AppEmptyState(
          icon: GjaIcons.sysFind,
          title: 'Nenhuma reunião para estes filtros',
          subtitle: 'Ajuste a busca ou limpe os filtros.',
          actionLabel: 'Limpar filtros',
          onAction: onClear,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtros
// ─────────────────────────────────────────────────────────────────────────────

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.controller,
    required this.usuario,
    required this.busca,
    required this.onPickPeriodo,
    required this.onFiltrar,
    required this.onLimpar,
  });

  final ReunioesListController controller;
  final TextEditingController usuario;
  final TextEditingController busca;
  final VoidCallback onPickPeriodo;
  final VoidCallback onFiltrar;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final full = constraints.maxWidth;
        final buscaW = narrow ? full : 240.0;
        final fieldW = narrow ? full : 220.0;
        final dropW = narrow ? full : 190.0;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Busca client-side por assunto/organizador (instantânea).
            SizedBox(
              width: buscaW,
              child: SignalBuilder(builder: (context) {
                final temTexto = controller.busca.value.isNotEmpty;
                return AppTextField(
                  label: 'Buscar assunto/organizador',
                  controller: busca,
                  prefixIcon: const Icon(GjaIcons.search, size: 18),
                  suffixIcon: temTexto
                      ? IconButton(
                          icon: const Icon(GjaIcons.decline, size: 18),
                          onPressed: () {
                            busca.clear();
                            controller.setBusca('');
                          },
                        )
                      : null,
                  onChanged: controller.setBusca,
                );
              }),
            ),
            SizedBox(
              width: narrow ? full : null,
              child: OutlinedButton.icon(
                onPressed: onPickPeriodo,
                icon: const Icon(GjaIcons.calendar, size: 18),
                label: SignalBuilder(builder: (context) {
                  final de = controller.de.value;
                  final ate = controller.ate.value;
                  return Text(de != null && ate != null
                      ? '${AtaFormat.data(de)} – ${AtaFormat.data(ate)}'
                      : 'Período');
                }),
              ),
            ),
            SizedBox(
              width: fieldW,
              child: AppTextField(
                label: 'Usuário (GUID)',
                controller: usuario,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => onFiltrar(),
              ),
            ),
            SizedBox(
              width: dropW,
              child: SignalBuilder(builder: (context) {
                return _StatusReuniaoDropdown(
                  value: controller.statusReuniao.value,
                  onChanged: (v) {
                    controller.setStatusReuniao(v);
                    controller.load();
                  },
                );
              }),
            ),
            SizedBox(
              width: dropW,
              child: SignalBuilder(builder: (context) {
                return _StatusAtaDropdown(
                  value: controller.statusAta.value,
                  onChanged: (v) {
                    controller.setStatusAta(v);
                    controller.load();
                  },
                );
              }),
            ),
            SizedBox(
              width: dropW,
              child: SignalBuilder(builder: (context) {
                return _TranscricaoDropdown(
                  value: controller.comTranscricao.value,
                  onChanged: (v) {
                    controller.setComTranscricao(v);
                    controller.load();
                  },
                );
              }),
            ),
            // FilledButton com tamanho fixo: o AppButton escala com o
            // screenutil e ficava gigante em monitores grandes.
            FilledButton.icon(
              onPressed: onFiltrar,
              icon: const Icon(GjaIcons.filter, size: 18),
              label: const Text('Filtrar'),
            ),
            SignalBuilder(builder: (context) {
              return TextButton(
                onPressed: controller.temFiltroAtivo ? onLimpar : null,
                child: const Text('Limpar'),
              );
            }),
          ],
        );
      }),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.busca,
    required this.de,
    required this.ate,
    required this.usuario,
    required this.statusReuniao,
    required this.statusAta,
    required this.comTranscricao,
    required this.onRemoveBusca,
    required this.onRemovePeriodo,
    required this.onRemoveUsuario,
    required this.onRemoveStatusReuniao,
    required this.onRemoveStatusAta,
    required this.onRemoveTranscricao,
  });

  final String busca;
  final DateTime? de;
  final DateTime? ate;
  final String usuario;
  final ReuniaoProcessamentoStatus? statusReuniao;
  final AtaStatus? statusAta;
  final bool? comTranscricao;
  final VoidCallback onRemoveBusca;
  final VoidCallback onRemovePeriodo;
  final VoidCallback onRemoveUsuario;
  final VoidCallback onRemoveStatusReuniao;
  final VoidCallback onRemoveStatusAta;
  final VoidCallback onRemoveTranscricao;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (busca.trim().isNotEmpty)
        _FilterChip(label: 'Busca: "$busca"', onRemove: onRemoveBusca),
      if (de != null && ate != null)
        _FilterChip(
            label: 'Período: ${AtaFormat.data(de)} – ${AtaFormat.data(ate)}',
            onRemove: onRemovePeriodo),
      if (usuario.trim().isNotEmpty)
        _FilterChip(label: 'Usuário: $usuario', onRemove: onRemoveUsuario),
      if (statusReuniao != null)
        _FilterChip(
            label: 'Reunião: ${statusReuniao!.label}',
            onRemove: onRemoveStatusReuniao),
      if (statusAta != null)
        _FilterChip(
            label: 'ATA: ${statusAta!.label}', onRemove: onRemoveStatusAta),
      if (comTranscricao != null)
        _FilterChip(
            label: comTranscricao!
                ? 'Com transcrição'
                : 'Sem transcrição',
            onRemove: onRemoveTranscricao),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
            spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: chips),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    // Cores explícitas do scheme para funcionar no tema escuro.
    return Chip(
      label: Text(label),
      labelStyle: context.textTheme.bodySmall?.copyWith(color: cs.onSurface),
      backgroundColor: cs.surfaceContainerHigh,
      side: BorderSide(color: cs.outlineVariant),
      onDeleted: onRemove,
      deleteIcon: const Icon(GjaIcons.decline, size: 16),
      deleteIconColor: cs.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _StatusReuniaoDropdown extends StatelessWidget {
  const _StatusReuniaoDropdown({required this.value, required this.onChanged});
  final ReuniaoProcessamentoStatus? value;
  final ValueChanged<ReuniaoProcessamentoStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<ReuniaoProcessamentoStatus?>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: const Text('Status reunião'),
        items: [
          const DropdownMenuItem(child: Text('Reunião: todas')),
          for (final s in ReuniaoProcessamentoStatus.values)
            if (s != ReuniaoProcessamentoStatus.desconhecido)
              DropdownMenuItem(value: s, child: Text(s.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StatusAtaDropdown extends StatelessWidget {
  const _StatusAtaDropdown({required this.value, required this.onChanged});
  final AtaStatus? value;
  final ValueChanged<AtaStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AtaStatus?>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: const Text('Status ATA'),
        items: [
          const DropdownMenuItem(child: Text('ATA: todas')),
          for (final s in AtaStatus.values)
            if (s != AtaStatus.desconhecido)
              DropdownMenuItem(value: s, child: Text(s.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _TranscricaoDropdown extends StatelessWidget {
  const _TranscricaoDropdown({required this.value, required this.onChanged});
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<bool?>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: const Text('Transcrição'),
        items: const [
          DropdownMenuItem(child: Text('Transcrição: todas')),
          DropdownMenuItem(value: true, child: Text('Com transcrição')),
          DropdownMenuItem(value: false, child: Text('Sem transcrição')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
