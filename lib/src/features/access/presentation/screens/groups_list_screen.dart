import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/groups_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/group_list_tile.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  final _controller = AppInjector.get<GroupsController>();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  // `go` (não `push`) para a URL refletir a sub-rota (/ga/groups/new e
  // /ga/groups/:id) — push imperativo não atualiza a barra de endereço. Não
  // precisa await + load: ao voltar para /ga/groups esta tela é remontada e o
  // initState chama _controller.load() (GroupsController é singleton, então o
  // upsertLocal feito no save também já reflete na lista).
  void _onNew() => context.go(AppRoutes.gaGroupNew);

  void _onEdit(AccessGroup group) =>
      context.go(AppRoutes.gaGroupEditPath(group.id), extra: group);

  Future<void> _onDelete(AccessGroup group) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir grupo',
      message: 'Deseja excluir o grupo "${group.name}"?',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    final error = await _controller.delete(group.id);
    if (!mounted) return;
    showToast(
      context,
      message: error ?? 'Grupo excluído',
      status: error == null ? 'success' : 'error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      scrollable: false,
      appBar: AppTopBar(
        title: 'Grupos',
        actions: [
          IconButton(
            tooltip: 'Novo grupo',
            icon: const Icon(GjaIcons.add),
            onPressed: _onNew,
          ),
        ],
      ),
      body: SignalBuilder(builder: (context) {
        final status = _controller.statusSignal.value;
        final groups = _controller.groupsSignal.value;

        if (status == AdminStatus.loading || status == AdminStatus.idle) {
          return const AppLoading();
        }
        if (status == AdminStatus.error) {
          return AppErrorWidget(
            message: _controller.errorSignal.value?.message,
            onRetry: _controller.load,
          );
        }
        if (groups.isEmpty) {
          return AppEmptyState(
            icon: GjaIcons.group,
            title: 'Nenhum grupo',
            subtitle: 'Crie um grupo para começar.',
            actionLabel: 'Novo grupo',
            onAction: _onNew,
          );
        }
        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final group = groups[i];
              return GroupListTile(
                group: group,
                onTap: () => _onEdit(group),
                onDelete: () => _onDelete(group),
              );
            },
          ),
        );
      }),
    );
  }
}
