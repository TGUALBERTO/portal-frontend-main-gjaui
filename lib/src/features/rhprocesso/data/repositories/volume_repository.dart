import 'package:dio/dio.dart';

import 'package:gjamobile/src/features/rhprocesso/data/resposta_arquivo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/consulta_volume.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/enums/visao_equipe.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Volume x NF na `rhprocesso-api`: períodos, consulta, DANFE e planilha.
/// Feature `rhprocesso_volume`; o Bearer é anexado pelo interceptor do Dio.
class VolumeRepository {
  VolumeRepository(this._api, {bool exigeRede = true}) : _exigeRede = exigeRede;

  final RhprocessoDio _api;

  /// `false` só nos testes: a checagem de conexão do `runTask` acessa a rede.
  final bool _exigeRede;

  Dio get _dio => _api.dio;

  static const _base = '/api/v1';

  /// O DANFE de um supervisor com várias filiais passa dos 30 s padrão do Dio:
  /// a API monta o PDF inteiro antes do primeiro byte.
  static const tempoGeracao = Duration(minutes: 5);

  /// Períodos disponíveis, do mais recente para o mais antigo.
  AsyncAppResult<List<Periodo>> periodos() => runTask(() async {
        final r = await _dio.get<List<dynamic>>('$_base/periodos');
        return (r.data ?? const [])
            .map((e) => Periodo.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      }, requiresNetwork: _exigeRede);

  /// Detalhe, notas, resumo por característica e totais da equipe no período.
  /// `404` quando a matrícula não existe na estrutura comercial do período.
  AsyncAppResult<ConsultaVolume> consultar(
    VisaoEquipe visao,
    String matricula,
    Periodo periodo,
  ) =>
      runTask(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '$_base/${visao.recurso}/${Uri.encodeComponent(matricula)}/volume',
          queryParameters: {'periodo': periodo.valor},
        );
        return ConsultaVolume.fromJson(r.data ?? const {});
      }, requiresNetwork: _exigeRede);

  /// PDF com os DANFEs da equipe no período.
  AsyncAppResult<ArquivoGerado> danfe(
    VisaoEquipe visao,
    String matricula,
    Periodo periodo,
  ) =>
      _baixar(visao, matricula, periodo, 'danfe.pdf');

  /// Planilha `.xlsx` do detalhe de volume.
  AsyncAppResult<ArquivoGerado> planilha(
    VisaoEquipe visao,
    String matricula,
    Periodo periodo,
  ) =>
      _baixar(visao, matricula, periodo, 'volume.xlsx');

  AsyncAppResult<ArquivoGerado> _baixar(
    VisaoEquipe visao,
    String matricula,
    Periodo periodo,
    String recurso,
  ) =>
      runTask(() async {
        try {
          final r = await _dio.get<List<int>>(
            '$_base/${visao.recurso}/${Uri.encodeComponent(matricula)}/$recurso',
            queryParameters: {'periodo': periodo.valor},
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: tempoGeracao,
              headers: {'Accept': '*/*'},
            ),
          );
          final extensao = recurso.substring(recurso.lastIndexOf('.'));
          return arquivoDaResposta(r, '${periodo.valor}_$matricula$extensao');
        } on DioException catch (e) {
          throw comCorpoDecodificado(e);
        }
      }, requiresNetwork: _exigeRede);
}
