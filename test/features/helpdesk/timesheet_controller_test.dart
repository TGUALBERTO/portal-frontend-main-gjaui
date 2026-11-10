import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/user_access.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/auth/domain/entities/user.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/data/repositories/timesheet_repository.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/catraca_acesso.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/ponto_dia.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/timesheet_controller.dart';
import 'package:gjamobile/src/features/kba/domain/entities/employee_link.dart';
import 'package:gjamobile/src/shared/enums/app_status.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:result_dart/result_dart.dart';
import 'package:signals_flutter/signals_flutter.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeTimesheetRepository implements TimesheetRepository {
  AppResult<int> Function(String email)? onUsuarioId;
  AppResult<List<CatracaAcesso>> Function()? onAcessos;
  AppResult<List<PontoDia>> Function()? onPontos;
  AppResult<List<Apontamento>> Function()? onApontamentos;
  AppResult<Map<int, Chamado>> Function(Set<int> ids)? onChamadosPorOrigem;

  int usuarioIdCalls = 0;
  final List<int> apontamentoUsuarioIds = [];
  final List<Set<int>> chamadosOrigemIds = [];

  @override
  AsyncAppResult<int> fetchUsuarioId({required String email}) async {
    usuarioIdCalls++;
    return onUsuarioId!(email);
  }

  @override
  AsyncAppResult<List<CatracaAcesso>> fetchAcessos({
    required String matricula,
    required DateTime dataIni,
    required DateTime dataFim,
  }) async =>
      (onAcessos ?? () => const Success(<CatracaAcesso>[]))();

  @override
  AsyncAppResult<List<PontoDia>> fetchPontos({
    required String matricula,
    required DateTime dataIni,
    required DateTime dataFim,
  }) async =>
      (onPontos ?? () => const Success(<PontoDia>[]))();

  @override
  AsyncAppResult<List<Apontamento>> fetchApontamentos({
    required int usuarioId,
    required DateTime dataIni,
    required DateTime dataFim,
  }) async {
    apontamentoUsuarioIds.add(usuarioId);
    return (onApontamentos ?? () => const Success(<Apontamento>[]))();
  }

  @override
  AsyncAppResult<Map<int, Chamado>> fetchChamadosPorOrigem({
    required Set<int> origemIds,
  }) async {
    chamadosOrigemIds.add(origemIds);
    return (onChamadosPorOrigem ??
        (_) => const Success(<int, Chamado>{}))(origemIds);
  }

  // Escrita de apontamento — fora do escopo destes testes.

  @override
  AsyncAppResult<List<Chamado>> searchChamados({required String termo}) async =>
      const Success(<Chamado>[]);

  @override
  AsyncAppResult<Unit> criarApontamento({
    required String chamadoId,
    required DateTime inicio,
    required DateTime fim,
    required String descricao,
    required bool privado,
  }) async =>
      const Success(unit);

  @override
  AsyncAppResult<Unit> atualizarApontamento({
    required int id,
    DateTime? inicio,
    DateTime? fim,
    String? descricao,
    bool? privado,
  }) async =>
      const Success(unit);

  @override
  AsyncAppResult<Unit> excluirApontamento({required int id}) async =>
      const Success(unit);
}

class _FakeAccessRepository implements AccessRepository {
  @override
  AsyncAppResult<dynamic> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError();
}

/// AccessController com `employeeLink`/`accessSignal` controláveis e `load()`
/// neutralizado. `matricula` vem de `employeeLink.matricula`; `_email` de
/// `accessSignal.value.user.email`.
class _FakeAccessController extends AccessController {
  _FakeAccessController() : super(repository: _FakeAccessRepository());

  final Signal<UserAccess?> _accessOverride = signal(null);
  EmployeeLink? _linkOverride;

  void setUser({String? email, int? matricula}) {
    _accessOverride.value = email == null
        ? null
        : UserAccess(
            user: AppUser(id: 'id-$email', email: email),
            groups: const [],
          );
    _linkOverride = matricula == null
        ? null
        : EmployeeLink(
            status: EmployeeLinkStatus.linked,
            bloqueado: false,
            kbaAvailable: false,
            attemptsRemaining: 0,
            matricula: matricula,
          );
  }

  @override
  Signal<UserAccess?> get accessSignal => _accessOverride;

  @override
  EmployeeLink? get employeeLink => _linkOverride;

  @override
  Future<void> load() async {}

  @override
  void dispose() {
    _accessOverride.dispose();
    super.dispose();
  }
}

// ── Builders ─────────────────────────────────────────────────────────────────

