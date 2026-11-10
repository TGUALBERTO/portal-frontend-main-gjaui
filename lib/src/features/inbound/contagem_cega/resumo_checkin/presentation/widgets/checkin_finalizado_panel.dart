import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Confirmação de que o check-in foi encerrado, com o placar recebidas ×
/// devolvidas e a saída para o próximo check-in.
///
/// Widget puro: quem observa a sessão é a tela — aqui só chegam os textos, o
/// que mantém o painel testável em qualquer viewport.
class CheckinFinalizadoPanel extends StatelessWidget {
  const CheckinFinalizadoPanel({
    super.key,
    required this.checkin,
    required this.resumo,
    required this.onNovoCheckin,
  });

  final String checkin;

  /// "1 NF(s) recebida(s) · 1 NF(s) para devolução ao fornecedor"
  final String resumo;

  final VoidCallback onNovoCheckin;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final appColors = context.appColors;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.ml),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColors.successContainer ??
                    appColors.success.withValues(alpha: 0.12),
              ),
              child: Icon(
                GjaIcons.accept,
                size: 64.r,
                color: appColors.success,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Check-in $checkin finalizado',
              textAlign: TextAlign.center,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              resumo,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Novo Check-in',
              variant: ButtonVariant.outline,
              prefixIcon: const Icon(GjaIcons.reset),
              onPressed: onNovoCheckin,
            ),
          ],
        ),
      ),
    );
  }
}
