import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Dados do vínculo manual escolhidos pelo admin no [KbaLinkSheet].
typedef KbaLinkInput = ({int codigoEmpresa, int matricula});

/// Abre o formulário de vínculo manual de matrícula (revisão manual).
/// Retorna os valores confirmados ou null quando cancelado.
Future<KbaLinkInput?> showKbaLinkSheet(PortalUser user) {
  return showAppSheet<KbaLinkInput>(child: KbaLinkSheet(user: user));
}

/// Formulário: código da empresa + matrícula do funcionário a vincular.
/// O backend valida que o par existe em funcionarios_fpw e também desbloqueia
/// o usuário.
class KbaLinkSheet extends StatefulWidget {
  const KbaLinkSheet({super.key, required this.user});

  final PortalUser user;

  @override
  State<KbaLinkSheet> createState() => _KbaLinkSheetState();
}

class _KbaLinkSheetState extends State<KbaLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codigoEmpresaController = TextEditingController();
  final _matriculaController = TextEditingController();

  @override
  void dispose() {
    _codigoEmpresaController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      codigoEmpresa: int.parse(_codigoEmpresaController.text.trim()),
      matricula: int.parse(_matriculaController.text.trim()),
    ));
  }

  String? _requiredInt(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Obrigatório';
    if (int.tryParse(v) == null) return 'Somente números';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.bottomSheet,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vincular matrícula',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Vínculo manual (revisão) para ${widget.user.displayName}. '
              'A matrícula é validada na base de funcionários e o usuário é '
              'desbloqueado automaticamente.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Código da empresa',
              controller: _codigoEmpresaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _requiredInt,
              autofocus: true,
            ),
            SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Matrícula',
              controller: _matriculaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _requiredInt,
              onFieldSubmitted: (_) => _confirm(),
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Vincular',
              isFullWidth: true,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
