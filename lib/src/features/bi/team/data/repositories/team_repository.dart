import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/models/dashboard_filter.dart';
import '../models/team_dashboard.dart';

/// Acesso ao painel "Performance do Time" (`GET /dashboards/team`).
class TeamRepository {
  TeamRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  static const _path = '/dashboards/team';

  AsyncAppResult<TeamDashboard> carregar(DashboardFilter filtro) {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: filtro.toQuery(),
      );
      return TeamDashboard.fromJson(res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }
}
