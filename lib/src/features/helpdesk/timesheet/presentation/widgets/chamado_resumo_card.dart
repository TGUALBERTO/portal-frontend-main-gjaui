import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado_resumo.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/tipo_vinculo.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Card de um chamado no painel do Timesheet: número, status e urgência no
/// topo, título, empresa/categoria, e os selos de vínculo com a data no rodapé.
///
/// Os selos de vínculo são o dado que o painel existe para mostrar — por isso
/// cada papel tem cor própria, para varrer a lista sem ler texto.
class ChamadoResumoCard extends StatelessWidget {
  const ChamadoResumoCard({
    super.key,
    required this.chamado,
    this.onTap,
    this.onApontar,
  });

  final ChamadoResumo chamado;

  /// Abre os detalhes do chamado.
  final VoidCallback? onTap;

  /// Abre o formulário de apontamento já com este chamado selecionado.
  final VoidCallback? onApontar;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final subtitulo = [chamado.empresaNome, chamado.categoria]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumeroBadge(origemId: chamado.origemId),
              if (chamado.statusLabel != null) ...[
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: _StatusBadge(
                    status: chamado.status,
                    label: chamado.statusLabel!,
                  ),
                ),
              ],
              const Spacer(),
              if (chamado.urgenciaLabel != null)
                _UrgenciaBadge(
                  urgencia: chamado.urgencia,
                  label: chamado.urgenciaLabel!,
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            chamado.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.titleSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitulo.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              subtitulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final vinculo in chamado.vinculos)
                      VinculoBadge(vinculo: vinculo),
                  ],
                ),
              ),
              if (chamado.dataCriacao != null) ...[
                SizedBox(width: AppSpacing.sm),
                _DataAbertura(
                  data: chamado.dataCriacao!,
                  atrasado: chamado.atrasado,
                ),
              ],
            ],
          ),
          if (onApontar != null) ...[
            SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onApontar,
                icon: const Icon(GjaIcons.fobWatch, size: 16),
                label: const Text('Apontar horas'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Selo do papel do usuário no chamado. Cor por papel, para a lista ser
/// legível de relance — é o filtro principal do painel.
class VinculoBadge extends StatelessWidget {
  const VinculoBadge({super.key, required this.vinculo});

  final TipoVinculo vinculo;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final (Color base, IconData icone) = switch (vinculo) {
      TipoVinculo.tecnico => (cs.primary, GjaIcons.wrench),
      TipoVinculo.requerente => (cs.tertiary, GjaIcons.personPlaceholder),
      TipoVinculo.observador => (cs.outline, GjaIcons.show),
    };
    return _Pill(
      background: base.withValues(alpha: 0.12),
      foreground: base,
      icon: icone,
      label: vinculo.label,
    );
  }
}

/// `#4242` — o número que o usuário reconhece e cita.
class _NumeroBadge extends StatelessWidget {
  const _NumeroBadge({required this.origemId});

  final int origemId;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return _Pill(
      background: cs.primary.withValues(alpha: 0.12),
      foreground: cs.primary,
      icon: GjaIcons.incident,
      label: '#$origemId',
      bold: true,
    );
  }
}

/// Status do GLPI: 1 Novo, 2/3 em atendimento, 4 pendente, 5/6 resolvido.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final int? status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final cs = context.colors;
    final Color base = switch (status) {
      1 => ac.info,
      2 || 3 => cs.primary,
      4 => ac.warning,
      5 || 6 => ac.success,
      _ => cs.outline,
    };
    return _Pill(
      background: base.withValues(alpha: 0.12),
      foreground: base,
      label: label,
    );
  }
}

/// Urgência do GLPI (1..5). Só destaca de "Média" para cima — pintar tudo tira
/// o sentido do destaque.
class _UrgenciaBadge extends StatelessWidget {
  const _UrgenciaBadge({required this.urgencia, required this.label});

  final int? urgencia;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final cs = context.colors;
    final Color base = switch (urgencia) {
      5 => cs.error,
      4 => ac.warning,
      3 => ac.info,
      _ => cs.outline,
    };
    return _Pill(
      background: base.withValues(alpha: 0.12),
      foreground: base,
      label: label,
    );
  }
}

/// Data de abertura; vira alerta quando o prazo de solução já venceu.
class _DataAbertura extends StatelessWidget {
  const _DataAbertura({required this.data, required this.atrasado});

  final DateTime data;
  final bool atrasado;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final cor = atrasado ? cs.error : cs.onSurfaceVariant;
    final texto = '${_dois(data.day)}/${_dois(data.month)}/${data.year % 100}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          atrasado ? GjaIcons.warning : GjaIcons.appointment,
          size: 14,
          color: cor,
        ),
        SizedBox(width: AppSpacing.xs),
        Tooltip(
          message: atrasado ? 'Prazo de solução vencido' : 'Aberto em',
          child: Text(
            texto,
            style: context.textTheme.bodySmall?.copyWith(color: cor),
          ),
        ),
      ],
    );
  }

  static String _dois(int n) => n.toString().padLeft(2, '0');
}

/// Pill de rótulo curto, no mesmo formato dos badges do card de apontamento.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.background,
    required this.foreground,
    required this.label,
    this.icon,
    this.bold = false,
  });

  final Color background;
  final Color foreground;
  final String label;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppBorders.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
