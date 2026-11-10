import 'package:gjamobile/src/features/access/domain/entities/group_permission_draft.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/crud_chip.dart';
import 'package:gjamobile/src/features/access/utils/feature_icon.dart';
import 'package:gjamobile/src/imports/core_imports.dart';

/// Mobile card representing one feature row of the permission matrix:
/// feature label + four CRUD toggle chips + quick "Tudo"/"Limpar" actions.
class PermissionMatrixRow extends StatelessWidget {
  const PermissionMatrixRow({
    super.key,
    required this.draft,
    required this.onToggle,
    required this.onSetAll,
  });

  final GroupPermissionDraft draft;
  final void Function(PermissionAction action) onToggle;
  final void Function(bool value) onSetAll;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconForFeature(draft.feature.iconName),
                  size: 20, color: cs.onSurfaceVariant),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.feature.label,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      draft.feature.code,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onSetAll(!draft.hasAll),
                child: Text(draft.hasAll ? 'Limpar' : 'Tudo'),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final action in PermissionAction.values)
                CrudChip(
                  action: action,
                  selected: draft.allows(action),
                  onToggle: () => onToggle(action),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
