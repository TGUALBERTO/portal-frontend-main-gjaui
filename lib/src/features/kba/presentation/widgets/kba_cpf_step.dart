import 'package:gjamobile/src/features/kba/presentation/controllers/kba_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Etapa inicial do vínculo: explicação do fluxo + digitação do CPF.
class KbaCpfStep extends StatelessWidget {
  const KbaCpfStep({super.key, required this.controller});

  final KbaController controller;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(GjaIcons.badge, size: 56, color: cs.primary),
        SizedBox(height: AppSpacing.md),
        Text(
          'Vincule sua matrícula',
          textAlign: TextAlign.center,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Para concluir seu primeiro acesso, precisamos confirmar sua '
          'identidade e vincular sua conta à sua matrícula. Informe seu CPF '
          'para começar.',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'CPF',
          hint: '000.000.000-00',
          controller: controller.cpfController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [CpfInputFormatter()],
          autofocus: true,
          onFieldSubmitted: (_) => controller.submitCpf(),
        ),
        SignalBuilder(builder: (context) {
          final error = controller.errorSignal.value;
          if (error == null) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              error.message,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          );
        }),
        SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Continuar',
          isFullWidth: true,
          onPressed: controller.submitCpf,
        ),
      ],
    );
  }
}
