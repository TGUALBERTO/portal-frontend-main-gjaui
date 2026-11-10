import 'package:gjamobile/src/features/access/domain/entities/user_group_summary.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Edit-only section listing a group's members with add/remove controls.
class GroupMembersSection extends StatelessWidget {
  const GroupMembersSection({
    super.key,
    required this.members,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<UserGroupSummary> members;
  final bool enabled;
  final VoidCallback onAdd;
  final void Function(UserGroupSummary member) onRemove;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Membros',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(GjaIcons.addEmployee),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        if (!enabled)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Salve o grupo para gerenciar membros.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else if (members.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Nenhum membro neste grupo.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          for (final member in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(_initials(member.displayName))),
              title: Text(member.displayName, style: TextStyle(color: cs.onSurfaceVariant),),
              subtitle: Text(member.email, style: TextStyle(color: cs.onSurfaceVariant),),
              trailing: IconButton(
                tooltip: 'Remover',
                icon: Icon(GjaIcons.decline, color: cs.error),
                onPressed: () => onRemove(member),
              ),
            ),
      ],
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
