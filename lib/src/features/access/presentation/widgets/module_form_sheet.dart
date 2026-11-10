import 'package:gjamobile/src/features/access/domain/entities/module.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Submits module form data. Returns a failure message, or null on success.
typedef ModuleSubmit = Future<String?> Function({
  Module? existing,
  required String code,
  required String label,
});

/// Bottom-sheet form to create or edit a module. Pops on success.
class ModuleFormSheet extends StatefulWidget {
  const ModuleFormSheet({
    super.key,
    this.module,
    required this.onSubmit,
    this.onSuccess,
    this.embedded = false,
  });

  final Module? module;
  final ModuleSubmit onSubmit;

  /// Called after a successful submit. Defaults to popping (bottom-sheet usage);
  /// the routed screen passes a `go` back to the list instead.
  final VoidCallback? onSuccess;

  /// When true, drops the bottom-sheet chrome (rounded container + heading) so
  /// the form can be hosted inside a full routed screen.
  final bool embedded;

  @override
  State<ModuleFormSheet> createState() => _ModuleFormSheetState();
}

class _ModuleFormSheetState extends State<ModuleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _label;
  bool _saving = false;

  bool get _isEditing => widget.module != null;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.module?.code ?? '');
    _label = TextEditingController(text: widget.module?.label ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final error = await widget.onSubmit(
      existing: widget.module,
      code: _code.text.trim(),
      label: _label.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      (widget.onSuccess ?? () => Navigator.of(context).pop())();
    } else {
      showToast(context, message: error, status: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      decoration: widget.embedded
          ? null
          : BoxDecoration(
              color: cs.surface,
              borderRadius: AppBorders.bottomSheet,
            ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md +
            (widget.embedded ? 0 : MediaQuery.viewInsetsOf(context).bottom),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.embedded) ...[
                Text(
                  _isEditing ? 'Editar módulo' : 'Novo módulo',
                  style: context.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                label: 'Código',
                hint: 'ex.: RH',
                controller: _code,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Informe um código';
                  if (value.length > 80) return 'Máximo de 80 caracteres';
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Rótulo',
                hint: 'ex.: Recursos Humanos (RH)',
                controller: _label,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Informe um rótulo';
                  if (value.length > 120) return 'Máximo de 120 caracteres';
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Salvar',
                isFullWidth: true,
                isLoading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
