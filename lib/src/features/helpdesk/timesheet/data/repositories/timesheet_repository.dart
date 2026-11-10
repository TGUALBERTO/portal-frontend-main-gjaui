import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/catraca_acesso.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/ponto_dia.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:result_dart/result_dart.dart';

/// Repositório da feature Timesheet (backend `core`).
class TimesheetRepository {
  TimesheetRepository(this._core);

  final CoreDio _core;

  static const _findByMatriculaAndDataBetween =
      '/acessos/search/findByMatriculaAndDataBetween';
  static const _findPontosByMatriculaAndDataBetween =
      '/pontos/search/findByMatriculaAndDataBetween';
  static const _findUsuarioByEmail = '/usuarios/search/findByEmail';
  static const _findByUsersIdTechAndDateBetween =
      '/chamados-tarefas/search/findByUsersIdTechAndDateBetween';
  static const _findChamadosByOrigemIds =
      '/chamados/search/findByOrigemIdIn';
  static const _buscarChamados = '/chamados/search/buscar';
  static const _apontamentos = '/helpdesk/apontamentos';
  static const _pageSize = 200;
  static const _chamadosPageSize = 20;

  /// Histórico de catraca do funcionário no intervalo [dataIni]–[dataFim]
  /// (inclusivo). O endpoint é paginado (HAL / Spring Data REST); busca todas
  /// as páginas e devolve a lista completa, ordenada por `data` desc.
  AsyncAppResult<List<CatracaAcesso>> fetchAcessos({
    required String matricula,
    required DateTime dataIni,
    required DateTime dataFim,
  }) {
    return runTask(() async {
      final all = <CatracaAcesso>[];
      var page = 0;
      int totalPages;
      do {
        final response = await _core.dio.get<Map<String, dynamic>>(
          _findByMatriculaAndDataBetween,
          queryParameters: {
            'matricula': matricula,
            'dataIni': dateTimeParam(dataIni),
            'dataFim': dateTimeParam(dataFim),
            'page': page,
            'size': _pageSize,
            'sort': 'data,desc',
          },
        );
        final data = response.data;
        if (data == null) {
          throw const FormatException(
            'Resposta inválida de $_findByMatriculaAndDataBetween',
          );
        }
        all.addAll(_parseAcessos(data));
        totalPages = _totalPages(data);
        page++;
      } while (page < totalPages);
      return all;
    }, requiresNetwork: true);
  }

  /// Pontos diários (primeira/última marcação do relógio de ponto) do
  /// funcionário no intervalo [dataIni]–[dataFim] (inclusivo, só a data é
  /// considerada). O endpoint é paginado (HAL / Spring Data REST); busca todas
  /// as páginas e devolve a lista completa, ordenada por `data` desc.
  AsyncAppResult<List<PontoDia>> fetchPontos({
    required String matricula,
    required DateTime dataIni,
    required DateTime dataFim,
  }) {
    return runTask(() async {
      final all = <PontoDia>[];
      var page = 0;
      int totalPages;
      do {
        final response = await _core.dio.get<Map<String, dynamic>>(
          _findPontosByMatriculaAndDataBetween,
          queryParameters: {
            'matricula': matricula,
            'dataIni': dateParam(dataIni),
            'dataFim': dateParam(dataFim),
            'page': page,
            'size': _pageSize,
            'sort': 'data,desc',
          },
        );
        final data = response.data;
        if (data == null) {
          throw const FormatException(
            'Resposta inválida de $_findPontosByMatriculaAndDataBetween',
          );
        }
        all.addAll(_parsePontos(data));
        totalPages = _totalPages(data);
        page++;
      } while (page < totalPages);
      return all;
    }, requiresNetwork: true);
  }

