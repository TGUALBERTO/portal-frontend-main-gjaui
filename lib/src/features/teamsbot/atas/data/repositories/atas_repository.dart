import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/teamsbot/atas/data/models/models.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Acesso à API de ATAs (`/api/atas`) no backend TeamsBot.
///
/// Todos os métodos retornam [AsyncAppResult] via [runTask] (`requiresNetwork`),
/// que mapeia exceções para [AppFailure] (incl. [ApiFailure] com o status HTTP).
class AtasRepository {
  AtasRepository(this._teamsbot);

  final TeamsbotDio _teamsbot;
  Dio get _dio => _teamsbot.dio;

  static const _base = '/api/atas';

  // ── Leituras ───────────────────────────────────────────────────────────

  AsyncAppResult<List<AtaResumo>> listar({
    String? status,
    String? empresa,
  }) {
    return runTask(() async {
      final response = await _dio.get<List<dynamic>>(
        _base,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (empresa != null && empresa.isNotEmpty) 'empresa': empresa,
        },
      );
      return (response.data ?? [])
          .map((e) => AtaResumo.fromJson(e as Map<String, dynamic>))
          .toList();
    }, requiresNetwork: true);
  }

  AsyncAppResult<AtaDetalhe> detalhe(int id) {
    return runTask(() async {
      final response = await _dio.get<Map<String, dynamic>>('$_base/$id');
      return AtaDetalhe.fromJson(response.data!);
    }, requiresNetwork: true);
  }

  AsyncAppResult<String> markdown(int id) {
    return runTask(() async {
      final response = await _dio.get<String>(
        '$_base/$id/markdown',
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    }, requiresNetwork: true);
  }

  /// Baixa a ATA em Word (.docx) no formato executivo (template GJA).
  AsyncAppResult<Uint8List> docx(int id) {
    return runTask(() async {
      final response = await _dio.get<List<int>>(
        '$_base/$id/docx',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    }, requiresNetwork: true);
  }

  // ── Escritas ───────────────────────────────────────────────────────────

  AsyncAppResult<Unit> gerar(GerarAtaRequest req) {
    return runTask(() async {
      await _dio.post<void>('$_base/gerar', data: req.toJson());
      return unit;
    }, requiresNetwork: true);
  }

  AsyncAppResult<AtaDetalhe> editar(int id, String markdown) {
    return runTask(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_base/$id/editar',
        data: {'markdown': markdown},
      );
      return AtaDetalhe.fromJson(response.data!);
    }, requiresNetwork: true);
  }

  AsyncAppResult<Unit> indexar(int id) {
    return runTask(() async {
      await _dio.post<void>('$_base/$id/indexar');
      return unit;
    }, requiresNetwork: true);
  }

  /// Dispara o (re)envio do .docx desta ATA ao SharePoint (202, assíncrono).
  ///
  /// Cobre o backfill de ATAs geradas antes da integração (status nulo). O corpo
  /// da resposta (estado do envio) é ignorado — recarregamos o detalhe em seguida.
  /// 404 quando a ATA não existe; 409 quando a integração está desligada, a ATA
  /// está cancelada ou já há um envio em andamento.
  AsyncAppResult<Unit> reenviarSharepoint(int id) {
    return runTask(() async {
      await _dio.post<void>('$_base/$id/sharepoint/reenviar');
      return unit;
    }, requiresNetwork: true);
  }
}
