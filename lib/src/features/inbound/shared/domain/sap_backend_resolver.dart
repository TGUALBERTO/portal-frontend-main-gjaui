import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/sap_backend.dart';

/// Identidade do usuário logado perante o SAP: qual Gateway o atende e com que
/// matrícula ele assina as escritas.
///
/// Existe como interface por duas razões práticas:
///
/// - **testabilidade**: o [AccessController] arrasta `AccessRepository` →
///   `CoreDio` → `AppConfig.init()`, o que torna inviável construir um
///   controller de inbound num teste unitário. Com a interface, o teste passa um
///   fake em duas linhas.
/// - **um dono só para o override de desenvolvimento**: o desvio de matrícula
///   para o SAP da Vitamedic estava inline no controller de veículos e seria
///   copiado para cada nova tela de inbound. Agora mora aqui.
abstract interface class SapBackendResolver {
  /// `null` quando a empresa do usuário não tem SAP mapeado — a tela mostra um
  /// erro claro em vez de escolher um backend padrão em silêncio, o que
  /// liberaria carga no SAP errado.
  BackendService? resolve();

  /// Nome da empresa, para compor a mensagem quando [resolve] devolve `null`.
  String get descricaoEmpresa;

  /// Matrícula do usuário logado, no formato que vai nos campos de autoria das
  /// escritas SAP (`Crenam`).
  ///
  /// `null` quando o usuário não tem vínculo de funcionário. Quem grava deve
  /// **bloquear** nesse caso em vez de mandar string vazia: registro de
  /// auditoria sem autor é pior que a tela travada, e o portal já tem fluxo
  /// próprio para resolver o vínculo.
  ///
  /// Mora aqui, e não numa interface própria, porque esta já é *a* costura
  /// entre o `AccessController` e o inbound — a implementação abaixo lê
  /// `employeeLink.matricula` desde o override de desenvolvimento.
  String? get matricula;
}

class AccessSapBackendResolver implements SapBackendResolver {
  AccessSapBackendResolver(this._access);

  final AccessController _access;

  @override
  BackendService? resolve() {
    final link = _access.employeeLink;
    return sapBackendForEmpresa(link?.empresa);
  }

  @override
  String get descricaoEmpresa =>
      _access.employeeLink?.empresa?.razaoSocial ?? 'não informada';

  @override
  String? get matricula => _access.employeeLink?.matricula?.toString();
}
