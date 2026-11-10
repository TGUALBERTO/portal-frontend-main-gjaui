import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/checkin_motorista.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Confirmação da liberação: ícone grande, o que foi liberado, contagem
/// regressiva para a Home e as duas saídas manuais.
///
/// Widget puro (sem signals nem controller) — quem observa a contagem é a tela;
/// aqui só chega o número. Isso mantém o painel testável em qualquer viewport.
class CheckinSucessoPanel extends StatelessWidget {
  const CheckinSucessoPanel({
    super.key,
    required this.mode,
    required this.checkin,
    required this.segundosRestantes,
    required this.totalSegundos,
    required this.onIrParaHome,
    required this.onNovaOperacao,
  });

  final CheckinCheckoutVeiculoMode mode;

  /// Check-in liberado — usado só para exibir placa/motorista na confirmação.
  final CheckinMotorista? checkin;

  final int segundosRestantes;
  final int totalSegundos;
  final VoidCallback onIrParaHome;
  final VoidCallback onNovaOperacao;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final appColors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            padding: EdgeInsets.all(AppSpacing.ml),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appColors.successContainer ??
                  appColors.success.withValues(alpha: 0.12),
            ),
            child: Icon(
              GjaIcons.accept,
              size: 96.r,
              color: appColors.success,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          mode.sucessoTitulo,
          textAlign: TextAlign.center,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: appColors.success,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          _resumoLiberacao,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        _buildContagem(context),
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Ir agora para o início',
          isFullWidth: true,
          onPressed: onIrParaHome,
        ),
        SizedBox(height: AppSpacing.ms),
        AppButton(
          label: mode.novaOperacaoLabel,
          variant: ButtonVariant.outline,
          isFullWidth: true,
          prefixIcon: const Icon(GjaIcons.reset),
          onPressed: onNovaOperacao,
        ),
      ],
    );
  }

  /// Placa e motorista do check-in liberado — a conferência que importa para
  /// quem está na guarita.
  String get _resumoLiberacao {
    final data = checkin;
    if (data == null) return mode.sucessoLabel;
    final partes = [
      if (data.placa.isNotEmpty) data.placa,
      if (data.motorista.isNotEmpty) data.motorista,
    ];
    return partes.isEmpty ? mode.sucessoLabel : partes.join('  ·  ');
  }

  Widget _buildContagem(BuildContext context) {
    final cs = context.colors;
    final restante = segundosRestantes.clamp(0, totalSegundos);

    return Column(
      children: [
        SizedBox(
          height: 64.r,
          width: 64.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: totalSegundos == 0 ? 0 : restante / totalSegundos,
                  strokeWidth: 4,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              FittedBox(
                child: Text(
                  '$restante',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Voltando para o início automaticamente...',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
