import 'package:gjamobile/src/features/access/domain/entities/module.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// A row in the modules list. Shows label, code, edit/delete.
class ModuleListTile extends StatelessWidget {
  const ModuleListTile({
    super.key,
    required this.module,
    required this.onEdit,
    required this.onDelete,
  });

  final Module module;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          Icon(GjaIcons.overviewChart, color: cs.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.label,
                  style: context.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  module.code,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(GjaIcons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(GjaIcons.delete),
            color: cs.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