Apontamento _apontamento({
  int? id = 1,
  int? chamado = 500,
  DateTime? data,
  int actiontime = 3600,
}) =>
    Apontamento(
      id: id,
      chamadoId: chamado,
      data: data,
      usuarioId: 100,
      content: 'tarefa',
      actiontime: actiontime,
      beginDate: null,
      endDate: null,
    );

CatracaAcesso _acesso() => CatracaAcesso(
      origemId: 1,
      data: DateTime(2026, 7, 6, 8),
      tipoAcesso: TipoAcesso.entrada,
      matricula: '111',
      nome: 'Fulano',
      cargo: '',
      lotacao: '',
      catraca: '',
      idCatraca: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTimesheetRepository repo;
  late _FakeAccessController access;
  late TimesheetController controller;

  setUp(() {
    repo = _FakeTimesheetRepository();
    access = _FakeAccessController();
    controller = TimesheetController(repository: repo, accessController: access);
  });

  tearDown(() {
    controller.dispose();
    access.dispose();
  });

  test('resolve usuarioId do email e busca apontamentos com esse id', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onApontamentos = () => Success([_apontamento()]);

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.success);
    expect(controller.usuarioId, 100);
    expect(repo.apontamentoUsuarioIds, [100]);
    expect(controller.apontamentosSignal.value, hasLength(1));
  });

  test('F1: sem matricula mas com usuarioId, apontamentos ainda carregam',
      () async {
    access.setUser(email: 'a@x.com', matricula: null);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onApontamentos = () => Success([_apontamento()]);

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.success);
    expect(controller.acessosSignal.value, isEmpty); // matricula null -> sem catraca
    expect(controller.apontamentosSignal.value, hasLength(1));
    expect(repo.apontamentoUsuarioIds, [100]);
  });

  test('F2: 404 no findByEmail = sem conta (sem erro), cacheado como resolvido',
      () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId =
        (_) => const Failure(ApiFailure('nao encontrado', status: 404));
    repo.onAcessos = () => const Success(<CatracaAcesso>[]);

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.success);
    expect(controller.errorSignal.value, isNull);
    expect(controller.partialErrorSignal.value, isNull);
    expect(controller.usuarioId, isNull);
    expect(controller.apontamentosSignal.value, isEmpty);

    // Segundo load não reconsulta (resolvido definitivo para este email).
    await controller.load();
    expect(repo.usuarioIdCalls, 1);
  });

  test('F2: falha transitoria no findByEmail vira aviso e reconsulta', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Failure(ServerFailure('boom'));
    repo.onAcessos = () => Success([_acesso()]); // catraca tem dado

    await controller.load();

    // Catraca carregou -> tela de sucesso, mas com aviso parcial.
    expect(controller.statusSignal.value, AppStatus.success);
    expect(controller.partialErrorSignal.value, isA<ServerFailure>());
    expect(controller.usuarioId, isNull);
    expect(controller.apontamentosSignal.value, isEmpty);

    // Não cacheado -> reconsulta no próximo load.
    await controller.load();
    expect(repo.usuarioIdCalls, 2);
  });

  test('F3: apontamentos falham mas acessos carregam -> sucesso + aviso',
      () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onAcessos = () => Success([_acesso()]);
    repo.onApontamentos = () => const Failure(ServerFailure('apontamento off'));

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.success);
    expect(controller.acessosSignal.value, hasLength(1)); // preservado
    expect(controller.apontamentosSignal.value, isEmpty);
    expect(controller.partialErrorSignal.value, isA<ServerFailure>());
    expect(controller.errorSignal.value, isNull);
  });

  test('F3: ambas as fontes falham sem dados -> status failure', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onAcessos = () => const Failure(ServerFailure('a'));
    repo.onApontamentos = () => const Failure(ServerFailure('b'));

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.failure);
    expect(controller.errorSignal.value, isA<ServerFailure>());
  });

  test('F4: troca de usuario reconsulta o id e nao reusa o do anterior',
      () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (email) => Success(email == 'a@x.com' ? 100 : 200);
    repo.onApontamentos = () => const Success(<Apontamento>[]);

    await controller.load();
    expect(controller.usuarioId, 100);
    expect(repo.apontamentoUsuarioIds, [100]);

    // Logout -> login de outro usuario na mesma instancia.
    access.setUser(email: 'b@x.com', matricula: 111);
    await controller.load();

    expect(repo.usuarioIdCalls, 2);
    expect(controller.usuarioId, 200);
    expect(repo.apontamentoUsuarioIds, [100, 200]); // usou 200, nao 100
  });

  test('F4: falha transitoria ao trocar de usuario nao vaza o id anterior',
      () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onApontamentos = () => Success([_apontamento()]);

    await controller.load();
    expect(controller.usuarioId, 100);

    // Troca de usuario; findByEmail do novo falha transitoriamente.
    access.setUser(email: 'b@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Failure(ServerFailure('timeout'));

    await controller.load();

    // Id do usuario A NAO permanece: apontamentos de A nao sao rebuscados.
    expect(controller.usuarioId, isNull);
    expect(repo.apontamentoUsuarioIds, [100]); // so a 1a busca (usuario A)
    expect(controller.apontamentosSignal.value, isEmpty);
  });

  test('carrega pontos e agrupa por dia (um por dia)', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onPontos = () => Success([
          PontoDia(
            matricula: '111',
            data: DateTime(2026, 7, 8),
            entrada: DateTime(2026, 7, 8, 7, 58),
            saida: DateTime(2026, 7, 8, 17, 30),
          ),
          PontoDia(
            matricula: '111',
            data: DateTime(2026, 7, 9),
            entrada: DateTime(2026, 7, 9, 8, 2),
            saida: null, // jornada aberta: uma única marcação
          ),
        ]);

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.success);
    final porDia = controller.pontosPorDiaSignal.value;
    expect(porDia, hasLength(2));
    expect(porDia[DateTime(2026, 7, 8)]?.saida, DateTime(2026, 7, 8, 17, 30));
    expect(porDia[DateTime(2026, 7, 9)]?.saida, isNull);
  });

  test('falha nos pontos com outra fonte carregada -> sucesso + aviso',
      () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onAcessos = () => Success([_acesso()]);
    repo.onPontos = () => const Failure(ServerFailure('ponto off'));

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.success);
    expect(controller.acessosSignal.value, hasLength(1));
    expect(controller.pontosSignal.value, isEmpty);
    expect(controller.partialErrorSignal.value, isA<ServerFailure>());
    expect(controller.errorSignal.value, isNull);
  });

  test('agrupa apontamentos por dia e soma o tempo apontado', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    final dia = DateTime(2026, 7, 8, 9);
    repo.onApontamentos = () => Success([
          _apontamento(id: 1, data: DateTime(2026, 7, 8, 9), actiontime: 3600),
          _apontamento(id: 2, data: DateTime(2026, 7, 8, 14), actiontime: 1800),
        ]);

    await controller.load();

    final key = DateTime(dia.year, dia.month, dia.day);
    expect(controller.apontamentosPorDiaSignal.value[key], hasLength(2));
    expect(controller.apontadoPorDiaSignal.value[key],
        const Duration(seconds: 5400));
  });

  Chamado chamado({required int origemId}) => Chamado(
        id: 'uuid-$origemId',
        origemId: origemId,
        titulo: 'Erro no faturamento',
      );

  test('busca titulos dos chamados dos apontamentos carregados', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onApontamentos = () => Success([
          _apontamento(id: 1, chamado: 500, data: DateTime(2026, 7, 8, 9)),
          _apontamento(id: 2, chamado: 600, data: DateTime(2026, 7, 9, 9)),
        ]);
    repo.onChamadosPorOrigem =
        (_) => Success({500: chamado(origemId: 500)});

    await controller.load();

    expect(repo.chamadosOrigemIds, [
      {500, 600}
    ]);
    // O signal de titulos e derivado do mapa de chamados.
    expect(controller.titulosChamadosSignal.value,
        const {500: 'Erro no faturamento'});
  });

  test('falha nos titulos nao bloqueia a tela (best-effort)', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onApontamentos = () => Success([_apontamento()]);
    repo.onChamadosPorOrigem = (_) => const Failure(ServerFailure('boom'));

    await controller.load();

    expect(controller.statusSignal.value, AppStatus.success);
    expect(controller.errorSignal.value, isNull);
    expect(controller.titulosChamadosSignal.value, isEmpty);
  });

  test('apontamento sem data e descartado do agrupamento', () async {
    access.setUser(email: 'a@x.com', matricula: 111);
    repo.onUsuarioId = (_) => const Success(100);
    repo.onApontamentos = () => Success([
          _apontamento(id: 1, data: null),
          _apontamento(id: 2, data: DateTime(2026, 7, 8, 9)),
        ]);

    await controller.load();

    expect(controller.apontamentosSignal.value, hasLength(2));
    // Só o com data entra no agrupamento por dia.
    final totalAgrupado = controller.apontamentosPorDiaSignal.value.values
        .fold<int>(0, (sum, list) => sum + list.length);
    expect(totalAgrupado, 1);
  });
}
