import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/rhprocesso/data/repositories/cadastros_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/estrutura_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/volume_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/estrutura_rota.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/enums/visao_equipe.dart';
import 'package:gjamobile/src/utils/utils.dart';

import 'fake_api.dart';

const _setembro = Periodo('202609');

Map<String, dynamic> consultaJson() => {
      'equipe': {
        'matricula': '12345',
        'nome': 'JOAO DA SILVA',
        'rotas': [
          {'unidade': '1', 'rota': '101', 'matriculaConsultor': '12345', 'nomeConsultor': 'JOAO DA SILVA'},
          {'unidade': '2', 'rota': '101', 'matriculaConsultor': '12345', 'nomeConsultor': 'JOAO DA SILVA'},
        ],
      },
      'periodo': '202609',
      'criterioData': 'EMISSAO',
      'origem': 'CORRENTE',
      'detalhe': [
        {
          'unidade': '1',
          'numeroNota': '12345',
          'dataEmissao': '2026-09-15',
          'dataPrestacao': null,
          'rota': '101',
          'codigoProduto': '101',
          'descricaoProduto': 'REFRIGERANTE 2L',
          'quantidade': 12,
          'valorUnitario': 7.5,
          'valorImpostoUnitario': 0.2675,
          'valorImpostoTotal': 3.21,
          'valorUnitarioComImposto': 7.7675,
          'valorTotalComImposto': 93.21,
          'valorTotalSemImposto': 90,
          'status': 'N',
          'operacaoFiscal': '5102',
          'fatorConversao': 0.5,
          'quantidadeCxu': 6,
          'caracteristica': 'CSD',
        },
      ],
      'notas': [
        {
          'unidade': '1',
          'numero': '12345',
          'dataEmissao': '2026-09-15',
          'rota': '101',
          'operacaoFiscal': '5102',
          'valorNota': 93.21,
        },
      ],
      'resumo': [
        {'caracteristica': 'CSD', 'quantidadeCxu': 6, 'valor': 93.21},
      ],
      'totais': {
        'quantidadeNotas': 1,
        'quantidadeItens': 1,
        'quantidadeCxu': 6,
        'valorComImposto': 93.21,
        'valorSemImposto': 90,
        'valorNotas': 93.21,
        'valorUnitario': 7.5,
        'valorImpostoUnitario': 0.2675,
        'valorImpostoTotal': 3.21,
        'valorUnitarioComImposto': 7.7675,
      },
    };

