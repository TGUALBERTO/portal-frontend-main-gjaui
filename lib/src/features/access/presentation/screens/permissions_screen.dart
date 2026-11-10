import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/group_permission_draft.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/groups_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/permission_matrix.dart';
import 'package:gjamobile/src/imports/imports.dart' hide Permission;
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Standalone permissions editor: pick a group, then edit its CRUD matrix.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _groupsController = AppInjector.get<GroupsController>();
  final _repository = AppInjector.get<AccessAdminRepository>();

  AccessGroup? _selected;
  List<GroupPermissionDraft> _matrix = const [];
  bool _loadingMatrix = false;
  bool _saving = false;
  String? _matrixError;

  @override
  void initState() {
    super.initState();
    _groupsController.load();
  }

  Future<void> _selectGroup(AccessGroup group) async {
    setState(() {
      _selected = group;
      _loadingMatrix = true;
      _matrixError = null;
      _matrix = const [];
    });
    final result = await _repository.fetchFeatures();
    if (!mounted) return;
    result.onSuccess((features) {
      final existing = <String, Permission>{
        for (final p in group.permissions) p.feature.id: p,
      };
      final drafts = features.map((f) {
        final p = existing[f.id];
        return p != null
            ? GroupPermissionDraft.fromPermission(p)
            : GroupPermissionDraft.empty(f);
      }).toList();
      drafts.sort((a, b) {
        final m = a.feature.module.label.compareTo(b.feature.module.label);
        return m != 0
            ? m
            : a.feature.label
                .toLowerCase()
                .compareTo(b.feature.label.toLowerCase());
      });
      setState(() {
        _matrix = drafts;
        _loadingMatrix = false;
      });
    }).onFailure((failure) => setState(() {
          _matrixError = failure.message;
          _loadingMatrix = false;
        }));
  }

  void _toggle(String featureId, PermissionAction action) {
    setState(() {
      _matrix = _matrix.map((d) {
        if (d.feature.id != featureId) return d;
        return d.copy()..toggle(action);
      }).toList(growable: false);
    });
  }

  void _setAll(String featureId, bool value) {
    setState(() {
      _matrix = _matrix.map((d) {
        if (d.feature.id != featureId) return d;
        return d.copy()..setAll(value);
      }).toList(growable: false);
    });
  }

  Future<void> _save() async {
    final group = _selected;
    if (group == null) return;
    setState(() => _saving = true);
    final result = await _repository.replacePermissions(group.id, _matrix);
    if (!mounted) return;
    setState(() => _saving = false);
    final error = result.exceptionOrNull()?.message;
    showToast(
      context,
      message: error ?? 'Permissões salvas',
      status: error == null ? 'success' : 'error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      scrollable: false,
      appBar: const AppTopBar(title: 'Permissões'),
      body: SignalBuilder(builder: (context) {
        final status = _groupsController.statusSignal.value;
        final groups = _groupsController.groupsSignal.value;

        if (status == AdminStatus.loading || status == AdminStatus.idle) {
          return const AppLoading();
        }
        if (status == AdminStatus.error) {
          return AppErrorWidget(
            message: _groupsController.errorSignal.value?.message,
            onRetry: _groupsController.load,
          );
        }
        if (groups.isEmpty) {
          return const AppEmptyState(
            icon: GjaIcons.locked,
            title: 'Nenhum grupo',
            subtitle: 'Crie um grupo para definir permissões.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selected?.id,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Grupo',
              ),
              items: [
                for (final g in groups)
                  DropdownMenuItem<String>(value: g.id, child: Text(g.name)),
              ],
              onChanged: (id) {
                final group = groups.firstWhere((g) => g.id == id);
                _selectGroup(group);
              },
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(child: _buildMatrixArea(context)),
            if (_selected != null && !_loadingMatrix && _matrixError == null)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: AppButton(
                  label: 'Salvar',
                  isFullWidth: true,
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildMatrixArea(BuildContext context) {
    if (_selected == null) {
      return const AppEmptyState(
        icon: GjaIcons.locked,
        title: 'Selecione um grupo',
        subtitle: 'Escolha um grupo para editar suas permissões.',
      );
    }
    if (_loadingMatrix) return const AppLoading();
    if (_matrixError != null) {
      return AppErrorWidget(
        message: _matrixError,
        onRetry: () => _selectGroup(_selected!),
      );
    }
    return SingleChildScrollView(
      child: PermissionMatrix(
        matrix: _matrix,
        onToggle: _toggle,
        onSetAll: _setAll,
      ),
    );
  }
}
