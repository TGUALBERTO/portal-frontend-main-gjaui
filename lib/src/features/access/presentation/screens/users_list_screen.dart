import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/users_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/kba_link_sheet.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/user_list_tile.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _controller = AppInjector.get<UsersController>();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  Future<void> _unlockKba(PortalUser user) async {
    final ok = await confirmDialog(
      context,
      title: 'Desbloquear KBA',
      message: 'Desbloquear o vínculo de matrícula de ${user.displayName}? '
          'O usuário poderá tentar o processo de validação novamente.',
      confirmLabel: 'Desbloquear',
    );
    if (!ok) return;

    final error = await _controller.unlockKba(user.id);
    if (!mounted) return;
    showGlobalToast(
      message: error ?? 'KBA desbloqueado para ${user.displayName}.',
      status: error == null ? 'success' : 'error',
    );
  }

  Future<void> _linkKba(PortalUser user) async {
    final input = await showKbaLinkSheet(user);
    if (input == null || !mounted) return;

    final error = await _controller.linkKba(
      user.id,
      codigoEmpresa: input.codigoEmpresa,
      matricula: input.matricula,
    );
    if (!mounted) return;
    showGlobalToast(
      message: error ??
          'Matrícula ${input.matricula} vinculada a ${user.displayName}.',
      status: error == null ? 'success' : 'error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      scrollable: false,
      appBar: const AppTopBar(title: 'Usuários'),
      body: SignalBuilder(builder: (context) {
        final status = _controller.statusSignal.value;

        if (status == AdminStatus.loading || status == AdminStatus.idle) {
          return const AppLoading();
        }
        if (status == AdminStatus.error) {
          return AppErrorWidget(
            message: _controller.errorSignal.value?.message,
            onRetry: _controller.load,
          );
        }

        final users = _controller.filteredSignal.value;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppTextField(
                hint: 'Buscar por nome ou e-mail',
                prefixIcon: const Icon(GjaIcons.search),
                onChanged: _controller.setQuery,
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const AppEmptyState(
                      icon: GjaIcons.employeeLookup,
                      title: 'Nenhum usuário encontrado',
                    )
                  : RefreshIndicator(
                      onRefresh: _controller.load,
                      child: ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final user = users[i];
                          return UserListTile(
                            user: user,
                            groupCount: _controller.groupsOf(user.id).length,
                            onTap: () => context.go(
                              AppRoutes.gaUserDetailPath(user.id),
                              extra: user,
                            ),
                            onManageGroups: () => context.go(
                              AppRoutes.gaUserGroupsPath(user.id),
                              extra: user,
                            ),
                            onUnlockKba: user.kbaBloqueado
                                ? () => _unlockKba(user)
                                : null,
                            onLinkKba: user.isLinked
                                ? null
                                : () => _linkKba(user),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
