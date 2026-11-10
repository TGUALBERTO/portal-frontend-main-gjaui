import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Bottom-sheet content listing portal users (excluding current members) so the
/// admin can pick one to add to a group. Pops with the selected [PortalUser].
class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key, required this.existingMemberIds});

  final Set<String> existingMemberIds;

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _repository = AppInjector.get<AccessAdminRepository>();
  bool _loading = true;
  String? _error;
  String _query = '';
  List<PortalUser> _users = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.fetchUsers();
    if (!mounted) return;
    result.onSuccess((users) => setState(() {
          _users = users
              .where((u) => !widget.existingMemberIds.contains(u.id))
              .toList(growable: false);
          _loading = false;
        })).onFailure((failure) => setState(() {
          _error = failure.message;
          _loading = false;
        }));
  }

  List<PortalUser> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users
        .where((u) =>
            (u.name?.toLowerCase().contains(q) ?? false) ||
            u.email.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.bottomSheet,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adicionar membro',
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'Buscar usuário',
            prefixIcon: const Icon(GjaIcons.search),
            onChanged: (v) => setState(() => _query = v),
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 320,
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const AppLoading();
    if (_error != null) {
      return AppErrorWidget(message: _error, onRetry: _load);
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const AppEmptyState(
        icon: GjaIcons.employeeRejections,
        title: 'Nenhum usuário disponível',
      );
    }
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const AppDivider(),
      itemBuilder: (context, i) {
        final user = filtered[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(_initials(user.displayName))),
          title: Text(user.displayName),
          subtitle: Text(user.email),
          trailing: const Icon(GjaIcons.add),
          onTap: () => Navigator.of(context).pop(user),
        );
      },
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
