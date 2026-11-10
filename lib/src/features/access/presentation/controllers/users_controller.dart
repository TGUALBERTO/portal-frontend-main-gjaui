import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/kba/domain/entities/employee_link.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// App-scoped controller for the users list and user→group assignment.
///
/// Since the backend has no `GET /users/{id}/groups` endpoint, current
/// memberships are aggregated by querying `GET /groups/{id}/users` across all
/// groups into a `Map<userId, Set<groupId>>` on [load].
class UsersController {
  UsersController({required AccessAdminRepository repository})
      : _repository = repository;

  final AccessAdminRepository _repository;

  late final Signal<AdminStatus> _status = signal(AdminStatus.idle);
  late final Signal<List<PortalUser>> _users = signal(const []);
  late final Signal<List<AccessGroup>> _groups = signal(const []);
  late final Signal<Map<String, Set<String>>> _membership = signal(const {});
  late final Signal<String> _query = signal('');
  late final Signal<AppFailure?> _error = signal(null);

  late final Computed<List<PortalUser>> _filtered = computed(() {
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return _users.value;
    return _users.value
        .where((u) =>
            (u.name?.toLowerCase().contains(q) ?? false) ||
            u.email.toLowerCase().contains(q))
        .toList(growable: false);
  });

  ReadonlySignal<AdminStatus> get statusSignal => _status;
  ReadonlySignal<List<PortalUser>> get usersSignal => _users;
  ReadonlySignal<List<AccessGroup>> get groupsSignal => _groups;
  ReadonlySignal<Map<String, Set<String>>> get membershipSignal => _membership;
  ReadonlySignal<String> get querySignal => _query;
  ReadonlySignal<AppFailure?> get errorSignal => _error;
  ReadonlySignal<List<PortalUser>> get filteredSignal => _filtered;

  // ignore: use_setters_to_change_properties
  void setQuery(String value) => _query.value = value;

  /// Semeia a lista de usuários diretamente (estado interno) — só para testes.
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void seedUsers(List<PortalUser> users) => _users.value = users;

  Set<String> groupsOf(String userId) =>
      _membership.value[userId] ?? const {};

  Future<void> load() async {
    _status.value = AdminStatus.loading;
    _error.value = null;

    // Fetch users and groups, then combine both Results into a single record.
    // `zip` short-circuits to the first failure, so a single guard covers both.
    final combined =
        (await _repository.fetchUsers()).zip(await _repository.fetchGroups());

    final records = combined.getOrNull();
    if (records == null) {
      final failure = combined.exceptionOrNull()!;
      _error.value = failure;
      _status.value = AdminStatus.error;
      AppLogger.warning('UsersController.load failed: ${failure.message}');
      return;
    }

    final (users, groups) = records;
    _users.value = users;
    _groups.value = groups;

    // Aggregate memberships across all groups (N calls).
    final membership = <String, Set<String>>{};
    for (final group in groups) {
      final members = await _repository.fetchGroupUsers(group.id);
      members.onSuccess((list) {
        for (final m in list) {
          membership.putIfAbsent(m.userId, () => <String>{}).add(group.id);
        }
      }).onFailure((f) => AppLogger.warning(
          'fetchGroupUsers(${group.id}) failed: ${f.message}'));
    }
    _membership.value = membership;
    _status.value = AdminStatus.loaded;
  }

  /// Adds or removes a user from a group, updating the membership map
  /// optimistically and rolling back on failure. Returns the failure message
  /// on error, null on success.
  Future<String?> setMembership({
    required String userId,
    required String groupId,
    required bool member,
  }) async {
    final previous = groupsOf(userId);
    _applyMembership(userId, groupId, member);

    final result = member
        ? await _repository.addUserToGroup(groupId, userId)
        : await _repository.removeUserFromGroup(groupId, userId);

    return result.fold(
      (_) => null,
      (failure) {
        _setMembershipSet(userId, previous); // rollback
        return failure.message;
      },
    );
  }

  void _applyMembership(String userId, String groupId, bool member) {
    final current = {...groupsOf(userId)};
    if (member) {
      current.add(groupId);
    } else {
      current.remove(groupId);
    }
    _setMembershipSet(userId, current);
  }

  void _setMembershipSet(String userId, Set<String> groups) {
    final next = {..._membership.value};
    next[userId] = {...groups};
    _membership.value = next;
  }

  /// Desbloqueia o KBA de um usuário (revisão manual). Atualiza a lista local
  /// no sucesso; retorna a mensagem de falha no erro, null no sucesso.
  Future<String?> unlockKba(String userId) async {
    final result = await _repository.unlockKba(userId);
    return result.fold(
      (_) {
        _users.value = _users.value
            .map((u) => u.id == userId ? u.copyWith(kbaBloqueado: false) : u)
            .toList(growable: false);
        return null;
      },
      (failure) => failure.message,
    );
  }

  /// Vincula manualmente um usuário a uma matrícula (revisão manual).
  /// Atualiza a lista local no sucesso; retorna a mensagem de falha no erro.
  Future<String?> linkKba(
    String userId, {
    required int codigoEmpresa,
    required int matricula,
  }) async {
    final result = await _repository.linkKba(
      userId,
      codigoEmpresa: codigoEmpresa,
      matricula: matricula,
    );
    return result.fold(
      (_) {
        _users.value = _users.value
            .map((u) => u.id == userId
                ? u.copyWith(
                    employeeLinkStatus: EmployeeLinkStatus.linked,
                    kbaBloqueado: false,
                    matricula: matricula,
                    codigoEmpresa: codigoEmpresa,
                  )
                : u)
            .toList(growable: false);
        return null;
      },
      (failure) => failure.message,
    );
  }

  void dispose() {
    _status.dispose();
    _users.dispose();
    _groups.dispose();
    _membership.dispose();
    _query.dispose();
    _error.dispose();
    _filtered.dispose();
  }
}
