import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/transcricao_status.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import '../format.dart';
import 'reuniao_badges.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Cartão com os metadados da transcrição (sem o conteúdo completo).
class TranscricaoCard extends StatelessWidget {
  const TranscricaoCard({super.key, required this.transcricao});

  final TranscricaoStatus transcricao;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final ac = context.appColors;
    final disponivel = transcricao.disponivel;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(GjaIcons.text, color: cs.primary, size: 20.sp),
              SizedBox(width: AppSpacing.xs),
              Text('Transcrição',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              ReuniaoStatusBadge(status: transcricao.status),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                disponivel ? GjaIcons.sysEnter2 : GjaIcons.sysMinus,
                size: 16.sp,
                color: disponivel ? ac.success : cs.onSurfaceVariant,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(disponivel ? 'Disponível' : 'Indisponível',
                  style: tt.bodyMedium),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _Info(label: 'Origem', value: transcricao.origem),
              _Info(
                  label: 'Tamanho',
                  value: formatBytes(transcricao.tamanhoBytes)),
              _Info(
                  label: 'Capturada em',
                  value: AtaFormat.dataHora(transcricao.capturadoEm)),
            ],
          ),
          if (transcricao.erro != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: AppBorders.sm,
              ),
              child: Text(transcricao.erro!,
                  style: tt.bodySmall?.copyWith(color: cs.onErrorContainer)),
            ),
          ],
        ],
      ),
    );
  }
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
        Text(label,
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            )),
        SizedBox(height: AppSpacing.xxs),
        Text((value == null || value!.isEmpty) ? '—' : value!,
            style: tt.bodyMedium),
      ],
    );
  }
}
