import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/models/dashboard_filter.dart';
import '../models/company_dashboard.dart';

/// Acesso ao "Comparativo por Empresa" (`GET /dashboards/company`) no backend core.
class CompanyRepository {
  CompanyRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  static const _path = '/dashboards/company';

  AsyncAppResult<CompanyDashboard> carregar(DashboardFilter filtro) {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: filtro.toQuery(),
      );
      return CompanyDashboard.fromJson(res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }
}
