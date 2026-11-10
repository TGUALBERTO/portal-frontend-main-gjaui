import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/entities/feature.dart';
import 'package:gjamobile/src/features/access/domain/entities/group_permission_draft.dart';
import 'package:gjamobile/src/features/access/domain/entities/module.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/domain/entities/user_group_summary.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Admin RBAC data source. Wraps the backend access-management endpoints
/// (all require the caller to be in the ADMIN group; Bearer token is attached
/// by the Dio interceptor on the [CoreDio] backend client). Every call is
/// wrapped in [runTask] for network checks and uniform [AppFailure] mapping.
class AccessAdminRepository {
  AccessAdminRepository(this._core);

  final CoreDio _core;

  // ── Groups ────────────────────────────────────────────────────────────────

  AsyncAppResult<List<AccessGroup>> fetchGroups() {
    return runTask(() async {
      final response = await _core.dio.get<dynamic>('/groups');
      return _parseList(response.data, AccessGroup.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<AccessGroup> createGroup({
    required String name,
    String? description,
  }) {
    return runTask(() async {
      final response = await _core.dio.post<dynamic>(
        '/groups',
        data: {'name': name, 'description': description},
      );
      return _parseObject(response.data, AccessGroup.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<AccessGroup> updateGroup(
    String id, {
    required String name,
    String? description,
  }) {
    return runTask(() async {
      final response = await _core.dio.put<dynamic>(
        '/groups/$id',
        data: {'name': name, 'description': description},
      );
      return _parseObject(response.data, AccessGroup.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> deleteGroup(String id) {
    return runTask(() async {
      await _core.dio.delete<dynamic>('/groups/$id');
      return unit;
    }, requiresNetwork: true);
  }

  AsyncAppResult<List<Permission>> replacePermissions(
    String groupId,
    List<GroupPermissionDraft> permissions,
  ) {
    return runTask(() async {
      final payload = permissions
          .where((d) => d.hasAny)
          .map((d) => d.toRequest())
          .toList(growable: false);
      final response = await _core.dio.put<dynamic>(
        '/groups/$groupId/permissions',
        data: {'permissions': payload},
      );
      return _parseList(response.data, Permission.fromJson);
    }, requiresNetwork: true);
  }

  // ── Membership ──────────────────────────────────────────────────────────

  AsyncAppResult<List<UserGroupSummary>> fetchGroupUsers(String groupId) {
    return runTask(() async {
      final response = await _core.dio.get<dynamic>('/groups/$groupId/users');
      return _parseList(response.data, UserGroupSummary.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> addUserToGroup(String groupId, String userId) {
    return runTask(() async {
      await _core.dio.post<dynamic>('/groups/$groupId/users/$userId');
      return unit;
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> removeUserFromGroup(String groupId, String userId) {
    return runTask(() async {
      await _core.dio.delete<dynamic>('/groups/$groupId/users/$userId');
      return unit;
    }, requiresNetwork: true);
  }

  // ── Features ──────────────────────────────────────────────────────────────

  AsyncAppResult<List<Feature>> fetchFeatures() {
    return runTask(() async {
      final response = await _core.dio.get<dynamic>('/features');
      return _parseList(response.data, Feature.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Feature> createFeature({
    required String code,
    required String label,
    String? iconName,
    required String moduleId,
  }) {
    return runTask(() async {
      final response = await _core.dio.post<dynamic>(
        '/features',
        data: {
          'code': code,
          'label': label,
          'iconName': iconName,
          'moduleId': moduleId,
        },
      );
      return _parseObject(response.data, Feature.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Feature> updateFeature(
    String id, {
    required String code,
    required String label,
    String? iconName,
    required String moduleId,
  }) {
    return runTask(() async {
      final response = await _core.dio.put<dynamic>(
        '/features/$id',
        data: {
          'code': code,
          'label': label,
          'iconName': iconName,
          'moduleId': moduleId,
        },
      );
      return _parseObject(response.data, Feature.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> deleteFeature(String id) {
    return runTask(() async {
      await _core.dio.delete<dynamic>('/features/$id');
      return unit;
    }, requiresNetwork: true);
  }

  // ── Modules ─────────────────────────────────────────────────────────────

  AsyncAppResult<List<Module>> fetchModules() {
    return runTask(() async {
      final response = await _core.dio.get<dynamic>('/modules');
      return _parseList(response.data, Module.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Module> createModule({
    required String code,
    required String label,
  }) {
    return runTask(() async {
      final response = await _core.dio.post<dynamic>(
        '/modules',
        data: {'code': code, 'label': label},
      );
      return _parseObject(response.data, Module.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Module> updateModule(
    String id, {
    required String code,
    required String label,
  }) {
    return runTask(() async {
      final response = await _core.dio.put<dynamic>(
        '/modules/$id',
        data: {'code': code, 'label': label},
      );
      return _parseObject(response.data, Module.fromJson);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> deleteModule(String id) {
    return runTask(() async {
      await _core.dio.delete<dynamic>('/modules/$id');
      return unit;
    }, requiresNetwork: true);
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  AsyncAppResult<List<PortalUser>> fetchUsers() {
    return runTask(() async {
      final response = await _core.dio.get<dynamic>('/users');
      return _parseList(response.data, PortalUser.fromJson);
    }, requiresNetwork: true);
  }

  /// Desbloqueia o KBA de um usuário que excedeu as tentativas (revisão
  /// manual). O usuário volta a poder iniciar o fluxo de vínculo.
  AsyncAppResult<Unit> unlockKba(String userId) {
    return runTask(() async {
      await _core.dio.post<dynamic>('/kba/admin/users/$userId/unlock');
      return unit;
    }, requiresNetwork: true);
  }

  /// Vincula manualmente um usuário a uma matrícula (revisão manual). O
  /// backend valida que a matrícula existe no helpdesk e também desbloqueia.
  AsyncAppResult<Unit> linkKba(
    String userId, {
    required int codigoEmpresa,
    required int matricula,
  }) {
    return runTask(() async {
      await _core.dio.put<dynamic>(
        '/kba/admin/users/$userId/link',
        data: {'codigoEmpresa': codigoEmpresa, 'matricula': matricula},
      );
      return unit;
    }, requiresNetwork: true);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) {
      throw const FormatException('Expected a JSON array response');
    }
    return data
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  T _parseObject<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object response');
    }
    return fromJson(data);
  }
}