  /// Resolve o id do usuário helpdesk (GLPI) a partir do e-mail do portal
  /// (`UsuarioRepository.findByEmail`).
  ///
  /// O endpoint responde uma coleção HAL (`_embedded.usuarios`) ordenada do
  /// melhor candidato para o pior — de propósito: o e-mail não é único e uma
  /// resposta de coleção evita o bug do `HttpHeadersPreparer` do Spring Data
  /// REST no caminho de entidade única (ver `UsuarioRepository`).
  ///
  /// - Sucesso → `Success(id)` (id do 1º item, de `_links.self.href`).
  /// - Coleção vazia → sintetiza `ApiFailure(status: 404)`; o chamador trata
  ///   como "sem conta helpdesk" (não é erro a exibir), distinguindo de falhas
  ///   de rede/servidor.
  /// - Item sem id parseável → `ServerFailure` (anomalia real, propagada).
  AsyncAppResult<int> fetchUsuarioId({required String email}) {
    return runTask(() async {
      final response = await _core.dio.get<Map<String, dynamic>>(
        _findUsuarioByEmail,
        queryParameters: {'email': email},
      );
      final usuarios = _parseUsuarios(response.data);
      if (usuarios.isEmpty) {
        throw const ApiFailure(
          'Usuário helpdesk não encontrado',
          status: 404,
        );
      }
      final id = Apontamento.idFromLinks(usuarios.first);
      if (id == null) {
        throw const FormatException(
          'findByEmail: sem id parseável em _links.self.href',
        );
      }
      return id;
    }, requiresNetwork: true);
  }

  /// Chamados por id de origem (GLPI), em uma única chamada
  /// (`ChamadoRepository.findByOrigemIdIn`). Retorna `origemId → chamado`;
  /// chamados não encontrados simplesmente ficam de fora do mapa.
  ///
  /// É a mesma representação HAL que o autocomplete consome, então cada item
  /// traz também o UUID do portal no `_links.self.href` — é ele que o POST de
  /// apontamento exige, e é o que permite duplicar um apontamento (que só
  /// carrega o `ticketsId` do GLPI) sem nenhuma busca extra.
  AsyncAppResult<Map<int, Chamado>> fetchChamadosPorOrigem({
    required Set<int> origemIds,
  }) {
    return runTask(() async {
      if (origemIds.isEmpty) return const <int, Chamado>{};
      final response = await _core.dio.get<Map<String, dynamic>>(
        _findChamadosByOrigemIds,
        queryParameters: {'origemIds': origemIds.join(',')},
      );
      final data = response.data;
      if (data == null) return const <int, Chamado>{};
      return {
        // `origemId` cai para 0 quando o campo falta — chave inútil, fora.
        for (final chamado in _parseChamados(data))
          if (chamado.origemId != 0) chamado.origemId: chamado,
      };
    }, requiresNetwork: true);
  }

