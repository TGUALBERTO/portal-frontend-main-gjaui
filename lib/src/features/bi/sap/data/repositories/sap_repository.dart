import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/models/dashboard_filter.dart';
import '../models/sap_dashboard.dart';

/// Acesso ao painel combinado "Visão SAP e Multiplataforma"
/// (`GET /dashboards/sap-multiplataforma`).
class SapRepository {
  SapRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  static const _path = '/dashboards/sap-multiplataforma';

  AsyncAppResult<SapDashboard> carregar(DashboardFilter filtro) {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: filtro.toQuery(),
      );
      return SapDashboard.fromJson(res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }
}
