import 'dart:async';

import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/mock/contagem_cega_mock.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_checkin.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_header_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/repositories/contagem_cega_repository.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/sap_backend_resolver.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:result_dart/result_dart.dart';

/// Repositório de mentira para os testes de regra do controller.
///
/// Devolve [mockNotasFiscais] — as mesmas notas que os testes de widget usam —
/// para que as regras de contagem sejam exercitadas sem rede e sem SAP.
class FakeContagemCegaRepository implements ContagemCegaRepository {
  FakeContagemCegaRepository({
    this.status = CheckinStatus.entradaLiberada,
    this.falha,
    this.falhaIniciarEntrega,
    this.statusContagem = ContagemHeaderStatus.inexistente,
    List<ContagemNotaFiscal>? notas,
  }) : notas = notas ?? mockNotasFiscais();

  /// Status devolvido no cabeçalho — troque para exercitar o gate.
  CheckinStatus status;

  /// Quando preenchido, `carregarCheckin` falha com este erro.
  AppFailure? falha;

  /// Quando preenchido, `iniciarEntrega` falha com este erro.
  AppFailure? falhaIniciarEntrega;

  /// `Status` do `INCContagemACegaHeader` — `'C'`/`'D'` significam check-in já
  /// finalizado no SAP.
  ContagemHeaderStatus statusContagem;

  List<ContagemNotaFiscal> notas;

  /// Chaves recebidas, para conferir o zero-padding do NUMC(10).
  final List<String> checkinsRecebidos = [];

  int iniciarEntregaCalls = 0;
  final List<bool> jaIniciadoRecebido = [];

  // ── Gravação da contagem ───────────────────────────────────────────────────

  /// Histórico devolvido por `lerContagens`, chaveado pela `accesskey` da nota.
  Map<String, List<ContagemLogRegistro>> historico = const {};

  AppFailure? falhaCabecalho;
  AppFailure? falhaHistorico;
  AppFailure? falhaRegistro;
  AppFailure? falhaFinalizacao;

  /// Argumentos de cada `finalizarContagem` — é o que prova qual status ('C'
  /// ou 'D') o check-in fecharia no SAP.
  final List<Map<String, Object?>> finalizacoes = [];

  /// Ordem real das chamadas (`'cabecalho'`, `'historico'`, `'registro'`) — é o
  /// que prova que o cabeçalho é garantido ANTES de o histórico ser lido.
  final List<String> chamadas = [];

  /// Check-ins recebidos nas escritas, para conferir o NUMC(10) zero-padded.
  final List<String> checkinsGravados = [];

  /// Argumentos de cada `registrarContagem`, para conferir o que vai ao SAP.
  final List<Map<String, Object?>> contagensGravadas = [];

  /// Quando preenchido, `registrarContagem` só resolve depois que o teste
  /// completar — é como se exercita duplo toque sem `Timer`.
  Completer<void>? bloqueioRegistro;

  @override
  AsyncAppResult<bool> garantirCabecalhoContagem({
    required BackendService backend,
    required String checkin,
  }) async {
    chamadas.add('cabecalho');
    checkinsGravados.add(checkin);
    final erro = falhaCabecalho;
    if (erro != null) return Failure(erro);
    return const Success(true);
  }

  @override
  AsyncAppResult<bool> finalizarContagem({
    required BackendService backend,
    required String checkin,
    required bool comDevolucao,
  }) async {
    chamadas.add('finalizacao');
    finalizacoes.add({'checkin': checkin, 'comDevolucao': comDevolucao});
    final erro = falhaFinalizacao;
    if (erro != null) return Failure(erro);
    return const Success(true);
  }

  @override
  AsyncAppResult<List<ContagemLogRegistro>> lerContagens({
    required BackendService backend,
    required String chave,
    required String accesskey,
  }) async {
    chamadas.add('historico');
    final erro = falhaHistorico;
    if (erro != null) return Failure(erro);
    return Success(historico[accesskey] ?? const []);
  }

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
  }) async {
    chamadas.add('registro');
    contagensGravadas.add({
      'checkin': checkin,
      'chave': chave,
      'accesskey': accesskey,
      'item': item,
      'lote': lote,
      'loteLido': loteLido,
      'quantidade': quantidade,
      'matricula': matricula,
    });

    final bloqueio = bloqueioRegistro;
    if (bloqueio != null) await bloqueio.future;

    final erro = falhaRegistro;
    if (erro != null) return Failure(erro);
    return Success(contagensGravadas.length);
  }

  @override
  AsyncAppResult<ContagemCheckin> carregarCheckin({
    required BackendService backend,
    required String checkin,
  }) async {
    checkinsRecebidos.add(checkin);
    final erro = falha;
    if (erro != null) return Failure(erro);
    return Success(ContagemCheckin(
      checkin: checkin,
      status: status,
      motorista: 'João da Silva',
      cpf: '12345678901',
      placa: 'ABC1D23',
      notas: status.permiteContagem ? notas : const [],
      statusContagem: statusContagem,
    ));
  }

  @override
  AsyncAppResult<bool> iniciarEntrega({
    required BackendService backend,
    required String checkin,
    required bool jaIniciado,
  }) async {
    iniciarEntregaCalls++;
    jaIniciadoRecebido.add(jaIniciado);
    final erro = falhaIniciarEntrega;
    if (erro != null) return Failure(erro);
    return const Success(true);
  }
}

/// Resolver de mentira: evita arrastar `AccessController` -> `AccessRepository`
/// -> `CoreDio` -> `AppConfig.init()` para dentro de um teste unitário.
class FakeSapBackendResolver implements SapBackendResolver {
  FakeSapBackendResolver([
    this.backend = BackendService.sapVitamedic,
    this.matricula = '28109',
  ]);

  BackendService? backend;

  /// `null` exercita o usuário sem vínculo de funcionário, que não pode gravar
  /// contagem (registro de auditoria sem autor).
  @override
  String? matricula;

  @override
  BackendService? resolve() => backend;

  @override
  String get descricaoEmpresa => 'Empresa de Teste';
}
