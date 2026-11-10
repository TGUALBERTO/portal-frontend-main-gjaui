import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/users_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Bottom-sheet to toggle a user's group memberships. Each group has a switch
/// reflecting current membership; toggling persists optimistically via the
/// [UsersController].
class UserGroupsSheet extends StatelessWidget {
  const UserGroupsSheet({
    super.key,
    required this.user,
    required this.controller,
    this.embedded = false,
  });

  final PortalUser user;
  final UsersController controller;

  /// When true, drops the bottom-sheet chrome (rounded container + heading) so
  /// the content can be hosted inside a full routed screen.
  final bool embedded;

  Future<void> _toggle(BuildContext context, String groupId, bool member) async {
    final error = await controller.setMembership(
      userId: user.id,
      groupId: groupId,
      member: member,
    );
    if (error != null && context.mounted) {
      showToast(context, message: error, status: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final groups = controller.groupsSignal.value;

    return Container(
      decoration: embedded
          ? null
          : BoxDecoration(
              color: cs.surface,
              borderRadius: AppBorders.bottomSheet,
            ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + (embedded ? 0 : MediaQuery.viewInsetsOf(context).bottom),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!embedded) ...[
            Text(
              'Grupos de ${user.displayName}',
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSpacing.sm),
          ],
          if (groups.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Nenhum grupo disponível.',
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: SignalBuilder(builder: (context) {
                  final memberOf = controller.groupsOf(user.id);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final group in groups)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(group.name),
                          subtitle: (group.description?.isNotEmpty ?? false)
                              ? Text(group.description!)
                              : null,
                          value: memberOf.contains(group.id),
                          onChanged: (v) => _toggle(context, group.id, v),
                        ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
