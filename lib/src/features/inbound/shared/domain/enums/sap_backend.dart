import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/access/domain/enums/empresas.dart';

/// Resolve qual SAP Gateway atende a [empresa] do usuário logado.
///
/// Mapeamento **estrito**: só as três empresas que possuem SAP hoje. Retorna
/// `null` para empresa nula (usuário sem `employeeLink`) ou não mapeada — a
/// tela mostra um erro claro em vez de escolher um backend padrão em silêncio,
/// o que liberaria caminhão no SAP errado.
///
/// As demais 23 empresas de [Empresa] (Rebic*, Rembal, Atlanta, autônomos,
/// educacionais…) estão fora de propósito. Quando uma delas ganhar SAP, basta
/// acrescentar o `case` aqui.
BackendService? sapBackendForEmpresa(Empresa? empresa) => switch (empresa) {
      Empresa.refrescosBandeirantes => BackendService.sapBandeirantes, // 1
      Empresa.nel => BackendService.sapNel, // 6
      Empresa.vitamedic => BackendService.sapVitamedic, // 15
      _ => null,
    };

/// Em que produto SAP a empresa roda.
///
/// Não é detalhe de infraestrutura: decide **qual contrato OData** atende a
/// operação. No S/4HANA o inbound consome serviços gerados por CDS
/// (`ZGJAAUTO_SB_GENERIC`, com `$expand` e propriedades renomeadas pela view);
/// no ECC não há CDS, e o equivalente foi reconstruído com SEGW dentro do
/// `ZGJAAUTO_GENERIC_SRV` — outros entity sets, outros nomes de propriedade.
///
/// O host continua saindo da empresa, por [sapBackendForEmpresa]. O que muda
/// com a plataforma é com quem se fala dentro daquele host.
enum SapPlataforma { ecc, s4hana }

extension SapBackendPlataforma on BackendService {
  /// `null` para backend que não é SAP.
  SapPlataforma? get sapPlataforma => switch (this) {
        BackendService.sapBandeirantes => SapPlataforma.ecc,
        BackendService.sapNel => SapPlataforma.s4hana,
        BackendService.sapVitamedic => SapPlataforma.s4hana,
        _ => null,
      };
}

/// Identificador do sistema SAP ecoado pelo backend em `GET /sap/session`.
/// Serve para o app conferir que a sessão recebida é do mesmo sistema que ele
/// resolveu localmente pela empresa.
extension SapBackendCode on BackendService {
  int? get sapCodigoEmpresa => switch (this) {
        BackendService.sapBandeirantes => 1,
        BackendService.sapNel => 6,
        BackendService.sapVitamedic => 15,
        _ => null,
      };

  String? get sapSystemCode => switch (this) {
        BackendService.sapBandeirantes => 'BANDEIRANTES',
        BackendService.sapNel => 'NEL',
        BackendService.sapVitamedic => 'VITAMEDIC',
        _ => null,
      };
}
