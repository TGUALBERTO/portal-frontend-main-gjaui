import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/models/dashboard_filter.dart';
import '../models/tipo_chamado_dashboard.dart';

/// Acesso aos painéis por tipo de chamado no backend core. O [path] varia por
/// tela (`/dashboards/incidents`, `/dashboards/requests`, `/dashboards/change`),
/// todos com o mesmo contrato de resposta.
class TipoChamadoRepository {
  TipoChamadoRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  AsyncAppResult<TipoChamadoDashboard> carregar(
    String path,
    DashboardFilter filtro,
  ) {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: filtro.toQuery(),
      );
      return TipoChamadoDashboard.fromJson(
          res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }
}
