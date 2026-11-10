import 'package:dio/dio.dart';

import 'package:gjamobile/src/features/rhprocesso/domain/entities/estrutura_rota.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estrutura comercial na `rhprocesso-api` (feature `rhprocesso_estrutura`):
/// períodos do Workflow, listagem, importação e manutenção de rota.
class EstruturaRepository {
  EstruturaRepository(this._api, {bool exigeRede = true})
      : _exigeRede = exigeRede;

  final RhprocessoDio _api;
  final bool _exigeRede;

  Dio get _dio => _api.dio;

  static const _base = '/api/v1/estrutura-comercial';

  /// Períodos que o Workflow (Oracle) tem para importar.
  AsyncAppResult<List<Periodo>> periodosWorkflow() => runTask(() async {
        final r = await _dio.get<List<dynamic>>('$_base/periodos-workflow');
        return (r.data ?? const [])
            .map((e) => Periodo('$e'))
            .toList(growable: false);
      }, requiresNetwork: _exigeRede);

  /// Rotas do período no RH Processo.
  AsyncAppResult<List<EstruturaRota>> listar(Periodo periodo) =>
      runTask(() async {
        final r = await _dio.get<List<dynamic>>(
          _base,
          queryParameters: {'periodo': periodo.valor},
        );
        return (r.data ?? const [])
            .map((e) => EstruturaRota.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      }, requiresNetwork: _exigeRede);

  /// Importa do Workflow as rotas que o período ainda não tem (as existentes
  /// não são alteradas).
  AsyncAppResult<ResultadoImportacao> importar(Periodo periodo) =>
      runTask(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '$_base/importacoes',
          data: {'periodo': periodo.valor},
        );
        return ResultadoImportacao.fromJson(r.data ?? const {});
      }, requiresNetwork: _exigeRede);

  /// Troca a hierarquia de uma rota do período.
  AsyncAppResult<EstruturaRota> alterar(EstruturaRota rota) =>
      runTask(() async {
        final r = await _dio.put<Map<String, dynamic>>(
          '$_base/${rota.periodo}/${Uri.encodeComponent(rota.unidade)}'
          '/${Uri.encodeComponent(rota.rota)}',
          data: rota.toAlteracaoJson(),
        );
        return EstruturaRota.fromJson(r.data ?? const {});
      }, requiresNetwork: _exigeRede);
}
