import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/module.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/modules_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/module_list_tile.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

class ModulesListScreen extends StatefulWidget {
  const ModulesListScreen({super.key});

  @override
  State<ModulesListScreen> createState() => _ModulesListScreenState();
}

class _ModulesListScreenState extends State<ModulesListScreen> {
  final _controller = AppInjector.get<ModulesController>();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  Future<void> _onDelete(Module module) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir módulo',
      message: 'Deseja excluir "${module.label}"?',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    final error = await _controller.delete(module.id);
    if (!mounted) return;
    showToast(
      context,
      message: error ?? 'Módulo excluído',
      status: error == null ? 'success' : 'error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      scrollable: false,
      appBar: AppTopBar(
        title: 'Módulos',
        actions: [
          IconButton(
            tooltip: 'Novo módulo',
            icon: const Icon(GjaIcons.add),
            onPressed: () => context.go(AppRoutes.gaModuleNew),
          ),
        ],
      ),
      body: SignalBuilder(builder: (context) {
        final status = _controller.statusSignal.value;
        final modules = _controller.modulesSignal.value;

        if (status == AdminStatus.loading || status == AdminStatus.idle) {
          return const AppLoading();
        }
        if (status == AdminStatus.error) {
          return AppErrorWidget(
            message: _controller.errorSignal.value?.message,
            onRetry: _controller.load,
          );
        }
        if (modules.isEmpty) {
          return AppEmptyState(
            icon: GjaIcons.overviewChart,
            title: 'Nenhum módulo',
            subtitle: 'Crie um módulo para começar.',
            actionLabel: 'Novo módulo',
            onAction: () => context.go(AppRoutes.gaModuleNew),
          );
        }
        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView.separated(
            itemCount: modules.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final module = modules[i];
              return ModuleListTile(
                module: module,
                onEdit: () => context.go(
                  AppRoutes.gaModuleEditPath(module.id),
                  extra: module,
                ),
                onDelete: () => _onDelete(module),
              );
            },
          ),
        );
      }),
    );
  }
}
