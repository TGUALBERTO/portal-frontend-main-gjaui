import 'package:flutter/widgets.dart';
import 'package:result_dart/result_dart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/group_permission_draft.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/domain/entities/user_group_summary.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Result of a save attempt. [group] is non-null on success; [error] carries a
/// message on failure; both null means client-side validation failed.
typedef GroupSaveResult = ({AccessGroup? group, String? error});

/// Screen-scoped controller for creating/editing a group: name/description
/// form, the permission matrix, and (edit-only) member management.
///
/// Built and disposed by `GroupEditScreen` because it is parameterized by the
/// group being edited — it is NOT registered in DI.
class GroupEditController {
  GroupEditController({
    required AccessAdminRepository repository,
    AccessGroup? initial,
    String? groupId,
  })  : _repository = repository,
        _group = initial,
        _groupId = initial?.id ?? groupId {
    nameController.text = initial?.name ?? '';
    descriptionController.text = initial?.description ?? '';
  }

  final AccessAdminRepository _repository;

  /// The group being edited. May start null on a deep-link to /ga/groups/:id
  /// (no `extra`); [init] then resolves it by [_groupId].
  AccessGroup? _group;
  String? _groupId;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  late final Signal<AdminStatus> _status = signal(AdminStatus.idle);
  late final Signal<List<GroupPermissionDraft>> _matrix = signal(const []);
  late final Signal<List<UserGroupSummary>> _members = signal(const []);
  late final Signal<bool> _saving = signal(false);
  late final Signal<AppFailure?> _error = signal(null);

  ReadonlySignal<AdminStatus> get statusSignal => _status;
  ReadonlySignal<List<GroupPermissionDraft>> get matrixSignal => _matrix;
  ReadonlySignal<List<UserGroupSummary>> get membersSignal => _members;
  ReadonlySignal<bool> get savingSignal => _saving;
  ReadonlySignal<AppFailure?> get errorSignal => _error;

  bool get isEditing => _groupId != null;

  /// Members and permissions can only be persisted once the group exists.
  bool get canManageRelations => _groupId != null;

  String? get groupId => _groupId;

  /// Loads all features (to build the matrix) and, when editing, the members.
  Future<void> init() async {
    _status.value = AdminStatus.loading;
    _error.value = null;

    // Deep-link / refresh on /ga/groups/:id without the group passed via
    // `extra`: resolve the full group (with permissions) by id before building
    // the matrix. The warm path (navigated from the list) already has _group.
    if (_group == null && _groupId != null) {
      final loaded = await _resolveGroupById(_groupId!);
      if (loaded == null) {
        _error.value ??= const ServerFailure('Grupo não encontrado');
        _status.value = AdminStatus.error;
        return;
      }
      _group = loaded;
      nameController.text = loaded.name;
      descriptionController.text = loaded.description ?? '';
    }

    final result = await _repository.fetchFeatures();
    await result.fold(
      (features) async {
        final existing = <String, Permission>{
          for (final p in _group?.permissions ?? const [])
            p.feature.id: p,
        };
        final drafts = features.map((f) {
          final p = existing[f.id];
          return p != null
              ? GroupPermissionDraft.fromPermission(p)
              : GroupPermissionDraft.empty(f);
        }).toList(growable: false);
        drafts.sort((a, b) {
          final m = a.feature.module.label.compareTo(b.feature.module.label);
          return m != 0
              ? m
              : a.feature.label
                  .toLowerCase()
                  .compareTo(b.feature.label.toLowerCase());
        });
        _matrix.value = drafts;
        if (canManageRelations) await _loadMembers();
        _status.value = AdminStatus.loaded;
      },
      (failure) async {
        _error.value = failure;
        _status.value = AdminStatus.error;
      },
    );
  }

  void toggle(String featureId, PermissionAction action) {
    _matrix.value = _matrix.value.map((d) {
      if (d.feature.id != featureId) return d;
      final copy = d.copy()..toggle(action);
      return copy;
    }).toList(growable: false);
  }

  void setAll(String featureId, bool value) {
    _matrix.value = _matrix.value.map((d) {
      if (d.feature.id != featureId) return d;
      return d.copy()..setAll(value);
    }).toList(growable: false);
  }

  /// Persists the group then replaces its permissions.
  Future<GroupSaveResult> save() async {
    if (formKey.currentState?.validate() != true) {
      return (group: null, error: null);
    }
    _saving.value = true;
    final name = nameController.text.trim();
    final desc = descriptionController.text.trim();
    final description = desc.isEmpty ? null : desc;

    final upsert = isEditing
        ? _repository.updateGroup(_groupId!,
            name: name, description: description)
        : _repository.createGroup(name: name, description: description);

    // Persist the group, remember its id, then replace its permissions and map
    // both into the final saved group — without ever leaving the Result.
    final result = await upsert
        .onSuccess((group) => _groupId = group.id)
        .flatMap(
          (group) =>
              _repository.replacePermissions(group.id, _matrix.value).map(
                    (permissions) => AccessGroup(
                      id: group.id,
                      name: group.name,
                      description: group.description,
                      permissions: permissions,
                    ),
                  ),
        );
    _saving.value = false;

    return result.fold(
      (group) => (group: group, error: null),
      (failure) => (group: null, error: failure.message),
    );
  }

  Future<String?> addMember(String userId) async {
    if (_groupId == null) return 'Salve o grupo antes de adicionar membros';
    final result = await _repository.addUserToGroup(_groupId!, userId);
    if (result.isError()) return result.exceptionOrNull()!.message;
    await _loadMembers();
    return null;
  }

  Future<String?> removeMember(String userId) async {
    if (_groupId == null) return null;
    final result = await _repository.removeUserFromGroup(_groupId!, userId);
    if (result.isError()) return result.exceptionOrNull()!.message;
    await _loadMembers();
    return null;
  }

  /// Fetches the groups list and returns the one matching [id] (the list
  /// endpoint already includes each group's permissions). Rebuilds edit state
  /// on a cold deep-link where the group wasn't passed via `extra`.
  Future<AccessGroup?> _resolveGroupById(String id) async {
    final result = await _repository.fetchGroups();
    return result.fold(
      (groups) {
        for (final g in groups) {
          if (g.id == id) return g;
        }
        return null;
      },
      (failure) {
        _error.value = failure;
        return null;
      },
    );
  }

  Future<void> _loadMembers() async {
    if (_groupId == null) return;
    final result = await _repository.fetchGroupUsers(_groupId!);
    result.fold(
      (list) => _members.value = list,
      (failure) => AppLogger.warning(
          'GroupEditController._loadMembers failed: ${failure.message}'),
    );
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    _status.dispose();
    _matrix.dispose();
    _members.dispose();
    _saving.dispose();
    _error.dispose();
  }
}
