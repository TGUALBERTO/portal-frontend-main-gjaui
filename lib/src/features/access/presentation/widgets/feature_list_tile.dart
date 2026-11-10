import 'package:gjamobile/src/features/access/domain/entities/feature.dart';
import 'package:gjamobile/src/features/access/utils/feature_icon.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// A row in the features list. Shows icon, label, code+module, edit/delete.
class FeatureListTile extends StatelessWidget {
  const FeatureListTile({
    super.key,
    required this.feature,
    required this.onEdit,
    required this.onDelete,
  });

  final Feature feature;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          Icon(iconForFeature(feature.iconName), color: cs.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label,
                  style: context.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${feature.code} · ${feature.module.label}',
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
