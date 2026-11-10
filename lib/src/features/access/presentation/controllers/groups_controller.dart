import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// App-scoped controller for the access-groups list.
class GroupsController {
  GroupsController({required AccessAdminRepository repository})
      : _repository = repository;

  final AccessAdminRepository _repository;

  late final Signal<AdminStatus> _status = signal(AdminStatus.idle);
  late final Signal<List<AccessGroup>> _groups = signal(const []);
  late final Signal<AppFailure?> _error = signal(null);

  ReadonlySignal<AdminStatus> get statusSignal => _status;
  ReadonlySignal<List<AccessGroup>> get groupsSignal => _groups;
  ReadonlySignal<AppFailure?> get errorSignal => _error;

  Future<void> load() async {
    _status.value = AdminStatus.loading;
    _error.value = null;
    final result = await _repository.fetchGroups();
    result.onSuccess((data) {
      _groups.value = data;
      _status.value = AdminStatus.loaded;
    }).onFailure((failure) {
      _error.value = failure;
      _status.value = AdminStatus.error;
      AppLogger.warning('GroupsController.load failed: ${failure.message}');
    });
  }

  /// Deletes a group; returns the failure message on error, null on success.
  Future<String?> delete(String id) async {
    final result = await _repository.deleteGroup(id);
    return result.fold(
      (_) {
        _groups.value =
            _groups.value.where((g) => g.id != id).toList(growable: false);
        return null;
      },
      (failure) => failure.message,
    );
  }

  /// Inserts or replaces a group in the local list (after create/edit) so the
  /// list reflects changes without a full reload.
  void upsertLocal(AccessGroup group) {
    final next = [..._groups.value];
    final idx = next.indexWhere((g) => g.id == group.id);
    if (idx >= 0) {
      next[idx] = group;
    } else {
      next.add(group);
    }
    next.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _groups.value = next;
  }

  void dispose() {
    _status.dispose();
    _groups.dispose();
    _error.dispose();
  }
}
