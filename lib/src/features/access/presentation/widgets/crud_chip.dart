import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/imports/core_imports.dart';

/// A single CRUD toggle chip (C/R/U/D) used in the mobile permission matrix.
class CrudChip extends StatelessWidget {
  const CrudChip({
    super.key,
    required this.action,
    required this.selected,
    required this.onToggle,
  });

  final PermissionAction action;
  final bool selected;
  final VoidCallback onToggle;

  static String labelFor(PermissionAction action) => switch (action) {
        PermissionAction.create => 'C',
        PermissionAction.read => 'R',
        PermissionAction.update => 'U',
        PermissionAction.delete => 'D',
      };

  static String tooltipFor(PermissionAction action) => switch (action) {
        PermissionAction.create => 'Criar',
        PermissionAction.read => 'Ler',
        PermissionAction.update => 'Atualizar',
        PermissionAction.delete => 'Excluir',
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Tooltip(
      message: tooltipFor(action),
      child: FilterChip(
        label: Text(labelFor(action)),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onToggle(),
        labelStyle: context.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
        backgroundColor: cs.surfaceContainerHighest,
        selectedColor: cs.primary,
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
        ),
      ),
    );
  }
}
