import 'package:gjamobile/src/features/access/domain/entities/group_permission_draft.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/permission_matrix_row.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Editable permission matrix (features × CRUD). Backed by a single
/// [GroupPermissionDraft] list, with two presentations chosen by width:
/// mobile cards (one per feature, grouped by module) and a desktop DataTable.
class PermissionMatrix extends StatefulWidget {
  const PermissionMatrix({
    super.key,
    required this.matrix,
    required this.onToggle,
    required this.onSetAll,
  });

  final List<GroupPermissionDraft> matrix;
  final void Function(String featureId, PermissionAction action) onToggle;
  final void Function(String featureId, bool value) onSetAll;

  @override
  State<PermissionMatrix> createState() => _PermissionMatrixState();
}

class _PermissionMatrixState extends State<PermissionMatrix> {
  String _query = '';

  List<GroupPermissionDraft> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.matrix;
    return widget.matrix
        .where((d) =>
            d.feature.label.toLowerCase().contains(q) ||
            d.feature.code.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissões',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.sm),
        if (widget.matrix.length > 6)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppTextField(
              hint: 'Buscar funcionalidade',
              prefixIcon: const Icon(GjaIcons.search),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        if (filtered.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Nenhuma funcionalidade encontrada',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else if (context.isMobile)
          _buildMobile(context, filtered)
        else
          _buildTable(context, filtered),
      ],
    );
  }

  Widget _buildMobile(
      BuildContext context, List<GroupPermissionDraft> drafts) {
    final tt = context.textTheme;
    final cs = context.colors;

    // Group by module preserving sorted order.
    final byModule = <String, List<GroupPermissionDraft>>{};
    for (final d in drafts) {
      byModule.putIfAbsent(d.feature.module.code, () => []).add(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byModule.entries) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              entry.value.first.feature.module.label,
              style: tt.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final draft in entry.value)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: PermissionMatrixRow(
                draft: draft,
                onToggle: (action) =>
                    widget.onToggle(draft.feature.id, action),
                onSetAll: (value) => widget.onSetAll(draft.feature.id, value),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTable(
      BuildContext context, List<GroupPermissionDraft> drafts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Funcionalidade')),
          DataColumn(label: Text('Criar')),
          DataColumn(label: Text('Ler')),
          DataColumn(label: Text('Atualizar')),
          DataColumn(label: Text('Excluir')),
        ],
        rows: [
          for (final draft in drafts)
            DataRow(
              cells: [
                DataCell(Text(draft.feature.label)),
                _checkCell(draft, PermissionAction.create),
                _checkCell(draft, PermissionAction.read),
                _checkCell(draft, PermissionAction.update),
                _checkCell(draft, PermissionAction.delete),
              ],
            ),
        ],
      ),
    );
  }

  DataCell _checkCell(GroupPermissionDraft draft, PermissionAction action) {
    return DataCell(
      Checkbox(
        value: draft.allows(action),
        onChanged: (_) => widget.onToggle(draft.feature.id, action),
      ),
    );
  }
}
