import 'package:dio/dio.dart';

import 'package:gjamobile/src/features/teamsbot/fila/data/models/models.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Acesso à fila FIFO de criação de ATAs (`/api/meeting-minutes/queue`) no
/// backend TeamsBot.
class FilaRepository {
  FilaRepository(this._teamsbot);

  final TeamsbotDio _teamsbot;
  Dio get _dio => _teamsbot.dio;

  static const _queue = '/api/meeting-minutes/queue';

  AsyncAppResult<List<FilaItem>> listarFila({String? status}) {
    return runTask(() async {
      final response = await _dio.get<List<dynamic>>(
        _queue,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return (response.data ?? [])
          .map((e) => FilaItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }, requiresNetwork: true);
  }

  AsyncAppResult<FilaItem> detalheFila(int queueId) {
    return runTask(() async {
      final response = await _dio.get<Map<String, dynamic>>('$_queue/$queueId');
      return FilaItem.fromJson(response.data!);
    }, requiresNetwork: true);
  }

  AsyncAppResult<FilaItem> retryFila(int queueId) {
    return runTask(() async {
      final response =
          await _dio.post<Map<String, dynamic>>('$_queue/$queueId/retry');
      return FilaItem.fromJson(response.data!);
    }, requiresNetwork: true);
  }
}
