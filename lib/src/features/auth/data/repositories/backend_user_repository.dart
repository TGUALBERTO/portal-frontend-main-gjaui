import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Syncs the authenticated Microsoft user with the backend. The Dio interceptor
/// attaches the Bearer access token and the backend extracts claims directly
/// from the validated JWT — no body needed. Talks to the [CoreDio] backend.
class BackendUserRepository {
  BackendUserRepository(this._core);

  final CoreDio _core;

  AsyncAppResult<Map<String, dynamic>> sync() {
    return runTask(() async {
      final response = await _core.dio.post<dynamic>('/users/sync');
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      throw const FormatException('Invalid /users/sync response');
    }, requiresNetwork: true);
  }

  AsyncAppResult<Map<String, dynamic>> me() {
    return runTask(() async {
      final response = await _core.dio.get<dynamic>('/users/me');
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      throw const FormatException('Invalid /users/me response');
    }, requiresNetwork: true);
  }
}
