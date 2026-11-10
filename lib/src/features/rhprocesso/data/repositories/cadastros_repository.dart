import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/rhprocesso/domain/entities/parametro.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/produto.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Cadastros da `rhprocesso-api`: características de produto (feature
/// `rhprocesso_caracteristicas`) e parâmetros gerais (`rhprocesso_parametros`).
class CadastrosRepository {
  CadastrosRepository(this._api, {bool exigeRede = true})
      : _exigeRede = exigeRede;

  final RhprocessoDio _api;
  final bool _exigeRede;

  Dio get _dio => _api.dio;

  static const _base = '/api/v1';

  // ── Características ──────────────────────────────────────────────────────

  AsyncAppResult<List<String>> grupos() => runTask(() async {
        final r = await _dio.get<List<dynamic>>('$_base/caracteristicas/grupos');
        return (r.data ?? const []).map((e) => '$e').toList(growable: false);
      }, requiresNetwork: _exigeRede);

  AsyncAppResult<List<String>> subgrupos(String grupo) => runTask(() async {
        final r = await _dio.get<List<dynamic>>(
          '$_base/caracteristicas/grupos/${Uri.encodeComponent(grupo)}/subgrupos',
        );
        return (r.data ?? const []).map((e) => '$e').toList(growable: false);
      }, requiresNetwork: _exigeRede);

  /// [caracterizados] `true`: produtos com característica; `false`: produtos
  /// ativos ainda sem característica.
  AsyncAppResult<List<Produto>> produtos({required bool caracterizados}) =>
      runTask(() async {
        final r = await _dio.get<List<dynamic>>(
          '$_base/produtos',
          queryParameters: {'caracterizado': caracterizados},
        );
        return (r.data ?? const [])
            .map((e) => Produto.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      }, requiresNetwork: _exigeRede);

  /// Associa (ou troca) a característica do produto.
  AsyncAppResult<Produto> associar(
    String codigo, {
    required String grupo,
    required String subgrupo,
    required double fator,
  }) =>
      runTask(() async {
        final r = await _dio.put<Map<String, dynamic>>(
          '$_base/produtos/${Uri.encodeComponent(codigo)}/caracteristica',
          data: {'grupo': grupo, 'subgrupo': subgrupo, 'fator': fator},
        );
        return Produto.fromJson(r.data ?? const {});
      }, requiresNetwork: _exigeRede);

  /// Remove a característica: o produto volta para a lista dos sem
  /// característica.
  AsyncAppResult<Unit> remover(String codigo) => runTask(() async {
        await _dio.delete<void>(
          '$_base/produtos/${Uri.encodeComponent(codigo)}/caracteristica',
        );
        return unit;
      }, requiresNetwork: _exigeRede);

  // ── Parâmetros ───────────────────────────────────────────────────────────

  AsyncAppResult<List<Parametro>> parametros() => runTask(() async {
        final r = await _dio.get<List<dynamic>>('$_base/parametros');
        return (r.data ?? const [])
            .map((e) => Parametro.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      }, requiresNetwork: _exigeRede);

  AsyncAppResult<Parametro> alterarParametro(
    int id, {
    required String descricao,
    required int valor,
  }) =>
      runTask(() async {
        final r = await _dio.put<Map<String, dynamic>>(
          '$_base/parametros/$id',
          data: {'descricao': descricao, 'valor': valor},
        );
        return Parametro.fromJson(r.data ?? const {});
      }, requiresNetwork: _exigeRede);
}
