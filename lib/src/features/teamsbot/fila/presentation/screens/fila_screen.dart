import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/teamsbot/fila/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/fila/presentation/controllers/fila_controller.dart';
import 'package:gjamobile/src/features/teamsbot/fila/presentation/widgets/fila_status_badge.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — Fila de criação de ATAs (`/teamsbot/fila`).
///
/// Segue o padrão das listas de ATAs/Reuniões: painel de indicadores (KPIs),
/// busca instantânea, ordenação por coluna, chips de filtros ativos e layout
/// responsivo (tabela em telas largas, cards em telas estreitas).
class FilaScreen extends StatefulWidget {
  const FilaScreen({super.key});

  @override
  State<FilaScreen> createState() => _FilaScreenState();
}

class _FilaScreenState extends State<FilaScreen> {
  late final FilaController _controller;
  late final TextEditingController _busca;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<FilaController>();
    _busca = TextEditingController(text: _controller.busca.value);
    if (_controller.itens.value.isEmpty) {
      _controller.load();
    } else {
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _limpar() {
    _busca.clear();
    _controller.limparFiltros();
  }

  void _removeBusca() {
    _busca.clear();
    _controller.setBusca('');
  }

  void _removeStatus() => _controller.aplicarFiltro(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fila de criação de ATAs'),
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
        child: Column(
          children: [
            SignalBuilder(builder: (context) {
              final all = _controller.itens.value;
              if (all.isEmpty) return const SizedBox.shrink();
              return _StatsBar(
                itens: all,
                statusFilter: _controller.statusFilter.value,
                onStatus: _controller.alternarStatus,
              );
            }),
            _Filtros(
              controller: _controller,
              busca: _busca,
              onLimpar: _limpar,
            ),
            SignalBuilder(builder: (context) {
              return _ActiveFilters(
                busca: _controller.busca.value,
                status: _controller.statusFilter.value,
                onRemoveBusca: _removeBusca,
                onRemoveStatus: _removeStatus,
              );
            }),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.refresh,
                child: SignalBuilder(builder: (context) {
                  final all = _controller.itens.value;
                  final visible = _controller.visibleItens.value;
                  final isLoading = _controller.isLoading.value;
                  final error = _controller.error.value;
                  final retryingId = _controller.retryingId.value;

                  if (isLoading && all.isEmpty) {
                    return const AppLoading(message: 'Carregando fila…');
                  }
                  if (error != null && all.isEmpty) {
                    return AppErrorWidget(
                      title: 'Não foi possível carregar a fila',
                      message: error.message,
                      onRetry: _controller.load,
                    );
                  }
                  if (all.isEmpty) {
                    return ListView(children: [
                      SizedBox(height: context.height * 0.12),
                      const AppEmptyState(
                        icon: GjaIcons.inbox,
                        title: 'Fila vazia',
                        subtitle: 'Nenhum item de criação de ATA no momento.',
                      ),
                    ]);
                  }
                  if (visible.isEmpty) {
                    return _NoMatches(onClear: _limpar);
                  }
                  return _Conteudo(
                    itens: visible,
                    total: all.length,
                    sortColumn: _controller.sortColumn.value,
                    sortAscending: _controller.sortAscending.value,
                    retryingId: retryingId,
                    onSort: _controller.ordenarPor,
                    onRetry: _controller.retry,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicadores (KPIs)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.itens,
    required this.statusFilter,
    required this.onStatus,
  });

  final List<FilaItem> itens;
  final FilaStatus? statusFilter;
  final ValueChanged<FilaStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ac = context.appColors;

    final total = itens.length;
    int count(FilaStatus s) => itens.where((e) => e.status == s).length;

    final cards = <Widget>[
      _StatCard(
        icon: GjaIcons.inbox,
        label: 'Total',
        value: '$total',
        color: cs.primary,
      ),
      _StatCard(
        icon: GjaIcons.busy,
        label: 'Aguardando',
        value: '${count(FilaStatus.aguardando)}',
        color: ac.warning,
        selected: statusFilter == FilaStatus.aguardando,
        onTap: () => onStatus(FilaStatus.aguardando),
      ),
      _StatCard(
        icon: GjaIcons.refresh,
        label: 'Processando',
        value: '${count(FilaStatus.processando)}',
        color: ac.info,
        selected: statusFilter == FilaStatus.processando,
        onTap: () => onStatus(FilaStatus.processando),
      ),
      _StatCard(
        icon: GjaIcons.sysEnter2,
        label: 'Concluído',
        value: '${count(FilaStatus.concluido)}',
        color: ac.success,
        selected: statusFilter == FilaStatus.concluido,
        onTap: () => onStatus(FilaStatus.concluido),
      ),
      _StatCard(
        icon: GjaIcons.error,
        label: 'Erro',
        value: '${count(FilaStatus.erro)}',
        color: cs.error,
        selected: statusFilter == FilaStatus.erro,
        onTap: () => onStatus(FilaStatus.erro),
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

typedef OnSortFila = void Function(FilaSortColumn coluna, bool ascendente);

const Map<FilaSortColumn, String> _sortLabels = {
  FilaSortColumn.id: 'Item',
  FilaSortColumn.reuniao: 'Reunião',
  FilaSortColumn.status: 'Status',
  FilaSortColumn.tentativas: 'Tentativas',
  FilaSortColumn.criado: 'Criado',
  FilaSortColumn.iniciado: 'Iniciado',
  FilaSortColumn.concluido: 'Concluído',
};

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.itens,
    required this.total,
    required this.sortColumn,
    required this.sortAscending,
    required this.retryingId,
    required this.onSort,
    required this.onRetry,
  });

  final List<FilaItem> itens;
  final int total;
  final FilaSortColumn sortColumn;
  final bool sortAscending;
  final int? retryingId;
  final OnSortFila onSort;
  final ValueChanged<int> onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 820) {
        return Column(
          children: [
            _ResultCount(visible: itens.length, total: total),
            Expanded(
              child: _Tabela(
                itens: itens,
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                retryingId: retryingId,
                onSort: onSort,
                onRetry: onRetry,
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          _MobileSortBar(
            column: sortColumn,
            ascending: sortAscending,
            onSort: onSort,
            count: _ResultCount(visible: itens.length, total: total),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: itens.length,
              itemBuilder: (_, i) => _FilaTile(
                item: itens[i],
                isRetrying: retryingId == itens[i].id,
                onRetry: () => onRetry(itens[i].id),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.visible, required this.total});

  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final texto = visible == total
        ? '$total ${total == 1 ? 'item' : 'itens'}'
        : '$visible de $total itens';
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

/// Colunas da tabela da fila. As primeiras 7 são ordenáveis (mapeiam para
/// [FilaSortColumn]); ATA e Ações não são.
enum _Col { id, reuniao, status, tentativas, criado, iniciado, concluido, ata, acoes }

FilaSortColumn? _sortKeyOf(_Col c) => switch (c) {
      _Col.id => FilaSortColumn.id,
      _Col.reuniao => FilaSortColumn.reuniao,
      _Col.status => FilaSortColumn.status,
      _Col.tentativas => FilaSortColumn.tentativas,
      _Col.criado => FilaSortColumn.criado,
      _Col.iniciado => FilaSortColumn.iniciado,
      _Col.concluido => FilaSortColumn.concluido,
      _Col.ata || _Col.acoes => null,
    };

String _colLabel(_Col c) => switch (c) {
      _Col.id => 'Item',
      _Col.reuniao => 'Reunião',
      _Col.status => 'Status',
      _Col.tentativas => 'Tentativas',
      _Col.criado => 'Criado',
      _Col.iniciado => 'Iniciado',
      _Col.concluido => 'Concluído',
      _Col.ata => 'ATA',
      _Col.acoes => 'Ações',
    };

bool _colNumeric(_Col c) =>
    c == _Col.id || c == _Col.reuniao || c == _Col.tentativas;

class _Tabela extends StatelessWidget {
  const _Tabela({
    required this.itens,
    required this.sortColumn,
    required this.sortAscending,
    required this.retryingId,
    required this.onSort,
    required this.onRetry,
  });

  final List<FilaItem> itens;
  final FilaSortColumn sortColumn;
  final bool sortAscending;
  final int? retryingId;
  final OnSortFila onSort;
  final ValueChanged<int> onRetry;

  static const _cols = _Col.values;

  DataCell _cell(BuildContext context, FilaItem e, _Col col) {
    final cs = context.colors;
    switch (col) {
      case _Col.id:
        return DataCell(Text('${e.id}'));
      case _Col.reuniao:
        return DataCell(InkWell(
          onTap: () =>
              context.push(AppRoutes.teamsbotReuniaoDetalhePath(e.reuniaoId)),
          child: Text('#${e.reuniaoId}',
              style: TextStyle(color: cs.primary)),
        ));
      case _Col.status:
        return DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilaStatusBadge(status: e.status),
            if (e.erro != null) ...[
              SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: e.erro!,
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(GjaIcons.information, size: 16, color: cs.error),
              ),
            ],
          ],
        ));
      case _Col.tentativas:
        return DataCell(Text('${e.tentativas}'));
      case _Col.criado:
        return DataCell(Text(AtaFormat.dataHora(e.criadoEm)));
      case _Col.iniciado:
        return DataCell(Text(AtaFormat.dataHora(e.iniciadoEm)));
      case _Col.concluido:
        return DataCell(Text(AtaFormat.dataHora(e.concluidoEm)));
      case _Col.ata:
        return DataCell(e.ataId == null
            ? const Text('—')
            : InkWell(
                onTap: () =>
                    context.push(AppRoutes.teamsbotAtaDetalhePath(e.ataId!)),
                child: Text('#${e.ataId}',
                    style: TextStyle(color: cs.primary)),
              ));
      case _Col.acoes:
        if (!e.status.isErro) return const DataCell(Text('—'));
        final retrying = retryingId == e.id;
        return DataCell(
          retrying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: 'Tentar novamente',
                  icon: const Icon(GjaIcons.refresh, size: 18),
                  onPressed: () => onRetry(e.id),
                ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final sortIndex = _cols.indexWhere((c) => _sortKeyOf(c) == sortColumn);

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
                    label: Text(_colLabel(c)),
                    numeric: _colNumeric(c),
                    onSort: _sortKeyOf(c) == null
                        ? null
                        : (columnIndex, ascending) =>
                            onSort(_sortKeyOf(_cols[columnIndex])!, ascending),
                  ),
              ],
              rows: [
                for (final e in itens)
                  DataRow(cells: [for (final c in _cols) _cell(context, e, c)]),
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

  final FilaSortColumn column;
  final bool ascending;
  final OnSortFila onSort;
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
            child: DropdownButton<FilaSortColumn>(
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

class _FilaTile extends StatelessWidget {
  const _FilaTile({
    required this.item,
    required this.isRetrying,
    required this.onRetry,
  });

  final FilaItem item;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return AppCard(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Item nº ${item.id}',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              FilaStatusBadge(status: item.status),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context
                    .push(AppRoutes.teamsbotReuniaoDetalhePath(item.reuniaoId)),
                icon: const Icon(GjaIcons.appointment, size: 16),
                label: Text('Reunião #${item.reuniaoId}'),
              ),
              Text('Tentativas: ${item.tentativas}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            'Criado: ${AtaFormat.dataHora(item.criadoEm)}  ·  Iniciado: ${AtaFormat.dataHora(item.iniciadoEm)}  ·  Concluído: ${AtaFormat.dataHora(item.concluidoEm)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (item.erro != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(item.erro!, style: tt.bodySmall?.copyWith(color: cs.error)),
          ],
          if (item.ataId != null || item.status.isErro) ...[
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (item.ataId != null)
                  AppButton(
                    label: 'Abrir ATA',
                    variant: ButtonVariant.secondary,
                    onPressed: () => context
                        .push(AppRoutes.teamsbotAtaDetalhePath(item.ataId!)),
                  ),
                if (item.status.isErro)
                  AppButton(
                    label: 'Tentar novamente',
                    variant: ButtonVariant.outline,
                    isLoading: isRetrying,
                    prefixIcon: const Icon(GjaIcons.refresh, size: 18),
                    onPressed: onRetry,
                  ),
              ],
            ),
          ],
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
          title: 'Nenhum item para estes filtros',
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
    required this.busca,
    required this.onLimpar,
  });

  final FilaController controller;
  final TextEditingController busca;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final full = constraints.maxWidth;
        final buscaW = narrow ? full : 260.0;
        final dropW = narrow ? full : 200.0;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: buscaW,
              child: SignalBuilder(builder: (context) {
                final temTexto = controller.busca.value.isNotEmpty;
                return AppTextField(
                  label: 'Buscar item / reunião / ATA',
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
              width: dropW,
              child: SignalBuilder(builder: (context) {
                return _FilaStatusDropdown(
                  value: controller.statusFilter.value,
                  onChanged: controller.aplicarFiltro,
                );
              }),
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
    required this.status,
    required this.onRemoveBusca,
    required this.onRemoveStatus,
  });

  final String busca;
  final FilaStatus? status;
  final VoidCallback onRemoveBusca;
  final VoidCallback onRemoveStatus;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (busca.trim().isNotEmpty)
        _FilterChip(label: 'Busca: "$busca"', onRemove: onRemoveBusca),
      if (status != null)
        _FilterChip(label: 'Status: ${status!.label}', onRemove: onRemoveStatus),
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

class _FilaStatusDropdown extends StatelessWidget {
  const _FilaStatusDropdown({required this.value, required this.onChanged});
  final FilaStatus? value;
  final ValueChanged<FilaStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<FilaStatus?>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: const Text('Status: todos'),
        items: [
          const DropdownMenuItem(child: Text('Status: todos')),
          for (final s in FilaStatus.values)
            if (s != FilaStatus.desconhecido)
              DropdownMenuItem(value: s, child: Text(s.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
