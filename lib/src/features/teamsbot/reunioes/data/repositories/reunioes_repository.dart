import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/extensions/date_time_extension.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/models.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Acesso à API do pipeline de reuniões (`/api/meetings/...` e
/// `/api/meeting-minutes/...`) no backend TeamsBot.
class ReunioesRepository {
  ReunioesRepository(this._teamsbot);

  final TeamsbotDio _teamsbot;
  Dio get _dio => _teamsbot.dio;

  static const _meetings = '/api/meetings/monitored';

  // ── Reuniões monitoradas ─────────────────────────────────────────────────

  AsyncAppResult<List<MonitoredMeetingResumo>> listarMonitoradas({
    DateTime? de,
    DateTime? ate,
    String? usuario,
    String? statusReuniao,
    String? statusAta,
    bool? comTranscricao,
  }) {
    return runTask(() async {
      final response = await _dio.get<List<dynamic>>(
        _meetings,
        queryParameters: {
          if (de != null) 'de': de.toIso8601DateOnly,
          if (ate != null) 'ate': ate.toIso8601DateOnly,
          if (usuario != null && usuario.isNotEmpty) 'usuario': usuario,
          if (statusReuniao != null) 'statusReuniao': statusReuniao,
          if (statusAta != null) 'statusAta': statusAta,
          if (comTranscricao != null) 'comTranscricao': comTranscricao,
        },
      );
      return (response.data ?? [])
          .map((e) => MonitoredMeetingResumo.fromJson(e as Map<String, dynamic>))
          .toList();
    }, requiresNetwork: true);
  }

  AsyncAppResult<MonitoredMeetingDetalhe> detalheMonitorada(int meetingId) {
    return runTask(() async {
      final response =
          await _dio.get<Map<String, dynamic>>('$_meetings/$meetingId');
      return MonitoredMeetingDetalhe.fromJson(response.data!);
    }, requiresNetwork: true);
  }

  AsyncAppResult<List<Participante>> participantes(int meetingId) {
    return runTask(() async {
      final response =
          await _dio.get<List<dynamic>>('$_meetings/$meetingId/participants');
      return (response.data ?? [])
          .map((e) => Participante.fromJson(e as Map<String, dynamic>))
          .toList();
    }, requiresNetwork: true);
  }

  AsyncAppResult<TranscricaoStatus> transcricao(int meetingId) {
    return runTask(() async {
      final response =
          await _dio.get<Map<String, dynamic>>('$_meetings/$meetingId/transcription');
      return TranscricaoStatus.fromJson(response.data!);
    }, requiresNetwork: true);
  }

  AsyncAppResult<TranscricaoConteudo> transcricaoConteudo(int meetingId) {
    return runTask(() async {
      final response = await _dio.get<Map<String, dynamic>>(
          '$_meetings/$meetingId/transcription/content');
      return TranscricaoConteudo.fromJson(response.data!);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> reprocessar(int meetingId) {
    return runTask(() async {
      await _dio.post<void>('$_meetings/$meetingId/reprocess');
      return unit;
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> enfileirar(int meetingId) {
    return runTask(() async {
      await _dio.post<void>('$_meetings/$meetingId/enqueue');
      return unit;
    }, requiresNetwork: true);
  }

  AsyncAppResult<MeetingMinutesStatus> statusMinutes(int meetingId) {
    return runTask(() async {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/meeting-minutes/$meetingId/status');
      return MeetingMinutesStatus.fromJson(response.data!);
    }, requiresNetwork: true);
  }
}
