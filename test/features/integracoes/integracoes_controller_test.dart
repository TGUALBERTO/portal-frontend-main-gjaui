import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/integracoes/data/models/models.dart';
import 'package:gjamobile/src/features/integracoes/data/repositories/integracoes_repository.dart';
import 'package:gjamobile/src/features/integracoes/presentation/controllers/integracoes_controller.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Fake do repositório de integrações; o que não é usado cai no noSuchMethod.
class _FakeRepository implements IntegracoesRepository {
  AppResult<List<ProcessoIntegracao>> listarResult = const Success([]);
  AppResult<ExecucaoIntegracao> executarResult = const Success(
    ExecucaoIntegracao(
      id: 'e1',
      processo: 'funcionario-fpw-completo',
      status: StatusExecucao.executando,
    ),
  );

  int listagens = 0;
  final List<String> disparados = [];

  @override
  AsyncAppResult<List<ProcessoIntegracao>> listar() async {
    listagens++;
    return listarResult;
  }

  @override
  AsyncAppResult<ExecucaoIntegracao> executarAgora(String nome) async {
    disparados.add(nome);
    return executarResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

ProcessoIntegracao processo(
  String nome, {
  bool ativo = true,
  bool podeExecutar = true,
  bool bloqueado = false,
  bool emExecucao = false,
  String? bloqueadoPor,
  String descricao = 'descrição',
  String grupo = 'grupo',
  StatusExecucao ultimoStatus = StatusExecucao.concluido,
  DateTime? iniciadoEm,
  DateTime? proximaExecucao,
}) {
  return ProcessoIntegracao(
    nome: nome,
    descricao: descricao,
    tipo: TipoProcesso.delta,
    grupoRecurso: grupo,
    requisitos: 'Oracle + Helpdesk',
    ativo: ativo,
    disparoManual: true,
    bloqueado: bloqueado,
    emExecucao: emExecucao,
    podeExecutar: podeExecutar,
    bloqueadoPor: bloqueadoPor,
    proximaExecucao: proximaExecucao,
    ultimaExecucao: ExecucaoIntegracao(
      id: 'x-$nome',
      processo: nome,
      status: ultimoStatus,
      iniciadoEm: iniciadoEm,
    ),
  );
}

void main() {
  // O controller avisa o usuario por toast, e o toast global resolve o contexto
  // pela GlobalKey do navigator — que exige o binding inicializado. Sem esta
  // linha o teste quebra no aviso, nao na regra que ele verifica.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repository;
  late IntegracoesController controller;

  setUp(() {
    repository = _FakeRepository();
    controller = IntegracoesController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test('load popula a lista de processos', () async {
    repository.listarResult = Success([processo('acesso'), processo('chamado')]);

    await controller.load();

    expect(controller.processos.value, hasLength(2));
    expect(controller.error.value, isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test('load com falha guarda o erro e mantém a lista intacta', () async {
    repository.listarResult = const Failure(ServerFailure('sem permissao'));

    await controller.load();

    expect(controller.error.value?.message, 'sem permissao');
    expect(controller.processos.value, isEmpty);
  });

  test('a busca filtra por nome, descrição e recurso', () async {
    repository.listarResult = Success([
      processo('acesso', descricao: 'Catracas'),
      processo('chamado', descricao: 'Chamados do GLPI', grupo: 'glpi'),
    ]);
    await controller.load();

    controller.setBusca('catraca');
    expect(controller.visiveis.value.single.nome, 'acesso');

    controller.setBusca('glpi');
    expect(controller.visiveis.value.single.nome, 'chamado');
  });

  test('o filtro de ativos esconde os processos desligados no ambiente',
      () async {
    repository.listarResult = Success([
      processo('acesso'),
      processo('edi', ativo: false, podeExecutar: false),
    ]);
    await controller.load();

    expect(controller.visiveis.value, hasLength(2));

    controller.alternarApenasAtivos();

    expect(controller.visiveis.value.single.nome, 'acesso');
    expect(controller.temFiltroAtivo, isTrue);
  });

  test('limparFiltros devolve a lista completa', () async {
    repository.listarResult = Success([processo('acesso'), processo('edi')]);
    await controller.load();
    controller.setBusca('acesso');
    controller.alternarApenasAtivos();

    controller.limparFiltros();

    expect(controller.visiveis.value, hasLength(2));
    expect(controller.temFiltroAtivo, isFalse);
  });

  test('processo sem execução vai para o fim quando ordena por última execução',
      () async {
    // Quem nunca rodou não deve encabeçar a lista ordenada por data.
    repository.listarResult = Success([
      const ProcessoIntegracao(
        nome: 'nunca-rodou',
        descricao: 'x',
        tipo: TipoProcesso.delta,
        grupoRecurso: 'g1',
        requisitos: 'r',
        ativo: true,
        disparoManual: true,
        bloqueado: false,
        emExecucao: false,
        podeExecutar: true,
      ),
      processo('rodou', iniciadoEm: DateTime(2026, 3, 1)),
    ]);
    await controller.load();

    controller.ordenarPor(ProcessoSortColumn.ultimaExecucao, true);

    expect(controller.visiveis.value.last.nome, 'nunca-rodou');
  });

  test('executarAgora dispara o processo e recarrega a lista', () async {
    repository.listarResult = Success([processo('funcionario-fpw-completo')]);
    await controller.load();
    final listagensAntes = repository.listagens;

    await controller.executarAgora('funcionario-fpw-completo');

    expect(repository.disparados, ['funcionario-fpw-completo']);
    expect(repository.listagens, greaterThan(listagensAntes));
    expect(controller.executandoNome.value, isNull);
  });

  test('conflito ao disparar recarrega a lista para corrigir a tela', () async {
    // 409 significa que o servidor mudou de estado: outro processo assumiu o
    // recurso, ou a integração caiu. Reler evita deixar o botão mentindo.
    repository.listarResult = Success([processo('funcionario-fpw')]);
    await controller.load();
    repository.executarResult = const Failure(
      ApiFailure('Processo bloqueado', status: 409),
    );
    final listagensAntes = repository.listagens;

    await controller.executarAgora('funcionario-fpw');

    expect(repository.listagens, greaterThan(listagensAntes));
    expect(controller.executandoNome.value, isNull);
  });

  test('processo em execução marca atividade e liga o acompanhamento',
      () async {
    repository.listarResult = Success([
      processo('funcionario-fpw-completo',
          emExecucao: true, podeExecutar: false),
    ]);

    await controller.load();

    final p = controller.processos.value.single;
    expect(p.temAtividade, isTrue);
    expect(p.statusExibido, StatusExecucao.executando);
  });

  test('lista estável não marca atividade', () async {
    repository.listarResult = Success([processo('acesso')]);

    await controller.load();

    expect(controller.processos.value.single.temAtividade, isFalse);
  });

  test('processo bloqueado por outro do mesmo recurso não pode executar',
      () async {
    repository.listarResult = Success([
      processo('funcionario-fpw',
          bloqueado: true,
          podeExecutar: false,
          bloqueadoPor: 'funcionario-fpw-completo'),
    ]);

    await controller.load();

    final p = controller.processos.value.single;
    expect(p.podeExecutar, isFalse);
    expect(p.bloqueadoPor, 'funcionario-fpw-completo');
    expect(p.temAtividade, isTrue);
  });
}
