import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/apontamento_acoes.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Card de um apontamento (tarefa de chamado): pill do chamado + duração em
/// destaque no topo, descrição limpa e período no rodapé. Usado nas visões
/// diária e semanal do Timesheet.
///
/// No hover surgem os ícones de duplicar e excluir ao lado da duração; no
/// toque, as mesmas ações saem pela pressão longa / botão direito.
class ApontamentoCard extends StatefulWidget {
  const ApontamentoCard({
    super.key,
    required this.apontamento,
    this.tituloChamado,
    this.onTap,
    this.onDuplicate,
    this.onDelete,
  });

  final Apontamento apontamento;

  /// Título do chamado ao qual o apontamento pertence (nulo = não resolvido).
  final String? tituloChamado;

  /// Abre a edição do apontamento; nulo deixa o card apenas informativo.
  final VoidCallback? onTap;

  /// Ações rápidas (hover e menu). Nulas escondem a ação correspondente.
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  State<ApontamentoCard> createState() => _ApontamentoCardState();
}

class _ApontamentoCardState extends State<ApontamentoCard> {
  bool _hovering = false;

  /// O menu rouba o ponteiro e dispara o `onExit`; sem isto os ícones sumiriam
  /// no meio da interação.
  bool _menuOpen = false;

  bool get _temAcoes => widget.onDuplicate != null || widget.onDelete != null;

  bool get _mostrarAcoes => _temAcoes && (_hovering || _menuOpen);

  Future<void> _abrirMenu(Offset globalPosition) async {
    if (!_temAcoes) return;
    final position = apontamentoMenuPosition(context, globalPosition);
    setState(() => _menuOpen = true);
    final acao = await showApontamentoMenu(
      context,
      position: position,
      podeDuplicar: widget.onDuplicate != null,
      podeExcluir: widget.onDelete != null,
    );
    // O dia pode ter recarregado com o menu aberto.
    if (!mounted) return;
    setState(() => _menuOpen = false);
    switch (acao) {
      case ApontamentoAcao.duplicar:
        widget.onDuplicate?.call();
      case ApontamentoAcao.excluir:
        widget.onDelete?.call();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final apontamento = widget.apontamento;
    final content = apontamento.contentPlain;
    final titulo = widget.tituloChamado?.trim();
    final periodo = _periodoLabel();

    final card = AppCard(
      onTap: widget.onTap,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: chamado + estado (esq.) e duração como herói (dir.).
          Row(
            children: [
              _ChamadoBadge(chamado: apontamento.chamadoId),
              if (apontamento.estado.label != null) ...[
                SizedBox(width: AppSpacing.sm),
                _EstadoBadge(estado: apontamento.estado),
              ],
              const Spacer(),
              SizedBox(width: AppSpacing.sm),
              _DuracaoPill(duration: apontamento.duration),
              if (_temAcoes)
                _CardActions(
                  visible: _mostrarAcoes,
                  onDuplicate: widget.onDuplicate,
                  onDelete: widget.onDelete,
                ),
            ],
          ),
          if (titulo != null && titulo.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (content.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (periodo != null) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(GjaIcons.pending,
                    size: 14, color: cs.onSurfaceVariant),
                SizedBox(width: AppSpacing.xs),
                Text(
                  periodo,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // A pressão longa / botão direito é o caminho das mesmas ações no toque.
    // O `onTap` do `AppCard` é descendente e continua vencendo a arena.
    final gesturas = GestureDetector(
      onLongPressStart: (d) => _abrirMenu(d.globalPosition),
      onSecondaryTapDown: (d) => _abrirMenu(d.globalPosition),
      child: card,
    );

    final interativo = _temAcoes
        ? MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: gesturas,
          )
        : gesturas;

    if (content.isEmpty) return interativo;
    // Com as ações à mostra o tooltip cobriria os próprios ícones.
    return Tooltip(
      message: _mostrarAcoes ? '' : content,
      waitDuration: AppDurations.normal,
      child: interativo,
    );
  }

  /// "14:00 – 15:30" (início–fim), senão "às 14:00" (data), senão `null`.
  String? _periodoLabel() {
    final ini = widget.apontamento.beginDate;
    final fim = widget.apontamento.endDate;
    if (ini != null && fim != null) return '${timeHm(ini)} – ${timeHm(fim)}';
    final hora = widget.apontamento.data;
    if (hora != null) return 'às ${timeHm(hora)}';
    return null;
  }
}

/// Ícones de ação do card, revelados no hover.
///
/// O espaço fica **sempre reservado** (só a opacidade muda): num card dentro
/// de uma lista, um reflow a cada hover é bem mais incômodo que o espaço
/// ocioso — diferente do bloco da agenda, que é posicionado e não empurra
/// nada.
class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.visible,
    required this.onDuplicate,
    required this.onDelete,
  });

  final bool visible;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppDurations.microInteraction,
        curve: AppCurves.standard,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDuplicate != null)
              IconButton(
                onPressed: onDuplicate,
                tooltip: 'Duplicar',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: const Icon(GjaIcons.copy),
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                tooltip: 'Excluir',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                color: context.colors.error,
                icon: const Icon(GjaIcons.delete),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pill do chamado ao qual o apontamento pertence (`#1234`).
class _ChamadoBadge extends StatelessWidget {
  const _ChamadoBadge({required this.chamado});

  final int? chamado;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: AppBorders.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(GjaIcons.incident,
              size: 14, color: cs.primary),
          SizedBox(width: AppSpacing.xs),
          Text(
            chamado != null ? '#$chamado' : 'Tarefa',
            style: context.textTheme.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge do estado da tarefa: verde (concluída) ou amarelo (pendente).
class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final TarefaEstado estado;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final (Color bg, Color fg) = switch (estado) {
      TarefaEstado.concluida => (ac.success, ac.onSuccess),
      TarefaEstado.pendente => (ac.warning, ac.onWarning),
      TarefaEstado.nenhum => (ac.info, ac.onInfo), // não exibido (label nulo)
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorders.full,
      ),
      child: Text(
        estado.label ?? '',
        style: context.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tempo apontado, em destaque (o dado-chave de um timesheet).
class _DuracaoPill extends StatelessWidget {
  const _DuracaoPill({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: AppBorders.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(GjaIcons.fobWatch, size: 14, color: cs.onPrimary),
          SizedBox(width: AppSpacing.xs),
          Text(
            durationLabel(duration),
            style: context.textTheme.labelMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
