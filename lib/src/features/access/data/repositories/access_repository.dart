import 'package:gjamobile/src/features/access/domain/entities/user_access.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

class AccessRepository {
  AccessRepository(this._core);

  final CoreDio _core;

  AsyncAppResult<UserAccess> fetchCurrent() {
    return runTask(() async {
      final response = await _core.dio.get<dynamic>('/users/me');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid /users/me response');
      }
      return UserAccess.fromJson(data);
    }, requiresNetwork: true);
  }
}
