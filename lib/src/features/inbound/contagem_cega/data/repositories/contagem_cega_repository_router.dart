import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_checkin.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/repositories/contagem_cega_repository.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/sap_backend.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Escolhe a implementação da contagem cega pela **plataforma** do SAP do
/// backend de cada chamada ([SapPlataforma]).
///
/// O host já sai da empresa (`sapBackendForEmpresa`); o que muda entre ECC e
/// S/4HANA é o contrato OData — entity sets, nomes de propriedade e, no caso do
/// ECC, até quantas idas a carga custa. A troca mora aqui para o controller e
/// as telas não saberem que existem dois formatos.
///
/// **O despacho é por chamada, não por sessão.** O perfil funcional troca de
/// empresa com a tela aberta, e o `SelecaoEmpresaSap` devolve um
/// [BackendService] diferente na ação seguinte. Guardar a implementação
/// escolhida mandaria a próxima leitura para o serviço da empresa anterior.
///
/// Cada implementação é singleton própria no DI, então a marca d'água do
/// incremental (`ContagemSequencia`) de uma nunca vaza para a outra.
class ContagemCegaRepositoryRouter implements ContagemCegaRepository {
  ContagemCegaRepositoryRouter({
    required ContagemCegaRepository s4hana,
    required ContagemCegaRepository ecc,
  })  : _s4hana = s4hana,
        _ecc = ecc;

  final ContagemCegaRepository _s4hana;
  final ContagemCegaRepository _ecc;

  /// Backend que não é SAP não chega aqui: o controller barra antes a empresa
  /// sem SAP mapeado. Se chegar, é bug — e escolher um formato padrão em
  /// silêncio falaria com o SAP errado.
  ContagemCegaRepository _para(BackendService backend) =>
      switch (backend.sapPlataforma) {
        SapPlataforma.ecc => _ecc,
        SapPlataforma.s4hana => _s4hana,
        null => throw StateError(
            'Contagem cega chamada com backend não-SAP: ${backend.name}',
          ),
      };

  @override
  AsyncAppResult<ContagemCheckin> carregarCheckin({
    required BackendService backend,
    required String checkin,
  }) =>
      _para(backend).carregarCheckin(backend: backend, checkin: checkin);

  @override
  AsyncAppResult<bool> iniciarEntrega({
    required BackendService backend,
    required String checkin,
    required bool jaIniciado,
  }) =>
      _para(backend).iniciarEntrega(
        backend: backend,
        checkin: checkin,
        jaIniciado: jaIniciado,
      );

  @override
  AsyncAppResult<bool> garantirCabecalhoContagem({
    required BackendService backend,
    required String checkin,
  }) =>
      _para(backend)
          .garantirCabecalhoContagem(backend: backend, checkin: checkin);

  @override
  AsyncAppResult<bool> finalizarContagem({
    required BackendService backend,
    required String checkin,
    required bool comDevolucao,
  }) =>
      _para(backend).finalizarContagem(
        backend: backend,
        checkin: checkin,
        comDevolucao: comDevolucao,
      );

  @override
  AsyncAppResult<List<ContagemLogRegistro>> lerContagens({
    required BackendService backend,
    required String chave,
    required String accesskey,
  }) =>
      _para(backend).lerContagens(
        backend: backend,
        chave: chave,
        accesskey: accesskey,
      );

  @override
  AsyncAppResult<int> registrarContagem({
    required BackendService backend,
    required String checkin,
    required String chave,
    required String accesskey,
    required String item,
    required String lote,
    required String loteLido,
    required double quantidade,
    required String matricula,
  }) =>
      _para(backend).registrarContagem(
        backend: backend,
        checkin: checkin,
        chave: chave,
        accesskey: accesskey,
        item: item,
        lote: lote,
        loteLido: loteLido,
        quantidade: quantidade,
        matricula: matricula,
      );
}
