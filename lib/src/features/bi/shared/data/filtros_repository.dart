import 'package:dio/dio.dart';

import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../models/filtro_opcao.dart';

/// Dados de referência da barra de filtros do BI (`GET /dashboards/filtros`).
class FiltrosRepository {
  FiltrosRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  AsyncAppResult<FiltrosReferencia> carregar() {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>('/dashboards/filtros');
      return FiltrosReferencia.fromJson(res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }
}
