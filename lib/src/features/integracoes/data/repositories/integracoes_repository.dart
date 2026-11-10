import 'package:dio/dio.dart';

import 'package:gjamobile/src/features/integracoes/data/models/models.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Acesso aos processos de integracao (`/integracoes`) no backend `core`.
///
/// Todos os endpoints exigem ADMIN; o Bearer e anexado pelo interceptor do
/// [CoreDio].
class IntegracoesRepository {
  IntegracoesRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  static const _base = '/integracoes';

  /// Catalogo completo, incluindo os processos desativados no ambiente.
  AsyncAppResult<List<ProcessoIntegracao>> listar() {
    return runTask(() async {
      final response = await _dio.get<List<dynamic>>(_base);
      return (response.data ?? [])
          .map((e) => ProcessoIntegracao.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }, requiresNetwork: true);
  }

  /// Historico recente de um processo, do mais novo para o mais antigo.
  AsyncAppResult<List<ExecucaoIntegracao>> historico(
    String nome, {
    int limite = 20,
  }) {
    return runTask(() async {
      final response = await _dio.get<List<dynamic>>(
        '$_base/$nome/execucoes',
        queryParameters: {'limite': limite},
      );
      return (response.data ?? [])
          .map((e) => ExecucaoIntegracao.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }, requiresNetwork: true);
  }

  /// Dispara o processo agora. O backend responde 409 quando outro processo do
  /// mesmo grupo esta executando ou quando a integracao esta desativada.
  AsyncAppResult<ExecucaoIntegracao> executarAgora(String nome) {
    return runTask(() async {
      final response =
          await _dio.post<Map<String, dynamic>>('$_base/$nome/executar');
      return ExecucaoIntegracao.fromJson(response.data ?? const {});
    }, requiresNetwork: true);
  }
}