  /// `_embedded.usuarios` — ausente quando não há match (coleção vazia).
  static List<Map<String, dynamic>> _parseUsuarios(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final embedded = data['_embedded'];
    if (embedded is! Map<String, dynamic>) return const [];
    final list = embedded['usuarios'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Apontamentos (tarefas de chamado) do usuário [usuarioId] no intervalo
  /// [dataIni]–[dataFim] (inclusivo). Paginado (HAL / Spring Data REST); busca
  /// todas as páginas e devolve a lista completa, ordenada por `date` desc.
  AsyncAppResult<List<Apontamento>> fetchApontamentos({
    required int usuarioId,
    required DateTime dataIni,
    required DateTime dataFim,
  }) {
    return runTask(() async {
      final all = <Apontamento>[];
      var page = 0;
      int totalPages;
      do {
        final response = await _core.dio.get<Map<String, dynamic>>(
          _findByUsersIdTechAndDateBetween,
          queryParameters: {
            'usuarioId': usuarioId,
            'dataIni': dateTimeParam(dataIni),
            'dataFim': dateTimeParam(dataFim),
            'page': page,
            'size': _pageSize,
            'sort': 'date,desc',
          },
        );
        final data = response.data;
        if (data == null) {
          throw const FormatException(
            'Resposta inválida de $_findByUsersIdTechAndDateBetween',
          );
        }
        all.addAll(_parseApontamentos(data));
        totalPages = _totalPages(data);
        page++;
      } while (page < totalPages);
      return all;
    }, requiresNetwork: true);
  }

  /// Busca chamados para o autocomplete de apontamento — por trecho do título
  /// ou id de origem exato quando [termo] é numérico (HAL / Spring Data REST,
  /// primeira página é suficiente para seleção).
  AsyncAppResult<List<Chamado>> searchChamados({required String termo}) {
    return runTask(() async {
      final response = await _core.dio.get<Map<String, dynamic>>(
        _buscarChamados,
        queryParameters: {
          'termo': termo,
          'page': 0,
          'size': _chamadosPageSize,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Resposta inválida de $_buscarChamados');
      }
      return _parseChamados(data).toList();
    }, requiresNetwork: true);
  }

  /// Cria um apontamento (tarefa de chamado) via endpoint custom do backend —
  /// quem fala com o GLPI é só o backend.
  AsyncAppResult<Unit> criarApontamento({
    required String chamadoId,
    required DateTime inicio,
    required DateTime fim,
    required String descricao,
    required bool privado,
  }) {
    return runTask(() async {
      await _core.dio.post<dynamic>(_apontamentos, data: {
        'chamadoId': chamadoId,
        'inicio': dateTimeParam(inicio),
        'fim': dateTimeParam(fim),
        'descricao': descricao,
        'privado': privado,
      });
      return unit;
    }, requiresNetwork: true);
  }

  /// Edita um apontamento enviando **apenas** os campos alterados — o backend
  /// repassa esse mesmo recorte ao GLPI (`PUT /TicketTask` com o id + o diff),
  /// preservando o que ninguém mexeu. Campo nulo = não mudou.
  ///
  /// O chamado não é editável: um apontamento não muda de ticket.
  AsyncAppResult<Unit> atualizarApontamento({
    required int id,
    DateTime? inicio,
    DateTime? fim,
    String? descricao,
    bool? privado,
  }) {
    return runTask(() async {
      await _core.dio.put<dynamic>('$_apontamentos/$id', data: {
        if (inicio != null) 'inicio': dateTimeParam(inicio),
        if (fim != null) 'fim': dateTimeParam(fim),
        if (descricao != null) 'descricao': descricao,
        if (privado != null) 'privado': privado,
      });
      return unit;
    }, requiresNetwork: true);
  }

  /// Exclui um apontamento (no GLPI e na cópia local do portal).
  AsyncAppResult<Unit> excluirApontamento({required int id}) {
    return runTask(() async {
      await _core.dio.delete<dynamic>('$_apontamentos/$id');
      return unit;
    }, requiresNetwork: true);
  }

  /// `_embedded.chamados` — ausente quando a página vem vazia.
  static Iterable<Chamado> _parseChamados(Map<String, dynamic> data) {
    final embedded = data['_embedded'];
    if (embedded is! Map<String, dynamic>) return const [];
    final list = embedded['chamados'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().map(Chamado.fromHal);
  }

  /// `_embedded.acessos` — ausente quando a página vem vazia.
  static Iterable<CatracaAcesso> _parseAcessos(Map<String, dynamic> data) {
    final embedded = data['_embedded'];
    if (embedded is! Map<String, dynamic>) return const [];
    final list = embedded['acessos'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().map(CatracaAcesso.fromJson);
  }

  /// `_embedded.pontos` — ausente quando a página vem vazia.
  static Iterable<PontoDia> _parsePontos(Map<String, dynamic> data) {
    final embedded = data['_embedded'];
    if (embedded is! Map<String, dynamic>) return const [];
    final list = embedded['pontos'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().map(PontoDia.fromJson);
  }

  /// `_embedded.chamados-tarefas` — ausente quando a página vem vazia
  /// (`collectionResourceRel` do `ChamadoTarefaRepository`).
  static Iterable<Apontamento> _parseApontamentos(Map<String, dynamic> data) {
    final embedded = data['_embedded'];
    if (embedded is! Map<String, dynamic>) return const [];
    final list = embedded['chamados-tarefas'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().map(Apontamento.fromJson);
  }

  static int _totalPages(Map<String, dynamic> data) {
    final pageInfo = data['page'];
    if (pageInfo is! Map<String, dynamic>) return 1;
    return (pageInfo['totalPages'] as num?)?.toInt() ?? 1;
  }
}
