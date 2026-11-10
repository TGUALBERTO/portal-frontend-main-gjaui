import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/atas/data/models/ata_detalhe.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/status_pill.dart';
import 'status_badges.dart';

/// Painel de metadados de uma ATA exibido no topo do detalhe.
class AtaMetadataPanel extends StatelessWidget {
  const AtaMetadataPanel({
    super.key,
    required this.detalhe,
    this.isAdmin = false,
  });

  final AtaDetalhe detalhe;

  /// Custo de IA é informação sensível — só exibido para administradores.
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AtaStatusBadge(status: detalhe.status),
              IndexStatusBadge(status: detalhe.indexStatus),
              SharePointStatusBadge(status: detalhe.sharepointStatus),
              StatusPill(
                label: 'v${detalhe.versaoAta}',
                background: cs.secondaryContainer,
                foreground: cs.onSecondaryContainer,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            detalhe.assunto,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Organizador: ${detalhe.organizador.isEmpty ? '—' : detalhe.organizador}',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _Info(label: 'Empresa', value: detalhe.empresa),
              _Info(
                  label: 'Data da reunião',
                  value: AtaFormat.dataExtensa(detalhe.dataReuniao)),
              _Info(
                label: 'Horário',
                value: detalhe.inicio == null
                    ? '—'
                    : '${AtaFormat.hora(detalhe.inicio)} – ${AtaFormat.hora(detalhe.fim)}',
              ),
              _Info(
                  label: 'Criado em',
                  value: AtaFormat.dataHora(detalhe.criadoEm)),
              _Info(
                  label: 'Atualizado em',
                  value: AtaFormat.dataHora(detalhe.atualizadoEm)),
              if (isAdmin)
                _Info(
                    label: 'Custo IA',
                    value: AtaFormat.custo(detalhe.custoUsd)),
            ],
          ),
          if (detalhe.participantes.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text('Participantes', style: _labelStyle(context)),
            SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in detalhe.participantes)
                  // Cores explícitas do scheme para funcionar no tema escuro.
                  Chip(
                    label: Text(p),
                    labelStyle:
                        tt.bodySmall?.copyWith(color: cs.onSurface),
                    backgroundColor: cs.surfaceContainerHigh,
                    side: BorderSide(color: cs.outlineVariant),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
          if (detalhe.joinUrl.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text('Link da reunião', style: _labelStyle(context)),
            SizedBox(height: AppSpacing.xxs),
            SelectableText(
              detalhe.joinUrl,
              style: tt.bodySmall?.copyWith(color: cs.primary),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) =>
      context.textTheme.labelMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          (value == null || value!.isEmpty) ? '—' : value!,
          style: tt.bodyMedium,
        ),
      ],
    );
  }
}
