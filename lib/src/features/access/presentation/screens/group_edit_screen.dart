import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/domain/entities/user_group_summary.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/group_edit_controller.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/groups_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/add_member_sheet.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/group_form_section.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/group_members_section.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/permission_matrix.dart';
import 'package:gjamobile/src/imports/imports.dart';

class GroupEditScreen extends StatefulWidget {
  const GroupEditScreen({super.key, this.group, this.groupId});

  /// Group being edited; null when creating.
  final AccessGroup? group;

  /// Group id from the route path (/ga/groups/:id). Lets the screen rebuild
  /// edit state on a deep-link/refresh where [group] wasn't passed via `extra`.
  final String? groupId;

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  late final GroupEditController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GroupEditController(
      repository: AppInjector.get<AccessAdminRepository>(),
      initial: widget.group,
      groupId: widget.groupId,
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final result = await _controller.save();
    if (!mounted) return;
    if (result.group != null) {
      AppInjector.get<GroupsController>().upsertLocal(result.group!);
      showToast(context, message: 'Grupo salvo', status: 'success');
      // `go` (não `pop`): a navegação até aqui passou a ser por `go`, então não
      // há rota empilhada para dar pop — volta explicitamente para a lista.
      context.go(AppRoutes.gaGroups);
    } else if (result.error != null) {
      showToast(context, message: result.error!, status: 'error');
    }
  }

  Future<void> _onAddMember() async {
    final existing = {
      for (final m in _controller.membersSignal.value) m.userId,
    };
    final selected = await showAppSheet<PortalUser>(
      child: AddMemberSheet(existingMemberIds: existing),
    );
    if (selected == null || !mounted) return;
    final error = await _controller.addMember(selected.id);
    if (!mounted) return;
    if (error != null) {
      showToast(context, message: error, status: 'error');
    }
  }

  Future<void> _onRemoveMember(UserGroupSummary member) async {
    final ok = await confirmDialog(
      context,
      title: 'Remover membro',
      message: 'Remover ${member.displayName} do grupo?',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;
    final error = await _controller.removeMember(member.userId);
    if (!mounted) return;
    if (error != null) {
      showToast(context, message: error, status: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _controller.isEditing ? 'Editar grupo' : 'Novo grupo';

    return AppPageScaffold(
      // Back explícito para a lista: como navegamos por `go`, não há stack para
      // o AppTopBar dar pop (cairia no fallback go(home)).
      appBar: AppTopBar(
        title: title,
        onPressed: () => context.go(AppRoutes.gaGroups),
      ),
      body: SignalBuilder(builder: (context) {
        final status = _controller.statusSignal.value;
        if (status == AdminStatus.loading || status == AdminStatus.idle) {
          return const AppLoading();
        }
        if (status == AdminStatus.error) {
          return AppErrorWidget(
            message: _controller.errorSignal.value?.message,
            onRetry: _controller.init,
          );
        }

        return Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupFormSection(
                nameController: _controller.nameController,
                descriptionController: _controller.descriptionController,
              ),
              SizedBox(height: AppSpacing.lg),
              const AppDivider(),
              SizedBox(height: AppSpacing.md),
              PermissionMatrix(
                matrix: _controller.matrixSignal.value,
                onToggle: _controller.toggle,
                onSetAll: _controller.setAll,
              ),
              SizedBox(height: AppSpacing.lg),
              const AppDivider(),
              SizedBox(height: AppSpacing.md),
              GroupMembersSection(
                members: _controller.membersSignal.value,
                enabled: _controller.canManageRelations,
                onAdd: _onAddMember,
                onRemove: _onRemoveMember,
              ),
              SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Salvar',
                isFullWidth: true,
                isLoading: _controller.savingSignal.value,
                onPressed: _onSave,
              ),
            ],
          ),
        );
      }),
    );
  }
}
