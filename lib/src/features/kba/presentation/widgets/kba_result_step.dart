import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Telas terminais do fluxo KBA: sucesso, bloqueado, CPF não encontrado e
/// cadastro sem dados suficientes.
class KbaResultStep extends StatelessWidget {
  const KbaResultStep._({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.showLogout = false,
  });

  factory KbaResultStep.success(BuildContext context) => KbaResultStep._(
        icon: GjaIcons.verified,
        iconColor: context.colors.primary,
        title: 'Matrícula vinculada!',
        message: 'Sua conta foi vinculada com sucesso. '
            'Você já pode usar o portal.',
        primaryLabel: 'Ir para o início',
        onPrimary: () => appRouter.go(AppRoutes.home),
      );

  factory KbaResultStep.blocked() => const KbaResultStep._(
        icon: GjaIcons.locked,
        iconColor: null,
        title: 'Não foi possível confirmar sua identidade',
        message: 'O limite de tentativas foi atingido. O desbloqueio é feito '
            'por análise manual — entre em contato com a equipe responsável.',
        showLogout: true,
      );

  factory KbaResultStep.cpfNotFound({required VoidCallback onRetry}) =>
      KbaResultStep._(
        icon: GjaIcons.sysFind,
        iconColor: null,
        title: 'CPF não localizado',
        message: 'Não encontramos seu CPF na base de funcionários. Procure a '
            'equipe responsável para regularização cadastral ou tente '
            'novamente.',
        primaryLabel: 'Tentar novamente',
        onPrimary: onRetry,
        showLogout: true,
      );

  factory KbaResultStep.insufficientData() => const KbaResultStep._(
        icon: GjaIcons.headset,
        iconColor: null,
        title: 'Vínculo manual necessário',
        message: 'Seu cadastro não possui dados suficientes para a validação '
            'automática. Procure a equipe responsável para concluir o vínculo.',
        showLogout: true,
      );

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool showLogout;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 56, color: iconColor ?? cs.onSurfaceVariant),
        SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: AppSpacing.xl),
        if (primaryLabel != null)
          AppButton(
            label: primaryLabel!,
            isFullWidth: true,
            onPressed: onPrimary,
          ),
        if (showLogout) ...[
          if (primaryLabel != null) SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Sair da conta',
            isFullWidth: true,
            variant: ButtonVariant.outline,
            onPressed: () => AppInjector.get<SessionController>().logout(),
          ),
        ],
      ],
    );
  }
}
