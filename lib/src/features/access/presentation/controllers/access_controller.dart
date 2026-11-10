import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/domain/entities/user_access.dart';
import 'package:gjamobile/src/features/kba/domain/entities/employee_link.dart';
import 'package:gjamobile/src/utils/utils.dart';

enum AccessStatus { idle, loading, loaded, error }

class AccessController {
  AccessController({required AccessRepository repository})
      : _repository = repository;

  final AccessRepository _repository;

  late final Signal<AccessStatus> _status = signal(AccessStatus.idle);
  late final Signal<UserAccess?> _access = signal(null);
  late final Signal<AppFailure?> _error = signal(null);
  late final Computed<List<AccessGroup>> _groups =
      computed(() => _access.value?.groups ?? const []);
  late final Computed<Map<String, List<Permission>>> _permsByModule =
      computed(_buildPermsByModule);
  late final Computed<Map<String, Permission>> _permsByFeatureCode =
      computed(_buildPermsByFeatureCode);
  late final Computed<bool> _isAdmin =
      computed(() => _groups.value.any((g) => g.name.toUpperCase() == 'ADMIN'));
  late final Computed<EmployeeLink?> _employeeLink =
      computed(() => _access.value?.employeeLink);
  late final Computed<bool> _needsEmployeeLink =
      computed(() => _employeeLink.value?.needsLink ?? false);

  ReadonlySignal<AccessStatus> get statusSignal => _status;
  ReadonlySignal<UserAccess?> get accessSignal => _access;
  ReadonlySignal<AppFailure?> get errorSignal => _error;
  ReadonlySignal<List<AccessGroup>> get groupsSignal => _groups;
  ReadonlySignal<Map<String, List<Permission>>> get permissionsByModuleSignal =>
      _permsByModule;
  ReadonlySignal<bool> get isAdminSignal => _isAdmin;
  ReadonlySignal<EmployeeLink?> get employeeLinkSignal => _employeeLink;
  ReadonlySignal<bool> get needsEmployeeLinkSignal => _needsEmployeeLink;

  /// True when the current user belongs to the ADMIN group.
  bool get isAdmin => _isAdmin.value;

  bool get isConsultor => _groups.value
      .any((group) => group.name.trim().toUpperCase() == 'CONSULTOR');

  /// Vínculo com a matrícula funcional (nulo em backend antigo/KBA off).
  EmployeeLink? get employeeLink => _employeeLink.value;

  /// True quando o usuário precisa passar pelo fluxo de vínculo (/vinculo).
  bool get needsEmployeeLink => _needsEmployeeLink.value;

  bool can(String featureCode, PermissionAction action) {
    final p = _permsByFeatureCode.value[featureCode];
    return p != null && p.allows(action);
  }

  bool hasFeature(String featureCode) =>
      _permsByFeatureCode.value.containsKey(featureCode);

  Future<void> load() async {
    _status.value = AccessStatus.loading;
    _error.value = null;
    final result = await _repository.fetchCurrent();
    result.onSuccess((data) {
      _access.value = data;
      _status.value = AccessStatus.loaded;
    }).onFailure((failure) {
      _error.value = failure;
      _status.value = AccessStatus.error;
      AppLogger.warning('AccessController.load failed: ${failure.message}');
    });
  }

  void clear() {
    _access.value = null;
    _error.value = null;
    _status.value = AccessStatus.idle;
  }

  Map<String, List<Permission>> _buildPermsByModule() {
    final access = _access.value;
    if (access == null) return const {};
    final dedup = <String, Permission>{};
    for (final g in access.groups) {
      for (final p in g.permissions) {
        final existing = dedup[p.feature.code];
        if (existing == null) {
          dedup[p.feature.code] = p;
        } else {
          dedup[p.feature.code] = Permission(
            feature: p.feature,
            canCreate: existing.canCreate || p.canCreate,
            canRead: existing.canRead || p.canRead,
            canUpdate: existing.canUpdate || p.canUpdate,
            canDelete: existing.canDelete || p.canDelete,
          );
        }
      }
    }
    final out = <String, List<Permission>>{};
    for (final p in dedup.values) {
      if (!p.canRead) continue;
      out.putIfAbsent(p.feature.module.code, () => []).add(p);
    }
    for (final list in out.values) {
      list.sort((a, b) => a.feature.label.compareTo(b.feature.label));
    }
    return out;
  }

  Map<String, Permission> _buildPermsByFeatureCode() {
    final access = _access.value;
    if (access == null) return const {};
    final dedup = <String, Permission>{};
    for (final g in access.groups) {
      for (final p in g.permissions) {
        final existing = dedup[p.feature.code];
        if (existing == null) {
          dedup[p.feature.code] = p;
        } else {
          dedup[p.feature.code] = Permission(
            feature: p.feature,
            canCreate: existing.canCreate || p.canCreate,
            canRead: existing.canRead || p.canRead,
            canUpdate: existing.canUpdate || p.canUpdate,
            canDelete: existing.canDelete || p.canDelete,
          );
        }
      }
    }
    return dedup;
  }

  void dispose() {
    _status.dispose();
    _access.dispose();
    _error.dispose();
    _groups.dispose();
    _permsByModule.dispose();
    _permsByFeatureCode.dispose();
    _isAdmin.dispose();
    _employeeLink.dispose();
    _needsEmployeeLink.dispose();
  }
}
