import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/module.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/modules_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/module_form_sheet.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Routed create/edit screen for a module (replaces the old bottom sheet) so
/// the action shows in the URL: /ga/modules/new and /ga/modules/:id.
class ModuleEditScreen extends StatefulWidget {
  const ModuleEditScreen({super.key, this.module, this.moduleId});

  /// Module passed via `extra` when navigating from the list (fast path).
  final Module? module;

  /// Module id from the route path; resolved against the list on a deep-link
  /// where [module] wasn't passed via `extra`.
  final String? moduleId;

  @override
  State<ModuleEditScreen> createState() => _ModuleEditScreenState();
}

class _ModuleEditScreenState extends State<ModuleEditScreen> {
  final _controller = AppInjector.get<ModulesController>();
  Module? _module;
  bool _resolving = false;
  String? _error;

  bool get _isEditing => widget.moduleId != null || widget.module != null;

  @override
  void initState() {
    super.initState();
    _module = widget.module;
    if (_module == null && widget.moduleId != null) {
      _resolve(widget.moduleId!);
    }
  }

  Future<void> _resolve(String id) async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    if (_controller.modulesSignal.value.isEmpty) {
      await _controller.load();
    }
    Module? found;
    for (final m in _controller.modulesSignal.value) {
      if (m.id == id) {
        found = m;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _module = found;
      _resolving = false;
      _error = found == null ? 'Módulo não encontrado' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: AppTopBar(
        title: _isEditing ? 'Editar módulo' : 'Novo módulo',
        onPressed: () => context.go(AppRoutes.gaModules),
      ),
      body: _resolving
          ? const AppLoading()
          : _error != null
              ? AppErrorWidget(
                  message: _error,
                  onRetry: () => _resolve(widget.moduleId!),
                )
              : ModuleFormSheet(
                  module: _module,
                  embedded: true,
                  onSubmit: _controller.save,
                  onSuccess: () => context.go(AppRoutes.gaModules),
                ),
    );
  }
}
