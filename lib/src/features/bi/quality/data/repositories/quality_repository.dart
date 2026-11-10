import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/models/dashboard_filter.dart';
import '../models/quality_dashboard.dart';

/// Acesso ao painel de Qualidade (`GET /dashboards/quality`).
class QualityRepository {
  QualityRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  static const _path = '/dashboards/quality';

  AsyncAppResult<QualityDashboard> carregar(DashboardFilter filtro) {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: filtro.toQuery(),
      );
      return QualityDashboard.fromJson(res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }
}
