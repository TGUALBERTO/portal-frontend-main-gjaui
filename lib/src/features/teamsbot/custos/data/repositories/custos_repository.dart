import 'package:dio/dio.dart';

import 'package:gjamobile/src/extensions/date_time_extension.dart';
import 'package:gjamobile/src/features/teamsbot/custos/data/models/custo.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Acesso ao relatório de custos de IA (`GET /api/atas/custos`).
class CustosRepository {
  CustosRepository(this._teamsbot);

  final TeamsbotDio _teamsbot;
  Dio get _dio => _teamsbot.dio;

  AsyncAppResult<CustoRelatorio> custos({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    return runTask(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/atas/custos',
        queryParameters: {
          if (dataInicio != null) 'dataInicio': dataInicio.toIso8601DateOnly,
          if (dataFim != null) 'dataFim': dataFim.toIso8601DateOnly,
        },
      );
      return CustoRelatorio.fromJson(response.data!);
    }, requiresNetwork: true);
  }
}
