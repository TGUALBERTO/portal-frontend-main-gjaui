import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/feature.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/modules_controller.dart';
import 'package:gjamobile/src/features/access/utils/feature_icon.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Submits feature form data. Returns a failure message, or null on success.
typedef FeatureSubmit = Future<String?> Function({
  Feature? existing,
  required String code,
  required String label,
  String? iconName,
  required String moduleId,
});

/// Bottom-sheet form to create or edit a feature. Pops on success.
class FeatureFormSheet extends StatefulWidget {
  const FeatureFormSheet({
    super.key,
    this.feature,
    required this.onSubmit,
    this.onSuccess,
    this.embedded = false,
  });

  final Feature? feature;
  final FeatureSubmit onSubmit;

  /// Called after a successful submit. Defaults to popping (bottom-sheet usage);
  /// the routed screen passes a `go` back to the list instead.
  final VoidCallback? onSuccess;

  /// When true, drops the bottom-sheet chrome (rounded container + heading) so
  /// the form can be hosted inside a full routed screen.
  final bool embedded;

  @override
  State<FeatureFormSheet> createState() => _FeatureFormSheetState();
}

class _FeatureFormSheetState extends State<FeatureFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _modules = AppInjector.get<ModulesController>();
  late final TextEditingController _code;
  late final TextEditingController _label;
  late final TextEditingController _icon;
  String? _moduleId;
  bool _saving = false;

  bool get _isEditing => widget.feature != null;

  @override
  void initState() {
    super.initState();
    final f = widget.feature;
    _code = TextEditingController(text: f?.code ?? '');
    _label = TextEditingController(text: f?.label ?? '');
    _icon = TextEditingController(text: f?.iconName ?? '');
    _moduleId = f?.module.id;
    if (_modules.modulesSignal.value.isEmpty) {
      _modules.load();
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    _icon.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final icon = _icon.text.trim();
    final error = await widget.onSubmit(
      existing: widget.feature,
      code: _code.text.trim(),
      label: _label.text.trim(),
      iconName: icon.isEmpty ? null : icon,
      moduleId: _moduleId!,
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
                  _isEditing ? 'Editar funcionalidade' : 'Nova funcionalidade',
                  style: context.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                label: 'Código',
                hint: 'ex.: relatorios',
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
                hint: 'ex.: Relatórios',
                controller: _label,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Informe um rótulo';
                  if (value.length > 120) return 'Máximo de 120 caracteres';
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),
              _buildIconField(context),
              SizedBox(height: AppSpacing.md),
              _buildModuleField(context),
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

  Future<void> _openIconCatalog() async {
    final uri = Uri.parse('https://fonts.google.com/icons');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showToast(context, message: 'Não foi possível abrir o catálogo',
          status: 'error');
    }
  }

  Widget _buildIconField(BuildContext context) {
    final cs = context.colors;
    final name = _icon.text.trim();
    final known = isKnownFeatureIcon(name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Ícone',
          hint: 'ex.: home, settings, account_circle',
          controller: _icon,
          onChanged: (_) => setState(() {}),
          prefixIcon: Icon(iconForFeature(name), color: cs.primary),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                name.isEmpty
                    ? 'Nome do ícone (Material Symbols, estilo outlined)'
                    : known
                        ? 'Ícone encontrado'
                        : 'Ícone não encontrado — verifique o nome',
                style: context.textTheme.bodySmall?.copyWith(
                  color: name.isEmpty || known ? cs.onSurfaceVariant : cs.error,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _openIconCatalog,
              icon: const Icon(GjaIcons.popupWindow, size: 16),
              label: const Text('Catálogo'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleField(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final status = _modules.statusSignal.value;
      final modules = _modules.modulesSignal.value;

      if (modules.isEmpty &&
          (status == AdminStatus.loading || status == AdminStatus.idle)) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        );
      }
      if (modules.isEmpty && status == AdminStatus.error) {
        return Row(
          children: [
            Expanded(
              child: Text(
                'Falha ao carregar módulos',
                style: context.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: _modules.load,
              child: const Text('Tentar de novo'),
            ),
          ],
        );
      }

      final ids = modules.map((m) => m.id).toSet();
      final value =
          (_moduleId != null && ids.contains(_moduleId)) ? _moduleId : null;
      return DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          isDense: true,
          labelText: 'Módulo',
        ),
        items: [
          for (final m in modules)
            DropdownMenuItem<String>(
              value: m.id,
              child: Text(m.label),
            ),
        ],
        validator: (v) => v == null ? 'Selecione um módulo' : null,
        onChanged: (v) => setState(() => _moduleId = v),
      );
    });
  }
}
