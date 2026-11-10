import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/catraca_acesso.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/apontamento_card.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Visão diária do Timesheet: passagens na catraca (horas trabalhadas) e
/// apontamentos de tarefas em chamados, ambos em ordem cronológica.
class TimesheetDayView extends StatelessWidget {
  const TimesheetDayView({
    super.key,
    required this.day,
    required this.acessos,
    required this.total,
    required this.apontamentos,
    required this.apontado,
    required this.titulosChamados,
    required this.onRefresh,
    this.onApontamentoTap,
    this.onApontamentoDuplicate,
    this.onApontamentoDelete,
  });

  final DateTime day;

  /// Marcações do dia em ordem crescente de horário.
  final List<CatracaAcesso> acessos;

  /// Horas trabalhadas (pares entrada→saída).
  final Duration total;

  /// Apontamentos de tarefas do dia em ordem crescente de horário.
  final List<Apontamento> apontamentos;

  /// Tempo total apontado no dia (soma de `actiontime`).
  final Duration apontado;

  /// Títulos dos chamados (`ticketsId → titulo`), quando resolvidos.
  final Map<int, String> titulosChamados;

  final Future<void> Function() onRefresh;

  /// Abre a edição de um apontamento. Nulo (ou apontamento sem id) deixa o
  /// card apenas informativo.
  final ValueChanged<Apontamento>? onApontamentoTap;

  /// Ações rápidas do card (hover / menu). Nulas escondem a ação.
  final ValueChanged<Apontamento>? onApontamentoDuplicate;
  final ValueChanged<Apontamento>? onApontamentoDelete;

  @override
  Widget build(BuildContext context) {
    if (acessos.isEmpty && apontamentos.isEmpty) {
      return AppEmptyState(
        icon: GjaIcons.timeOff,
        title: 'Sem registros',
        subtitle: 'Nenhuma passagem de catraca ou apontamento em '
            '${dayLabelPt(day)}.',
      );
    }

    final children = <Widget>[];

    if (acessos.isNotEmpty) {
      children.add(
        _SummaryCard(
          icon: GjaIcons.pending,
          label: '${acessos.length} '
              '${acessos.length == 1 ? 'marcação' : 'marcações'}',
          value: durationLabel(total),
        ),
      );
      for (final acesso in acessos) {
        children.add(SizedBox(height: AppSpacing.sm));
        children.add(_AcessoTile(acesso: acesso));
      }
    }

    if (apontamentos.isNotEmpty) {
      if (children.isNotEmpty) children.add(SizedBox(height: AppSpacing.md));
      children.add(
        _SummaryCard(
          icon: GjaIcons.task,
          label: '${apontamentos.length} '
              '${apontamentos.length == 1 ? 'apontamento' : 'apontamentos'}',
          value: durationLabel(apontado),
        ),
      );
      for (final ap in apontamentos) {
        children.add(SizedBox(height: AppSpacing.sm));
        final onTap = onApontamentoTap;
        final onDuplicate = onApontamentoDuplicate;
        final onDelete = onApontamentoDelete;
        // Sem id não há o que editar nem excluir (o id vem de
        // `_links.self.href`).
        final semId = ap.id == null;
        children.add(ApontamentoCard(
          apontamento: ap,
          tituloChamado: titulosChamados[ap.chamadoId],
          onTap: onTap == null || semId ? null : () => onTap(ap),
          onDuplicate:
              onDuplicate == null || semId ? null : () => onDuplicate(ap),
          onDelete: onDelete == null || semId ? null : () => onDelete(ap),
        ));
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

/// Card de resumo de uma seção (rótulo à esquerda, total à direita).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: context.colors.primary),
          SizedBox(width: AppSpacing.ms),
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcessoTile extends StatelessWidget {
  const _AcessoTile({required this.acesso});

  final CatracaAcesso acesso;

  @override
  Widget build(BuildContext context) {
    final isEntrada = acesso.tipoAcesso.isEntrada;
    final color = isEntrada ? context.appColors.success : context.colors.error;

    final card = AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              acesso.isRefeitorio
                  ? GjaIcons.meal
                  : (isEntrada ? GjaIcons.journeyArrive : GjaIcons.log),
              size: 20,
              color: color,
            ),
          ),
          SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              acesso.tipoAcesso.label,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            timeHms(acesso.data),
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (acesso.catraca.isEmpty) return card;
    return Tooltip(message: acesso.catraca, child: card);
  }
}
