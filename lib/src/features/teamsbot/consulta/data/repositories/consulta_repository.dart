import 'package:dio/dio.dart';

import 'package:gjamobile/src/features/teamsbot/consulta/data/models/models.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Acesso à consulta RAG de ATAs (`POST /api/atas/consultar`) e ao histórico
/// de consultas do usuário (`GET /api/atas/consultas`).
class ConsultaRepository {
  ConsultaRepository(this._teamsbot);

  final TeamsbotDio _teamsbot;
  Dio get _dio => _teamsbot.dio;

  AsyncAppResult<RagResposta> consultar(ConsultaRequest req) {
    return runTask(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/atas/consultar',
        data: req.toJson(),
      );
      return RagResposta.fromJson(response.data!);
    }, requiresNetwork: true);
  }

  /// Histórico de consultas do usuário, da mais recente para a mais antiga.
  AsyncAppResult<List<ConsultaHistoricoItem>> historico(String usuarioId) {
    return runTask(() async {
      final response = await _dio.get<List<dynamic>>(
        '/api/atas/consultas',
        queryParameters: {'usuarioId': usuarioId},
      );
      return (response.data ?? const [])
          .map((e) => ConsultaHistoricoItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }, requiresNetwork: true);
  }
}
