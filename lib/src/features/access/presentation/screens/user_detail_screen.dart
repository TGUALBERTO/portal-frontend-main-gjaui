import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/users_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Detalhe de um usuário (admin), roteado em `/ga/user/:id`. Mostra os dados do
/// [PortalUser] carregado na lista + os grupos do usuário. Aceita o usuário via
/// `extra` (caminho rápido) e resolve pelo id em deep-link.
class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, this.user, this.userId});

  final PortalUser? user;
  final String? userId;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _controller = AppInjector.get<UsersController>();
  PortalUser? _user;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    // Em deep-link (sem `extra`) ou lista vazia, resolve o usuário e popula
    // os grupos a partir do controller.
    if (_user == null || _controller.usersSignal.value.isEmpty) {
      _resolve(widget.userId ?? widget.user?.id);
    }
  }

  Future<void> _resolve(String? id) async {
    if (id == null) {
      setState(() => _error = 'Usuário não encontrado');
      return;
    }
    setState(() {
      _resolving = true;
      _error = null;
    });
    if (_controller.usersSignal.value.isEmpty) {
      await _controller.load();
    }
    PortalUser? found;
    for (final u in _controller.usersSignal.value) {
      if (u.id == id) {
        found = u;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _user = found ?? _user;
      _resolving = false;
      _error =
          (found == null && _user == null) ? 'Usuário não encontrado' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return AppPageScaffold(
      appBar: AppTopBar(
        title: 'Usuário',
        onPressed: () => context.go(AppRoutes.gaUsers),
      ),
      body: _resolving
          ? const AppLoading()
          : (_error != null || user == null)
              ? AppErrorWidget(
                  message: _error ?? 'Usuário não encontrado',
                  onRetry: () => _resolve(widget.userId ?? widget.user?.id),
                )
              : SignalBuilder(builder: (context) {
                  final groupIds = _controller.groupsOf(user.id);
                  final groups = _controller.groupsSignal.value
                      .where((g) => groupIds.contains(g.id))
                      .toList(growable: false);
                  return _Body(user: user, groups: groups);
                }),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.user, required this.groups});

  final PortalUser user;
  final List<AccessGroup> groups;

  @override
  Widget build(BuildContext context) {
    final linkLabel = user.isLinked
        ? (user.kbaBloqueado ? 'Vinculado (bloqueado)' : 'Vinculado')
        : (user.kbaBloqueado ? 'Não vinculado (bloqueado)' : 'Não vinculado');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            UserAvatar(name: user.displayName, radius: 44),
            SizedBox(height: AppSpacing.md),
            Text(
              user.displayName,
              style: context.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        AppCard(
          title: 'Informações',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user.matricula != null)
                ProfileInfoTile(
                    icon: GjaIcons.numberSign,
                    label: 'Matrícula',
                    value: user.matricula.toString()),
              if (user.empresa != null)
                ProfileInfoTile(
                    icon: GjaIcons.building,
                    label: 'Empresa',
                    value: user.empresa!.razaoSocial),
              ProfileInfoTile(
                  icon: GjaIcons.badge,
                  label: 'Vínculo de matrícula',
                  value: linkLabel),
              if (user.createdAt != null)
                ProfileInfoTile(
                    icon: GjaIcons.appointment,
                    label: 'Criado em',
                    value: user.createdAt!.toIso8601DateOnly),
              if (user.lastLoginAt != null)
                ProfileInfoTile(
                    icon: GjaIcons.journeyArrive,
                    label: 'Último acesso',
                    value: user.lastLoginAt!.toIso8601DateOnly),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        AppCard(
          title: 'Grupos',
          trailing: TextButton.icon(
            onPressed: () => context.go(
              AppRoutes.gaUserGroupsPath(user.id),
              extra: user,
            ),
            icon: const Icon(GjaIcons.group, size: 18),
            label: const Text('Gerenciar'),
          ),
          child: groups.isEmpty
              ? const AppEmptyState(
                  icon: GjaIcons.group,
                  title: 'Nenhum grupo',
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final g in groups)
                      Chip(
                        label: Text(g.name),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
