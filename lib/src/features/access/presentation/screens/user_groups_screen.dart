import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/users_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/user_groups_sheet.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Routed screen to manage a user's group memberships (replaces the old bottom
/// sheet) so the action shows in the URL: /ga/users/:id.
class UserGroupsScreen extends StatefulWidget {
  const UserGroupsScreen({super.key, this.user, this.userId});

  /// User passed via `extra` when navigating from the list (fast path).
  final PortalUser? user;

  /// User id from the route path; resolved against the list on a deep-link
  /// where [user] wasn't passed via `extra`.
  final String? userId;

  @override
  State<UserGroupsScreen> createState() => _UserGroupsScreenState();
}

class _UserGroupsScreenState extends State<UserGroupsScreen> {
  final _controller = AppInjector.get<UsersController>();
  PortalUser? _user;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    // The sheet reads groupsSignal + membership, so on a deep-link (or whenever
    // the list isn't loaded) resolve the user and populate the controller.
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
        title: user != null ? 'Grupos de ${user.displayName}' : 'Grupos',
        onPressed: () => context.go(AppRoutes.gaUsers),
      ),
      body: _resolving
          ? const AppLoading()
          : (_error != null || user == null)
              ? AppErrorWidget(
                  message: _error ?? 'Usuário não encontrado',
                  onRetry: () => _resolve(widget.userId ?? widget.user?.id),
                )
              : UserGroupsSheet(
                  user: user,
                  controller: _controller,
                  embedded: true,
                ),
    );
  }
}
