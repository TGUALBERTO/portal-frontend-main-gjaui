import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/models/dashboard_filter.dart';
import '../models/executive_dashboard.dart';

/// Acesso ao dashboard executivo (`GET /dashboards/executive`) no backend core.
class ExecutiveRepository {
  ExecutiveRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  static const _path = '/dashboards/executive';

  AsyncAppResult<ExecutiveDashboard> carregar(DashboardFilter filtro) {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: filtro.toQuery(),
      );
      return ExecutiveDashboard.fromJson(res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }
}
