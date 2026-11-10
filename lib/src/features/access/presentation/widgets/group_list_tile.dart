import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// A row in the groups list. Shows name + description with edit/delete actions.
/// Destructive actions are disabled for the protected ADMIN group.
class GroupListTile extends StatelessWidget {
  const GroupListTile({
    super.key,
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  final AccessGroup group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  bool get _isAdmin => group.name.toUpperCase() == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            _isAdmin ? GjaIcons.userSettings : GjaIcons.group,
            color: cs.primary,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: context.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if ((group.description?.trim().isNotEmpty ?? false))
                  Text(
                    group.description!,
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(GjaIcons.edit),
            onPressed: onTap,
          ),
          IconButton(
            tooltip: _isAdmin ? 'Grupo protegido' : 'Excluir',
            icon: const Icon(GjaIcons.delete),
            color: cs.error,
            onPressed: _isAdmin ? null : onDelete,
          ),
        ],
      ),
    );
  }
}
