import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado_resumo.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/meus_chamados_filtro.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Chamados do usuário logado (backend `core`, endpoint custom do helpdesk).
///
/// Separado do [TimesheetRepository] porque fala outro contrato: aquele consome
/// HAL/Spring Data REST (`_embedded`, `page.totalPages`) e varre todas as
/// páginas; este consome um DTO JSON plano e pagina sob demanda, já que a lista
/// de chamados de um técnico pode ter centenas de itens.
///
/// O endpoint **não** recebe o id do usuário: o backend o resolve do token, para
/// que ninguém consiga listar os chamados de outra pessoa.
class MeusChamadosRepository {
  MeusChamadosRepository(this._core);

  final CoreDio _core;

  static const _meusChamados = '/helpdesk/meus-chamados';

  /// Uma página de chamados do usuário. Falha de rede/servidor volta como
  /// `AppFailure`; um 404 significa que o módulo helpdesk está desligado neste
  /// ambiente — o painel trata isso como indisponibilidade, não como erro.
  AsyncAppResult<PaginaChamados> buscar({
    required MeusChamadosFiltro filtro,
    required int page,
    int size = 20,
    String sort = 'dataCriacao,desc',
  }) {
    return runTask(() async {
      final termo = filtro.termo.trim();
      final response = await _core.dio.get<Map<String, dynamic>>(
        _meusChamados,
        queryParameters: {
          if (filtro.dataIni != null) 'dataIni': dateParam(filtro.dataIni!),
          if (filtro.dataFim != null) 'dataFim': dateParam(filtro.dataFim!),
          if (filtro.empresaNome != null) 'empresaNome': filtro.empresaNome,
          if (filtro.urgencia != null) 'urgencia': filtro.urgencia,
          if (filtro.status != null) 'status': filtro.status,
          'apenasAbertos': filtro.apenasAbertos,
          if (filtro.tipoVinculo != null)
            'tipoVinculo': filtro.tipoVinculo!.codigo,
          if (termo.isNotEmpty) 'termo': termo,
          'page': page,
          'size': size,
          'sort': sort,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Resposta inválida de $_meusChamados');
      }
      return PaginaChamados.fromJson(data);
    }, requiresNetwork: true);
  }
}
