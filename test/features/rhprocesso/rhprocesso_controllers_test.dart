import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/rhprocesso/data/repositories/cadastros_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/estrutura_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/volume_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/parametro.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/enums/visao_equipe.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/caracteristicas_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/estrutura_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/parametros_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/volume_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/salvar_arquivo.dart';

import 'fake_api.dart';
import 'rhprocesso_repositories_test.dart' show consultaJson;

void main() {
  // Os controllers chamam showGlobalToast, que consulta o navigator global.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VolumeController', () {
    late FakeApi api;
    late List<ArquivoGerado> salvos;
    late List<String> sugeridos;
    late bool cancelar;
    late _DestinoFake destino;
    late VolumeController controller;

    setUp(() async {
      api = FakeApi()
        ..quando('GET /api/v1/periodos', RespostaFake.json([
          {'periodo': '202609', 'ano': 2026, 'mes': 9},
          {'periodo': '202608', 'ano': 2026, 'mes': 8},
        ]));
      salvos = [];
      sugeridos = [];
      cancelar = false;
      destino = _DestinoFake(salvos);
      controller = VolumeController(
        repository: VolumeRepository(api.dio, exigeRede: false),
        escolher: (nome) async {
          sugeridos.add(nome);
          return cancelar ? null : destino;
        },
      );
      await controller.carregarPeriodos();
    });

    tearDown(() => controller.dispose());

    test('seleciona o período mais recente', () {
      expect(controller.periodo.value?.valor, '202609');
    });

    test('matrícula inválida não chama a API', () async {
      final antes = api.requisicoes.length;

      await controller.processar("1' OR '1'='1");

      expect(api.requisicoes.length, antes);
      expect(controller.erro.value?.message, contains('números'));
    });

    test('processar mostra a consulta e libera o DANFE', () async {
      api.quando('GET /api/v1/consultores/12345/volume', RespostaFake.json(consultaJson()));

      await controller.processar(' 12345 ');

      expect(controller.consulta.value?.equipe.nome, 'JOAO DA SILVA');
      expect(controller.podeGerar, isTrue);
    });

    test('o DANFE é da consulta processada e é salvo com o nome da API', () async {
      api
        ..quando('GET /api/v1/consultores/12345/volume', RespostaFake.json(consultaJson()))
        ..quando('GET /api/v1/consultores/12345/danfe.pdf', RespostaFake.bytes(
          [1, 2, 3],
          headers: {'content-disposition': 'attachment; filename="202609_JOAO_12345.pdf"'},
        ));
      await controller.processar('12345');

      await controller.gerarDanfe();

      expect(api.ultima.uri.path, '/api/v1/consultores/12345/danfe.pdf');
      expect(api.ultima.queryParameters, {'periodo': '202609'});
      expect(salvos.single.nome, '202609_JOAO_12345.pdf');
      // O destino é escolhido antes, com o nome no padrão da API.
      expect(sugeridos.single, '202609_JOAO DA SILVA_12345.pdf');
      expect(controller.gerandoDanfe.value, isFalse);
    });

    test('cancelar o diálogo de salvar não gera o arquivo', () async {
      api.quando('GET /api/v1/consultores/12345/volume', RespostaFake.json(consultaJson()));
      await controller.processar('12345');
      final antes = api.requisicoes.length;
      cancelar = true;

      await controller.exportarPlanilha();

      expect(sugeridos.single, '202609_JOAO DA SILVA_12345.xlsx');
      expect(api.requisicoes.length, antes);
      expect(salvos, isEmpty);
      expect(controller.exportando.value, isFalse);
    });

    test('falha na geração descarta o arquivo vazio já criado', () async {
      api
        ..quando('GET /api/v1/consultores/12345/volume', RespostaFake.json(consultaJson()))
        ..quando('GET /api/v1/consultores/12345/danfe.pdf', RespostaFake.json({'message': 'erro'}, status: 500));
      await controller.processar('12345');

      await controller.gerarDanfe();

      expect(salvos, isEmpty);
      expect(destino.descartado, isTrue);
      expect(controller.gerandoDanfe.value, isFalse);
    });

    test('trocar a visão descarta a consulta (outra pessoa)', () async {
      api.quando('GET /api/v1/consultores/12345/volume', RespostaFake.json(consultaJson()));
      await controller.processar('12345');

      controller.selecionarVisao(VisaoEquipe.supervisor);

      expect(controller.consulta.value, isNull);
      expect(controller.podeGerar, isFalse);
    });

    test('sem consulta processada, gerar não faz nada', () async {
      final antes = api.requisicoes.length;

      await controller.gerarDanfe();

      expect(api.requisicoes.length, antes);
      expect(salvos, isEmpty);
    });
  });

  group('EstruturaController', () {
    test('importar recarrega a lista do período', () async {
      final api = FakeApi()
        ..quando('GET /api/v1/estrutura-comercial/periodos-workflow', RespostaFake.json(['202610', '202609']))
        ..quando('GET /api/v1/estrutura-comercial', RespostaFake.json([]))
        ..quando('POST /api/v1/estrutura-comercial/importacoes', RespostaFake.json({
          'periodo': '202610',
          'rotasNoWorkflow': 2,
          'rotasExistentes': 0,
          'rotasIncluidas': 2,
        }));
      final controller = EstruturaController(
        repository: EstruturaRepository(api.dio, exigeRede: false),
      );
      addTearDown(controller.dispose);
      await controller.iniciar();
      expect(controller.periodo.value?.valor, '202610');

      api.quando('GET /api/v1/estrutura-comercial', RespostaFake.json([
        {'periodo': 202610, 'unidade': '1', 'rota': '101', 'matriculaConsultor': '1', 'nomeConsultor': 'A'},
        {'periodo': 202610, 'unidade': '1', 'rota': '102', 'matriculaConsultor': '2', 'nomeConsultor': 'B'},
      ]));
      final r = await controller.importar();

      expect(r?.rotasIncluidas, 2);
      expect(controller.rotas.value, hasLength(2));
      expect(api.ultima.method, 'GET');
    });

    test('busca filtra por rota e nome', () async {
      final api = FakeApi()
        ..quando('GET /api/v1/estrutura-comercial/periodos-workflow', RespostaFake.json(['202610']))
        ..quando('GET /api/v1/estrutura-comercial', RespostaFake.json([
          {'periodo': 202610, 'unidade': '1', 'rota': '101', 'matriculaConsultor': '1', 'nomeConsultor': 'ANA'},
          {'periodo': 202610, 'unidade': '1', 'rota': '202', 'matriculaConsultor': '2', 'nomeConsultor': 'BRUNO'},
        ]));
      final controller = EstruturaController(
        repository: EstruturaRepository(api.dio, exigeRede: false),
      );
      addTearDown(controller.dispose);
      await controller.iniciar();

      controller.setBusca('bruno');

      expect(controller.visiveis.value.single.rota, '202');
    });
  });

  group('CaracteristicasController', () {
    test('associar tira o produto da lista dos sem característica', () async {
      final api = FakeApi()
        ..quando('GET /api/v1/produtos', RespostaFake.json([
          {'codigo': '101', 'descricao': 'AGUA', 'fator': 1},
          {'codigo': '102', 'descricao': 'SUCO', 'fator': 1},
        ]))
        ..quando('PUT /api/v1/produtos/101/caracteristica', RespostaFake.json(
          {'codigo': '101', 'descricao': 'AGUA', 'fator': 1, 'grupo': 'AGUA', 'subgrupo': 'SEM GAS'},
        ));
      final controller = CaracteristicasController(
        repository: CadastrosRepository(api.dio, exigeRede: false),
      );
      addTearDown(controller.dispose);
      await controller.carregar();

      final ok = await controller.associar(
        controller.produtos.value.first,
        grupo: 'AGUA',
        subgrupo: 'SEM GAS',
        fator: 1,
      );

      expect(ok, isTrue);
      expect(controller.produtos.value.map((p) => p.codigo), ['102']);
    });
  });

  group('ParametrosController', () {
    late FakeApi api;
    late ParametrosController controller;

    setUp(() async {
      api = FakeApi()
        ..quando('GET /api/v1/parametros', RespostaFake.json([
          {'id': 1, 'descricao': 'LIMITE PRESTACAO', 'valor': 202401},
          {'id': 2, 'descricao': 'ANOS', 'valor': 2},
        ]));
      controller = ParametrosController(
        repository: CadastrosRepository(api.dio, exigeRede: false),
      );
      await controller.carregar();
    });

    tearDown(() => controller.dispose());

    test('período inválido não chega à API', () async {
      final antes = api.requisicoes.length;

      final ok = await controller.alterar(
        controller.parametros.value.first,
        descricao: 'LIMITE PRESTACAO',
        valor: '202513',
      );

      expect(ok, isFalse);
      expect(api.requisicoes.length, antes);
    });

    test('alteração válida atualiza a lista', () async {
      api.quando('PUT /api/v1/parametros/1', RespostaFake.json(
        {'id': 1, 'descricao': 'LIMITE PRESTACAO', 'valor': 202501},
      ));

      final ok = await controller.alterar(
        controller.parametros.value.first,
        descricao: 'LIMITE PRESTACAO',
        valor: '202501',
      );

      expect(ok, isTrue);
      expect(controller.parametros.value.first.valor, 202501);
    });
  });

  test('nome sugerido: sem acento e caractere inválido, como o da API', () {
    expect(nomeArquivoVolume('202608', 'NATALLY MAGALHÃES  FERREIRA', '26768', 'pdf'),
        '202608_NATALLY MAGALHAES FERREIRA_26768.pdf');
    expect(nomeArquivoVolume('202608', "JOSÉ D'ÁVILA/X", '1', 'xlsx'), '202608_JOSE DAVILAX_1.xlsx');
  });

  group('Parametro.validar', () {
    const periodo = Parametro(id: 1, descricao: '', valor: 0);
    const anos = Parametro(id: 2, descricao: '', valor: 0);

    test('IDs 1 e 3 exigem yyyymm com mês válido', () {
      expect(periodo.validar('202501'), isNull);
      expect(periodo.validar('202513'), isNotNull);
      expect(periodo.validar('2025-01'), isNotNull);
    });

    test('ID 4 é em dias; os demais numéricos, em anos', () {
      expect(const Parametro(id: 4, descricao: '', valor: 15).unidade, 'dia(s)');
      expect(anos.unidade, 'ano(s)');
    });

    test('ID 2 aceita inteiro não negativo', () {
      expect(anos.validar('0'), isNull);
      expect(anos.validar('3'), isNull);
      expect(anos.validar('-1'), isNotNull);
    });
  });
}

class _DestinoFake implements DestinoArquivo {
  _DestinoFake(this.salvos);

  final List<ArquivoGerado> salvos;
  bool descartado = false;

  @override
  Future<bool> gravar(ArquivoGerado arquivo) async {
    salvos.add(arquivo);
    return true;
  }

  @override
  Future<void> descartar() async => descartado = true;
}
