import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/controllers/atas_list_controller.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/widgets/status_badges.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/empresa_field.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela 1 — Lista de ATAs (`/teamsbot`). Renderizada dentro da casca responsiva.
///
/// Layout responsivo: em telas largas mostra tabela ordenável por coluna; em
/// telas estreitas, cards com seletor de ordenação. Um painel de indicadores
/// (KPIs) clicáveis funciona como atalho de filtro, complementando a barra de
/// filtros e os chips de filtros ativos.
class AtasListScreen extends StatefulWidget {
  const AtasListScreen({super.key});

  @override
  State<AtasListScreen> createState() => _AtasListScreenState();
}

class _AtasListScreenState extends State<AtasListScreen> {
  late final AtasListController _controller;
  late final AccessController _access;
  late final TextEditingController _empresa;
  late final TextEditingController _busca;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<AtasListController>();
    _access = AppInjector.get<AccessController>();
    _empresa = TextEditingController(text: _controller.empresaFilter.value);
    _busca = TextEditingController(text: _controller.buscaAssunto.value);
    // Busca no backend apenas na primeira entrada (lista vazia). Ao voltar para
    // a tela, reusa o que está em memória — atualizar é manual (botão/puxar)
    // ou automático via polling quando há indexação em andamento.
    if (_controller.atas.value.isEmpty) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _empresa.dispose();
    _busca.dispose();
    super.dispose();
  }

  void _applyFilters() {
    _controller.applyFilters(
      status: _controller.statusFilter.value,
      empresa: _empresa.text.trim(),
    );
  }

  void _clear() {
    _empresa.clear();
    _busca.clear();
    _controller.clearFilters();
  }

  // Remoção individual de filtros (usada pelos chips de filtros ativos).
  void _removeBusca() {
    _busca.clear();
    _controller.setBuscaAssunto('');
  }

  void _removeStatus() {
    _controller.setStatusFilter(null);
    _controller.load();
  }

  void _removeIndex() => _controller.setIndexFilter(null);

  void _removeEmpresa() {
    _empresa.clear();
    _applyFilters();
  }

  void _open(int id) => context.push(AppRoutes.teamsbotAtaDetalhePath(id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de ATAs'),
        automaticallyImplyLeading: false,
        actions: [
          SignalBuilder(builder: (context) {
            final loading = _controller.isLoading.value;
            if (loading) {
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
          // rola junto num único scroll — os filtros empilhados no mobile
          // ficam mais altos que o viewport e estouravam o Expanded da lista.
          return constraints.maxWidth >= 720 ? _wideBody() : _narrowBody();
        }),
      ),
    );
  }

  // ── Cabeçalho compartilhado (KPIs, filtros e chips de filtros ativos) ──────

  Widget _statsBar() => SignalBuilder(builder: (context) {
        final all = _controller.atas.value;
        if (all.isEmpty) return const SizedBox.shrink();
        return _StatsBar(
          atas: all,
          isAdmin: _access.isAdminSignal.value,
          indexFilter: _controller.indexFilter.value,
          onIndex: _controller.alternarIndex,
        );
      });

  Widget _filterBar() => _FilterBar(
        controller: _controller,
        empresa: _empresa,
        busca: _busca,
        onApply: _applyFilters,
        onClear: _clear,
      );

  Widget _activeFilters() => SignalBuilder(builder: (context) {
        return _ActiveFilters(
          busca: _controller.buscaAssunto.value,
          status: _controller.statusFilter.value,
          index: _controller.indexFilter.value,
          empresa: _controller.empresaFilter.value,
          onRemoveBusca: _removeBusca,
          onRemoveStatus: _removeStatus,
          onRemoveIndex: _removeIndex,
          onRemoveEmpresa: _removeEmpresa,
        );
      });

  /// Telas largas: cabeçalho fixo e a tabela ocupa o resto com rolagem própria.
  Widget _wideBody() {
    return Column(
      children: [
        _statsBar(),
        _filterBar(),
        _activeFilters(),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: SignalBuilder(builder: (context) {
              final all = _controller.atas.value;
              final visible = _controller.visibleAtas.value;
              final isLoading = _controller.isLoading.value;
              final error = _controller.error.value;

              if (isLoading && all.isEmpty) {
                return const AppLoading(message: 'Carregando ATAs…');
              }
              if (error != null && all.isEmpty) {
                return AppErrorWidget(
                  title: 'Não foi possível carregar as ATAs',
                  message: error.message,
                  onRetry: _controller.load,
                );
              }
              if (all.isEmpty) {
                return _EmptyList(onRefresh: _controller.load);
              }
              if (visible.isEmpty) {
                return _NoMatches(onClear: _clear);
              }
              return Column(
                children: [
                  _ResultCount(visible: visible.length, total: all.length),
                  Expanded(
                    child: _AtasTable(
                      atas: visible,
                      isAdmin: _access.isAdminSignal.value,
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
          SliverToBoxAdapter(child: _filterBar()),
          SliverToBoxAdapter(child: _activeFilters()),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          // Seletor de ordenação (só quando há lista visível).
          SignalBuilder(builder: (context) {
            final all = _controller.atas.value;
            final visible = _controller.visibleAtas.value;
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
                isAdmin: _access.isAdminSignal.value,
                onSort: _controller.ordenarPor,
                count: _ResultCount(visible: visible.length, total: all.length),
              ),
            );
          }),
          SignalBuilder(builder: (context) {
            final all = _controller.atas.value;
            final visible = _controller.visibleAtas.value;
            final isLoading = _controller.isLoading.value;
            final error = _controller.error.value;

            if (isLoading && all.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoading(message: 'Carregando ATAs…'),
              );
            }
            if (error != null && all.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorWidget(
                  title: 'Não foi possível carregar as ATAs',
                  message: error.message,
                  onRetry: _controller.load,
                ),
              );
            }
            if (all.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: GjaIcons.notes,
                  title: 'Nenhuma ATA encontrada',
                  subtitle: 'Gere uma nova ATA ou ajuste os filtros.',
                  actionLabel: 'Atualizar',
                  onAction: _controller.load,
                ),
              );
            }
            if (visible.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: GjaIcons.sysFind,
                  title: 'Nenhuma ATA para estes filtros',
                  subtitle: 'Ajuste a busca ou limpe os filtros.',
                  actionLabel: 'Limpar filtros',
                  onAction: _clear,
                ),
              );
            }
            final isAdmin = _access.isAdminSignal.value;
            // Padding inferior extra: reserva espaço para o FAB "Gerar ATA".
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (_, i) => _AtaListTile(
                    ata: visible[i], isAdmin: isAdmin, onOpen: _open),
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

/// Painel de indicadores derivados da lista carregada. Os cards de Indexadas,
/// Indexando e Erro funcionam como atalho de filtro (alternam ao clicar).
class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.atas,
    required this.isAdmin,
    required this.indexFilter,
    required this.onIndex,
  });

  final List<AtaResumo> atas;
  final bool isAdmin;
  final IndexStatus? indexFilter;
  final ValueChanged<IndexStatus> onIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ac = context.appColors;

    final total = atas.length;
    final indexadas =
        atas.where((a) => a.indexStatus == IndexStatus.ataIndexada).length;
    final indexando = atas.where((a) => a.indexStatus.isTransitorio).length;
    final comErro =
        atas.where((a) => a.indexStatus == IndexStatus.erroIndexacao).length;
    final custo = atas.fold<double>(0, (s, a) => s + (a.custoUsd ?? 0));

    final cards = <Widget>[
      _StatCard(
        icon: GjaIcons.notes,
        label: 'Total',
        value: '$total',
        color: cs.primary,
      ),
      _StatCard(
        icon: GjaIcons.cloudCheck,
        label: 'Indexadas',
        value: '$indexadas',
        color: ac.success,
        selected: indexFilter == IndexStatus.ataIndexada,
        onTap: () => onIndex(IndexStatus.ataIndexada),
      ),
      _StatCard(
        icon: GjaIcons.cloud,
        label: 'Indexando',
        value: '$indexando',
        color: ac.info,
        selected: indexFilter == IndexStatus.ataIndexando,
        onTap: () => onIndex(IndexStatus.ataIndexando),
      ),
      _StatCard(
        icon: GjaIcons.error,
        label: 'Com erro',
        value: '$comErro',
        color: ac.warning,
        selected: indexFilter == IndexStatus.erroIndexacao,
        onTap: () => onIndex(IndexStatus.erroIndexacao),
      ),
      // Custo de IA é informação sensível — só para administradores.
      if (isAdmin)
        _StatCard(
          icon: GjaIcons.currency,
          label: 'Custo IA',
          value: AtaFormat.custo(custo),
          color: cs.primary,
        ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: LayoutBuilder(builder: (context, constraints) {
        // Largo: cards dividem o espaço igualmente. Estreito: rolagem horizontal.
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

/// Callback de ordenação: recebe a coluna clicada e a direção pedida pela tabela.
typedef OnSort = void Function(AtaSortColumn coluna, bool ascendente);

/// Barra fina com a contagem de ATAs exibidas (e o total, quando há busca ativa).
class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.visible, required this.total});

  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final texto = visible == total
        ? '$total ${total == 1 ? 'ATA' : 'ATAs'}'
        : '$visible de $total ${total == 1 ? 'ATA' : 'ATAs'}';
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

/// Rótulos de cada coluna ordenável (compartilhados entre tabela e seletor mobile).
const Map<AtaSortColumn, String> _sortLabels = {
  AtaSortColumn.assunto: 'Assunto',
  AtaSortColumn.dataReuniao: 'Data reunião',
  AtaSortColumn.status: 'Status',
  AtaSortColumn.indexStatus: 'Indexação',
  AtaSortColumn.sharepoint: 'SharePoint',
  AtaSortColumn.versao: 'Versão',
  AtaSortColumn.custo: 'Custo IA',
  AtaSortColumn.criadoEm: 'Criado em',
};

/// Colunas visíveis da tabela, em ordem. A coluna de custo só aparece para
/// admins — por isso a tabela é dirigida por esta lista (os índices de
/// ordenação passados ao `DataTable` acompanham as colunas realmente exibidas).
List<AtaSortColumn> _tableColumns(bool isAdmin) => [
      AtaSortColumn.assunto,
      AtaSortColumn.dataReuniao,
      AtaSortColumn.status,
      AtaSortColumn.indexStatus,
      AtaSortColumn.sharepoint,
      AtaSortColumn.versao,
      if (isAdmin) AtaSortColumn.custo,
      AtaSortColumn.criadoEm,
    ];

bool _isNumeric(AtaSortColumn c) =>
    c == AtaSortColumn.versao || c == AtaSortColumn.custo;

class _AtasTable extends StatelessWidget {
  const _AtasTable({
    required this.atas,
    required this.isAdmin,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onOpen,
  });

  final List<AtaResumo> atas;
  final bool isAdmin;
  final AtaSortColumn sortColumn;
  final bool sortAscending;
  final OnSort onSort;
  final ValueChanged<int> onOpen;

  DataCell _cell(AtaResumo a, AtaSortColumn coluna) {
    return switch (coluna) {
      AtaSortColumn.assunto => DataCell(ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(a.assunto, overflow: TextOverflow.ellipsis),
        )),
      AtaSortColumn.dataReuniao => DataCell(Text(AtaFormat.data(a.dataReuniao))),
      AtaSortColumn.status => DataCell(AtaStatusBadge(status: a.status)),
      AtaSortColumn.indexStatus =>
        DataCell(IndexStatusBadge(status: a.indexStatus)),
      AtaSortColumn.sharepoint =>
        DataCell(SharePointStatusBadge(status: a.sharepointStatus)),
      AtaSortColumn.versao => DataCell(Text('v${a.versaoAta}')),
      AtaSortColumn.custo => DataCell(Text(AtaFormat.custo(a.custoUsd))),
      AtaSortColumn.criadoEm => DataCell(Text(AtaFormat.dataHora(a.criadoEm))),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final cols = _tableColumns(isAdmin);
    final sortIndex = cols.indexOf(sortColumn);

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
                for (final c in cols)
                  DataColumn(
                    label: Text(_sortLabels[c]!),
                    numeric: _isNumeric(c),
                    onSort: (columnIndex, ascending) =>
                        onSort(cols[columnIndex], ascending),
                  ),
              ],
              rows: [
                for (final a in atas)
                  DataRow(
                    onSelectChanged: (_) => onOpen(a.id),
                    cells: [for (final c in cols) _cell(a, c)],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Seletor de ordenação para telas estreitas (sem cabeçalho de coluna clicável).
class _MobileSortBar extends StatelessWidget {
  const _MobileSortBar({
    required this.column,
    required this.ascending,
    required this.isAdmin,
    required this.onSort,
    required this.count,
  });

  final AtaSortColumn column;
  final bool ascending;
  final bool isAdmin;
  final OnSort onSort;
  final Widget count;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    // Sem admin, "Custo IA" não é uma opção de ordenação.
    final opcoes = _tableColumns(isAdmin);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: count),
          Icon(GjaIcons.sort, size: 16.sp, color: cs.onSurfaceVariant),
          SizedBox(width: AppSpacing.xs),
          DropdownButtonHideUnderline(
            child: DropdownButton<AtaSortColumn>(
              value: column,
              isDense: true,
              items: [
                for (final c in opcoes)
                  DropdownMenuItem(value: c, child: Text(_sortLabels[c]!)),
              ],
              // Ao trocar de coluna, mantém a direção atual.
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

class _AtaListTile extends StatelessWidget {
  const _AtaListTile({
    required this.ata,
    required this.isAdmin,
    required this.onOpen,
  });

  final AtaResumo ata;
  final bool isAdmin;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return AppCard(
      onTap: () => onOpen(ata.id),
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ata.assunto,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('v${ata.versaoAta}',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(GjaIcons.appointment,
                  size: 14.sp, color: cs.onSurfaceVariant),
              SizedBox(width: AppSpacing.xs),
              Text(AtaFormat.data(ata.dataReuniao),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              // Custo de IA só para administradores.
              if (isAdmin) ...[
                const Spacer(),
                Icon(GjaIcons.currency,
                    size: 14.sp, color: cs.onSurfaceVariant),
                Text('IA ${AtaFormat.custo(ata.custoUsd)}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AtaStatusBadge(status: ata.status),
              IndexStatusBadge(status: ata.indexStatus),
              SharePointStatusBadge(status: ata.sharepointStatus),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados vazios
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    // ListView para permitir pull-to-refresh mesmo vazio.
    return ListView(
      children: [
        SizedBox(height: context.height * 0.15),
        AppEmptyState(
          icon: GjaIcons.notes,
          title: 'Nenhuma ATA encontrada',
          subtitle: 'Gere uma nova ATA ou ajuste os filtros.',
          actionLabel: 'Atualizar',
          onAction: onRefresh,
        ),
      ],
    );
  }
}

/// Estado exibido quando a busca/filtros não retornam nenhuma ATA da lista carregada.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: context.height * 0.15),
        AppEmptyState(
          icon: GjaIcons.sysFind,
          title: 'Nenhuma ATA para estes filtros',
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.empresa,
    required this.busca,
    required this.onApply,
    required this.onClear,
  });

  final AtasListController controller;
  final TextEditingController empresa;
  final TextEditingController busca;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final full = constraints.maxWidth;
        final buscaW = narrow ? full : 260.0;
        final fieldW = narrow ? full : 180.0;
        final dropW = narrow ? full : 190.0;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Busca por assunto: client-side e instantânea (não recarrega a lista).
            SizedBox(
              width: buscaW,
              child: SignalBuilder(builder: (context) {
                final temTexto = controller.buscaAssunto.value.isNotEmpty;
                return AppTextField(
                  label: 'Buscar assunto',
                  controller: busca,
                  prefixIcon: const Icon(GjaIcons.search, size: 18),
                  suffixIcon: temTexto
                      ? IconButton(
                          icon: const Icon(GjaIcons.decline, size: 18),
                          onPressed: () {
                            busca.clear();
                            controller.setBuscaAssunto('');
                          },
                        )
                      : null,
                  onChanged: controller.setBuscaAssunto,
                );
              }),
            ),
            SizedBox(
              width: dropW,
              child: SignalBuilder(builder: (context) {
                return _StatusDropdown(
                  value: controller.statusFilter.value,
                  onChanged: (status) {
                    controller.setStatusFilter(status);
                    onApply();
                  },
                );
              }),
            ),
            SizedBox(
              width: dropW,
              child: SignalBuilder(builder: (context) {
                return _IndexDropdown(
                  value: controller.indexFilter.value,
                  onChanged: controller.setIndexFilter,
                );
              }),
            ),
            SizedBox(
              width: fieldW,
              child: EmpresaField(
                controller: empresa,
                emptyLabel: 'Todas',
                onChanged: onApply,
              ),
            ),
            // FilledButton com tamanho fixo: o AppButton escala com o
            // screenutil e ficava gigante em monitores grandes.
            FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(GjaIcons.filter, size: 18),
              label: const Text('Filtrar'),
            ),
            SignalBuilder(builder: (context) {
              return TextButton(
                onPressed: controller.temFiltroAtivo ? onClear : null,
                child: const Text('Limpar'),
              );
            }),
          ],
        );
      }),
    );
  }
}

/// Chips dos filtros atualmente ativos, cada um removível individualmente.
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.busca,
    required this.status,
    required this.index,
    required this.empresa,
    required this.onRemoveBusca,
    required this.onRemoveStatus,
    required this.onRemoveIndex,
    required this.onRemoveEmpresa,
  });

  final String busca;
  final AtaStatus? status;
  final IndexStatus? index;
  final String empresa;
  final VoidCallback onRemoveBusca;
  final VoidCallback onRemoveStatus;
  final VoidCallback onRemoveIndex;
  final VoidCallback onRemoveEmpresa;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (busca.trim().isNotEmpty)
        _FilterChip(label: 'Busca: "$busca"', onRemove: onRemoveBusca),
      if (status != null)
        _FilterChip(label: 'Status: ${status!.label}', onRemove: onRemoveStatus),
      if (index != null)
        _FilterChip(
            label: 'Indexação: ${index!.label}', onRemove: onRemoveIndex),
      if (empresa.trim().isNotEmpty)
        _FilterChip(label: 'Empresa: $empresa', onRemove: onRemoveEmpresa),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: chips),
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

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final AtaStatus? value;
  final ValueChanged<AtaStatus?> onChanged;

  static const _opcoes = [
    AtaStatus.gerada,
    AtaStatus.reprocessada,
    AtaStatus.cancelada,
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AtaStatus?>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: const Text('Status: todos'),
        items: [
          const DropdownMenuItem<AtaStatus?>(child: Text('Status: todos')),
          for (final s in _opcoes)
            DropdownMenuItem<AtaStatus?>(value: s, child: Text(s.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _IndexDropdown extends StatelessWidget {
  const _IndexDropdown({required this.value, required this.onChanged});

  final IndexStatus? value;
  final ValueChanged<IndexStatus?> onChanged;

  static const _opcoes = [
    IndexStatus.ataIndexada,
    IndexStatus.ataIndexando,
    IndexStatus.pendenteIndexacao,
    IndexStatus.erroIndexacao,
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<IndexStatus?>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: const Text('Indexação: todas'),
        items: [
          const DropdownMenuItem<IndexStatus?>(child: Text('Indexação: todas')),
          for (final s in _opcoes)
            DropdownMenuItem<IndexStatus?>(value: s, child: Text(s.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