void main() {
  group('VolumeRepository', () {
    late FakeApi api;
    late VolumeRepository repo;

    setUp(() {
      api = FakeApi();
      repo = VolumeRepository(api.dio, exigeRede: false);
    });

    test('períodos vêm como yyyymm com rótulo MM/yyyy', () async {
      api.quando('GET /api/v1/periodos', RespostaFake.json([
        {'periodo': '202609', 'ano': 2026, 'mes': 9},
        {'periodo': '202608', 'ano': 2026, 'mes': 8},
      ]));

      final r = (await repo.periodos()).getOrThrow();

      expect(r.map((p) => p.valor), ['202609', '202608']);
      expect(r.first.rotulo, '09/2026');
    });

    test('consulta do supervisor usa o recurso e o período da query', () async {
      api.quando('GET /api/v1/supervisores/54321/volume', RespostaFake.json(consultaJson()));

      final c = (await repo.consultar(VisaoEquipe.supervisor, '54321', _setembro)).getOrThrow();

      expect(api.ultima.queryParameters, {'periodo': '202609'});
      expect(c.equipe.nome, 'JOAO DA SILVA');
      expect(c.equipe.codigosRotas, ['101']);
      expect(c.detalhe.single.quantidadeCxu, 6);
      expect(c.detalhe.single.dataEmissao, DateTime(2026, 9, 15));
      expect(c.notas.single.valorNota, 93.21);
      expect(c.resumo.single.caracteristica, 'CSD');
      expect(c.totais.quantidadeNotas, 1);
      // Caixas do desktop.
      expect(c.totais.quantidadeItens, 1);
      expect(c.totais.valorImpostoUnitario, 0.2675);
      expect(c.totais.valorUnitarioComImposto, 7.7675);
      expect(c.detalhe.single.valorImpostoUnitario, 0.2675);
    });

    test('matrícula fora da estrutura: a mensagem da API chega ao usuário', () async {
      api.quando('GET /api/v1/consultores/99/volume', RespostaFake.json(
        {'code': 'NOT_FOUND', 'message': 'Consultor 99 não encontrado no período 202609.'},
        status: 404,
      ));

      final falha = (await repo.consultar(VisaoEquipe.consultor, '99', _setembro)).exceptionOrNull();

      expect(falha, isA<ApiFailure>());
      expect((falha! as ApiFailure).isNotFound, isTrue);
      expect(falha.message, contains('não encontrado'));
    });

    test('DANFE: nome do Content-Disposition, aviso do SAP e timeout longo', () async {
      api.quando('GET /api/v1/consultores/12345/danfe.pdf', RespostaFake.bytes(
        [0x25, 0x50, 0x44, 0x46],
        headers: {
          'content-disposition': 'attachment; filename="202609_JOAO DA SILVA_12345.pdf"',
          'x-rhprocesso-aviso': 'Identificacao NF-e indisponivel no SAP para a(s) filial(is) 1002.',
        },
      ));

      final a = (await repo.danfe(VisaoEquipe.consultor, '12345', _setembro)).getOrThrow();

      expect(a.nome, '202609_JOAO DA SILVA_12345.pdf');
      expect(a.bytes, [0x25, 0x50, 0x44, 0x46]);
      expect(a.aviso, contains('1002'));
      expect(api.ultima.receiveTimeout, VolumeRepository.tempoGeracao);
    });

    test('planilha sem Content-Disposition usa o nome padrão', () async {
      api.quando('GET /api/v1/consultores/12345/volume.xlsx',
          RespostaFake.bytes([1, 2, 3], contentType: 'application/octet-stream'));

      final a = (await repo.planilha(VisaoEquipe.consultor, '12345', _setembro)).getOrThrow();

      expect(a.nome, '202609_12345.xlsx');
      expect(a.aviso, isNull);
    });

    test('erro no download: o corpo JSON em bytes vira a mensagem da falha', () async {
      api.quando('GET /api/v1/consultores/12345/danfe.pdf', RespostaFake.json(
        {'code': 'NOT_FOUND', 'message': 'Nenhuma nota no período 202609.'},
        status: 404,
      ));

      final falha = (await repo.danfe(VisaoEquipe.consultor, '12345', _setembro)).exceptionOrNull();

      expect(falha!.message, 'Nenhuma nota no período 202609.');
    });
  });

  group('EstruturaRepository', () {
    late FakeApi api;
    late EstruturaRepository repo;

    setUp(() {
      api = FakeApi();
      repo = EstruturaRepository(api.dio, exigeRede: false);
    });

    test('importação envia o período e lê o resultado', () async {
      api.quando('POST /api/v1/estrutura-comercial/importacoes', RespostaFake.json({
        'periodo': '202610',
        'rotasNoWorkflow': 10,
        'rotasExistentes': 7,
        'rotasIncluidas': 3,
      }));

      final r = (await repo.importar(const Periodo('202610'))).getOrThrow();

      expect(api.ultima.data, {'periodo': '202610'});
      expect(r.rotasIncluidas, 3);
    });

    test('alteração vai para /{periodo}/{unidade}/{rota} com a hierarquia no corpo', () async {
      api.quando('PUT /api/v1/estrutura-comercial/202610/1/101', RespostaFake.json({
        'periodo': 202610,
        'unidade': '1',
        'rota': '101',
        'matriculaConsultor': '777',
        'nomeConsultor': 'MARIA',
      }));
      const rota = EstruturaRota(
        periodo: '202610',
        unidade: '1',
        rota: '101',
        matriculaConsultor: '12345',
        nomeConsultor: 'JOAO',
        matriculaSupervisor: 'S01',
      );

      final salva = (await repo.alterar(rota.copyWith(
        matriculaConsultor: '777',
        nomeConsultor: 'MARIA',
        matriculaSupervisor: '',
      ))).getOrThrow();

      final corpo = api.ultima.data as Map<String, dynamic>;
      expect(corpo['matriculaConsultor'], '777');
      // Campo esvaziado vira null: rota sem supervisor.
      expect(corpo['matriculaSupervisor'], isNull);
      expect(salva.periodo, '202610');
      expect(salva.nomeConsultor, 'MARIA');
    });
  });

  group('CadastrosRepository', () {
    late FakeApi api;
    late CadastrosRepository repo;

    setUp(() {
      api = FakeApi();
      repo = CadastrosRepository(api.dio, exigeRede: false);
    });

    test('produtos sem característica: query caracterizado=false', () async {
      api.quando('GET /api/v1/produtos', RespostaFake.json([
        {'codigo': '101', 'codigoGravado': '000101', 'descricao': 'AGUA', 'fator': 1},
      ]));

      final lista = (await repo.produtos(caracterizados: false)).getOrThrow();

      expect(api.ultima.queryParameters, {'caracterizado': false});
      expect(lista.single.caracterizado, isFalse);
    });

    test('associação envia grupo, subgrupo e fator', () async {
      api.quando('PUT /api/v1/produtos/101/caracteristica', RespostaFake.json({
        'codigo': '101',
        'descricao': 'AGUA',
        'fator': 0.5,
        'grupo': 'AGUA',
        'subgrupo': 'SEM GAS',
      }));

      final p = (await repo.associar('101', grupo: 'AGUA', subgrupo: 'SEM GAS', fator: 0.5)).getOrThrow();

      expect(api.ultima.data, {'grupo': 'AGUA', 'subgrupo': 'SEM GAS', 'fator': 0.5});
      expect(p.caracterizado, isTrue);
    });

    test('remoção usa DELETE', () async {
      api.quando('DELETE /api/v1/produtos/101/caracteristica', RespostaFake.bytes(const [], status: 204));

      expect((await repo.remover('101')).isSuccess(), isTrue);
    });

    test('alteração de parâmetro', () async {
      api.quando('PUT /api/v1/parametros/1', RespostaFake.json({'id': 1, 'descricao': 'LIMITE', 'valor': 202501}));

      final p = (await repo.alterarParametro(1, descricao: 'LIMITE', valor: 202501)).getOrThrow();

      expect(api.ultima.data, {'descricao': 'LIMITE', 'valor': 202501});
      expect(p.valor, 202501);
    });
  });
}
