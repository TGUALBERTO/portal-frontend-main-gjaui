import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/presentation/controllers/consulta_historico_controller.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/markdown_view.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela full-screen — histórico de consultas RAG do usuário logado
/// (`/teamsbot/consultar/historico`).
///
/// Segue o padrão das demais telas do TeamsBot: indicadores no topo, busca
/// instantânea, contador de resultados e layout responsivo.
class ConsultaHistoricoScreen extends StatefulWidget {
  const ConsultaHistoricoScreen({super.key});

  @override
  State<ConsultaHistoricoScreen> createState() =>
      _ConsultaHistoricoScreenState();
}

class _ConsultaHistoricoScreenState extends State<ConsultaHistoricoScreen> {
  late final ConsultaHistoricoController _controller;
  late final String _usuarioId;
  late final TextEditingController _busca;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<ConsultaHistoricoController>();
    _usuarioId = AppInjector.get<SessionController>().user?.id ?? '';
    _busca = TextEditingController(text: _controller.busca.value);
    _controller.load(_usuarioId);
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _limparBusca() {
    _busca.clear();
    _controller.setBusca('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas consultas'),
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
        child: SignalBuilder(builder: (context) {
          final all = _controller.itens.value;
          final visible = _controller.visibleItens.value;
          final isLoading = _controller.isLoading.value;
          final error = _controller.error.value;
          final maisRecentes = _controller.maisRecentesPrimeiro.value;

          if (_usuarioId.isEmpty) {
            return const AppEmptyState(
              icon: GjaIcons.employeeRejections,
              title: 'Usuário não identificado',
              subtitle: 'Entre novamente para ver o seu histórico de consultas.',
            );
          }
          if (isLoading && all.isEmpty) {
            return const AppLoading(message: 'Carregando suas consultas…');
          }
          if (error != null && all.isEmpty) {
            return AppErrorWidget(
              title: 'Não foi possível carregar o histórico',
              message: error.message,
              onRetry: () => _controller.load(_usuarioId),
            );
          }
          if (all.isEmpty) {
            return const AppEmptyState(
              icon: GjaIcons.history,
              title: 'Nenhuma consulta ainda',
              subtitle:
                  'As perguntas que você fizer na aba Consultar aparecem aqui.',
            );
          }

          return Column(
            children: [
              _StatsBar(itens: all),
              _BuscaBar(
                busca: _busca,
                controller: _controller,
                onClear: _limparBusca,
              ),
              _ResultBar(
                visible: visible.length,
                total: all.length,
                maisRecentes: maisRecentes,
                onToggleOrdem: _controller.alternarOrdem,
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: visible.isEmpty
                      ? _NoMatches(onClear: _limparBusca)
                      : ListView.separated(
                          padding: EdgeInsets.all(AppSpacing.md),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) =>
                              _ConsultaTile(item: visible[index]),
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicadores (KPIs)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.itens});

  final List<ConsultaHistoricoItem> itens;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ac = context.appColors;

    final total = itens.length;
    final corte = DateTime.now().subtract(const Duration(days: 7));
    final recentes = itens
        .where((e) => e.criadoEm != null && e.criadoEm!.isAfter(corte))
        .length;
    final atasCitadas = itens
        .expand((e) => e.fontes)
        .map((f) => f.ataId)
        .whereType<int>()
        .toSet()
        .length;

    final cards = <Widget>[
      _StatCard(
        icon: GjaIcons.comment,
        label: 'Consultas',
        value: '$total',
        color: cs.primary,
      ),
      _StatCard(
        icon: GjaIcons.calendar,
        label: 'Últimos 7 dias',
        value: '$recentes',
        color: ac.info,
      ),
      _StatCard(
        icon: GjaIcons.documentText,
        label: 'ATAs citadas',
        value: '$atasCitadas',
        color: ac.success,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
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
                SizedBox(width: 148, child: cards[i]),
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: AppBorders.md,
            ),
            child: Icon(icon, size: 16.sp, color: color),
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
// Busca e contagem
// ─────────────────────────────────────────────────────────────────────────────

class _BuscaBar extends StatelessWidget {
  const _BuscaBar({
    required this.busca,
    required this.controller,
    required this.onClear,
  });

  final TextEditingController busca;
  final ConsultaHistoricoController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: SignalBuilder(builder: (context) {
        final temTexto = controller.busca.value.isNotEmpty;
        return AppTextField(
          label: 'Buscar nas perguntas e respostas',
          controller: busca,
          prefixIcon: const Icon(GjaIcons.search, size: 18),
          suffixIcon: temTexto
              ? IconButton(
                  icon: const Icon(GjaIcons.decline, size: 18),
                  onPressed: onClear,
                )
              : null,
          onChanged: controller.setBusca,
        );
      }),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.visible,
    required this.total,
    required this.maisRecentes,
    required this.onToggleOrdem,
  });

  final int visible;
  final int total;
  final bool maisRecentes;
  final VoidCallback onToggleOrdem;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final texto = visible == total
        ? '$total ${total == 1 ? 'consulta' : 'consultas'}'
        : '$visible de $total consultas';

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(texto,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          TextButton.icon(
            onPressed: onToggleOrdem,
            icon: Icon(
              maisRecentes ? GjaIcons.arrowBottom : GjaIcons.arrowTop,
              size: 16,
            ),
            label: Text(maisRecentes ? 'Mais recentes' : 'Mais antigas'),
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
          title: 'Nenhuma consulta para esta busca',
          subtitle: 'Ajuste o texto buscado ou limpe a busca.',
          actionLabel: 'Limpar busca',
          onAction: onClear,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item do histórico
// ─────────────────────────────────────────────────────────────────────────────

class _ConsultaTile extends StatelessWidget {
  const _ConsultaTile({required this.item});

  final ConsultaHistoricoItem item;

  Future<void> _copiarResposta() async {
    await Clipboard.setData(ClipboardData(text: item.resposta));
    showGlobalToast(message: 'Resposta copiada.', status: 'success');
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    final subtitulo = [
      AtaFormat.dataHora(item.criadoEm),
      if (item.fontes.isNotEmpty)
        '${item.fontes.length} ${item.fontes.length == 1 ? 'fonte' : 'fontes'}',
    ].join('  ·  ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(GjaIcons.comment),
        title: Text(
          item.pergunta,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitulo,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        childrenPadding:
            EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.filtros.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final entry in item.filtros.entries)
                  // Cores explícitas do scheme para funcionar no tema escuro.
                  Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    labelStyle: tt.bodySmall?.copyWith(color: cs.onSurface),
                    backgroundColor: cs.surfaceContainerHigh,
                    side: BorderSide(color: cs.outlineVariant),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
          ],
          AppCard(
            color: cs.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(GjaIcons.ai,
                        size: 16.sp, color: cs.onPrimaryContainer),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text('Resposta',
                          style: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer,
                          )),
                    ),
                    IconButton(
                      tooltip: 'Copiar resposta',
                      icon: Icon(GjaIcons.copy,
                          size: 16.sp, color: cs.onPrimaryContainer),
                      onPressed: _copiarResposta,
                    ),
                  ],
                ),
                MarkdownView(data: item.resposta),
              ],
            ),
          ),
          if (item.fontes.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text('Fontes (${item.fontes.length})',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final fonte in item.fontes)
                  // Cores explícitas do scheme para funcionar no tema escuro.
                  ActionChip(
                    avatar: Icon(GjaIcons.documentText,
                        size: 16, color: cs.primary),
                    label: Text(fonte.ataId == null
                        ? fonte.secao
                        : 'ATA #${fonte.ataId} — ${fonte.secao}'),
                    labelStyle: tt.bodySmall?.copyWith(color: cs.onSurface),
                    backgroundColor: cs.surfaceContainerHigh,
                    side: BorderSide(color: cs.outlineVariant),
                    visualDensity: VisualDensity.compact,
                    onPressed: fonte.ataId == null
                        ? null
                        : () => context.push(
                            AppRoutes.teamsbotAtaDetalhePath(fonte.ataId!)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
