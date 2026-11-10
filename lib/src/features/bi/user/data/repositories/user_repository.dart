import 'package:dio/dio.dart';
import 'package:gjamobile/src/features/bi/shared/models/models.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

import '../models/colaborador_ref.dart';
import '../models/user_dashboard.dart';

/// Acesso ao painel "Performance Individual" (`GET /dashboards/user/{userId}`) e
/// à lista de colaboradores para o seletor (`GET /dashboards/colaboradores`).
class UserRepository {
  UserRepository(this._core);

  final CoreDio _core;
  Dio get _dio => _core.dio;

  static const _findUsuarioByEmail = '/usuarios/search/findByEmail';

  AsyncAppResult<UserDashboard> carregar(int userId, DashboardFilter filtro) {
    return runTask(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/dashboards/user/$userId',
        queryParameters: filtro.toQuery(),
      );
      return UserDashboard.fromJson(res.data ?? const <String, dynamic>{});
    }, requiresNetwork: true);
  }

  AsyncAppResult<List<ColaboradorRef>> colaboradores() {
    return runTask(() async {
      final res = await _dio.get<List<dynamic>>('/dashboards/colaboradores');
      return parseList(res.data, ColaboradorRef.fromJson);
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

    /// `_embedded.usuarios` — ausente quando não há match (coleção vazia).
  static List<Map<String, dynamic>> _parseUsuarios(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final embedded = data['_embedded'];
    if (embedded is! Map<String, dynamic>) return const [];
    final list = embedded['usuarios'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

}
