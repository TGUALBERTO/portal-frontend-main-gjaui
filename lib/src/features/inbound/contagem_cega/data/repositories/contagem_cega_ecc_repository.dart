import 'package:dio/dio.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/contagem_sequencia.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/contagem_cega_ecc_campos.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_header_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_item_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_po_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_var_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_xml_item_consumo_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in_checkin_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/inc_contagem_a_cega_header_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/inc_contagem_a_cega_log_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/mappers/contagem_cega_mapper.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_checkin.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_header_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/repositories/contagem_cega_repository.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/services/rehidratar_nota.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_query.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_write.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_odata_client.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Contagem cega no **SAP ECC** (hoje, Refrescos Bandeirantes).
///
/// Faz o mesmo que `ContagemCegaRepositoryImpl` — abrir o check-in, montar a
/// lista de conferência, gravar o log de tentativas e finalizar — contra um
/// serviço diferente. Quem escolhe entre os dois é o
/// `ContagemCegaRepositoryRouter`, pela [SapPlataforma] do backend da chamada.
///
/// ## O que muda em relação ao S/4HANA
///
/// **Um serviço só.** Lá a contagem vive no `ZGJAAUTO_SB_GENERIC` (gerado por
/// CDS) e só a finalização sai pelo `ZGJAAUTO_GENERIC_SRV`. No ECC não existe
/// serviço CDS: tudo foi reconstruído com SEGW dentro do
/// `ZGJAAUTO_GENERIC_SRV`. Uma sessão só, em vez de duas.
///
/// **Nove leituras em vez de oito.** O `INCheckin` do S/4HANA trazia o
/// motorista e as NF-e numa ida só, por `$expand=to_Items`. O serviço ECC não
/// tem essa associação — o cabeçalho (`IN100_CHECKIN_MOTISTA`) e as notas
/// (`IN100CheckinItems`) são entidades independentes. Continua sendo um número
/// FIXO de chamadas: as notas vão todas num `$filter` só, não uma por nota.
///
/// **O servidor numera a tentativa.** No S/4HANA o app calcula `max + 1` sobre
/// o log e manda o `Contagem` no corpo, com uma marca d'água local para fechar
/// a janela entre gravar e reler. No ECC o `CREATE_ENTITY` faz
/// `SELECT MAX( contagem ) + 1` por `(Checkin, Chave, Accesskey, NLote, Item)`
/// dentro da própria requisição e devolve a entidade criada — então o app
/// **não manda** `Contagem` e lê o número da resposta. É mais seguro: o cálculo
/// e a gravação acontecem na mesma unidade de trabalho, e dois coletores na
/// mesma nota não disputam o número.
///
/// A [ContagemSequencia] continua aqui, mas só como memória do que o servidor
/// atribuiu — é ela que mantém a reidratação coerente quando o coletor reabre.
class ContagemCegaEccRepository implements ContagemCegaRepository {
  ContagemCegaEccRepository(this._sap);

  final SapODataClient _sap;

  /// Memória do último `Contagem` que o SAP atribuiu por linha.
  ///
  /// Instância própria, separada da do repositório S/4HANA: os dois são
  /// singletons distintos no DI, e um número de um sistema não pode influenciar
  /// o outro.
  final ContagemSequencia _sequencia = ContagemSequencia();

  static const String _service = ContagemCegaEccCampos.servico;

  /// Quantas notas por `$filter`, mesma conta do S/4HANA: um par
  /// (Chave 20 + Accesskey 44) custa ~95 caracteres codificados, e 20 pares
  /// ficam em ~1,9 KB.
  static const int _notasPorLote = 20;

  // ── Leitura da carga ───────────────────────────────────────────────────────

  @override
  AsyncAppResult<ContagemCheckin> carregarCheckin({
    required BackendService backend,
    required String checkin,
  }) {
    return runTask(() async {
      // (1) Cabeçalho do check-in. As propriedades vêm em CAIXA ALTA — este
      // entity type foi criado à mão no SEGW, sem import DDIC.
      final Map<String, dynamic> json;
      try {
        json = await _sap.getEntity(
          backend: backend,
          service: _service,
          path: '${ContagemCegaEccCampos.checkinSet}(${odataLiteral(checkin)})',
        );
      } on DioException catch (error) {
        if (error.response?.statusCode == 404) {
          throw ValidationFailure('Check-in $checkin não encontrado no SAP.');
        }
        rethrow;
      }

      final numero = odataString(json[ContagemCegaEccCampos.checkin]);
      final cabecalho = ContagemCheckin(
        checkin: numero.isEmpty ? checkin : numero,
        status: CheckinStatus.fromApi(
          odataString(json[ContagemCegaEccCampos.checkinStatus]),
        ),
        motorista: odataString(json[ContagemCegaEccCampos.checkinMotorista]),
        cpf: odataString(json[ContagemCegaEccCampos.checkinCpf]),
        placa: odataString(json[ContagemCegaEccCampos.checkinPlaca]),
      );

      // Status que não permite contagem para aqui, como no S/4HANA: as leituras
      // seguintes custam caro e seriam jogadas fora. A tela ainda recebe
      // motorista e placa para explicar o bloqueio a quem está na doca.
      if (!cabecalho.status.permiteContagem) return cabecalho;

      // (2) As NF-e do caminhão. É a leitura que o `$expand=to_Items` do
      // S/4HANA economizava.
      final itens = await _notasDoCheckin(backend, cabecalho.checkin);
      if (itens.isEmpty) return cabecalho;

      // O mapper consome um `InCheckinDto`; montá-lo aqui mantém o mapeamento
      // de notas idêntico nos dois sistemas, que é o que garante que a tela
      // mostre a mesma coisa em qualquer empresa.
      final dto = InCheckinDto(
        checkin: cabecalho.checkin,
        status: cabecalho.status.codigo,
        motorista: cabecalho.motorista,
        cpf: cabecalho.cpf,
        placa: cabecalho.placa,
        itens: itens,
      );

      // NF-e sem chave de acesso NÃO entra nos filtros, mas CONTINUA em
      // `dto.itens`.
      //
      // Já aconteceu em QAS: a ZIN1008 com ACCESSKEY em branco produziu
      // `$filter=(Chave eq '...' and Accesskey eq '')`, que o SAP respondeu com
      // 500 e derrubou a abertura do check-in inteiro. Mandar o par vazio é
      // pedir lixo e, no melhor caso, receber as linhas erradas.
      //
      // Some do filtro, não da tela: numa contagem cega, nota que desaparece
      // em silêncio passa batido e o caminhão é recebido sem ser conferido. Ela
      // aparece sem itens, que é visivelmente quebrado — e é esse o ponto.
      final pares = itens
          .where((i) => i.chave.isNotEmpty && i.accesskey.isNotEmpty)
          .map((i) => (i.chave, i.accesskey))
          .toSet()
          .toList(growable: false);

      if (pares.length != itens.length) {
        AppLogger.warning(
          'Contagem cega (ECC): check-in ${cabecalho.checkin} tem '
          '${itens.length - pares.length} NF-e sem Chave/Accesskey na '
          'ZIN1008. Elas aparecem na lista sem itens; o vínculo precisa ser '
          'corrigido no SAP.',
        );
      }
      if (pares.isEmpty) return cabecalho;

      // (3) O status do cabeçalho da CONTAGEM, que diz se este check-in já foi
      // finalizado. Dispara junto e não depende de ninguém.
      final statusContagem =
          _statusContagem(backend, checkin: cabecalho.checkin);

      // (4)–(8) em paralelo: nenhuma depende da outra.
      final resultados = await Future.wait<List<Object>>([
        _fornecedores(backend, pares),
        _cabecalhos(backend, pares),
        _itensXml(backend, pares),
        _consumos(backend, pares),
        _contagensGravadas(backend, pares),
      ]);

      final fornecedores = resultados[0] as List<In100VarDto>;
      final cabecalhos = resultados[1] as List<In100AutomationHeaderDto>;
      final itensXml = resultados[2] as List<In100AutomationItemDto>;
      final consumos = resultados[3] as List<In100XmlItemConsumoDto>;
      final contagens = resultados[4] as List<IncContagemACegaLogDto>;

      // (9) depende da (7): só dá para pedir os itens de pedido depois de saber
      // quais pedidos o consumo cita.
      final pedidos = await _pedidos(backend, consumos);

      final notas = mapearNotas(
        checkin: dto,
        fornecedores: fornecedores,
        cabecalhos: cabecalhos,
        itensXml: itensXml,
        consumos: consumos,
        pedidos: pedidos,
      );

      return cabecalho
          .comNotas(_comContagens(notas, contagens))
          .comStatusContagem(await statusContagem);
    }, requiresNetwork: true);
  }

  /// **Não faz nada no ECC, de propósito.**
  ///
  /// No S/4HANA isto faz um MERGE em `INCheckin` levando o status do veículo de
  /// `L` para `E` ("em entrega"). O serviço ECC não tem como escrever esse
  /// campo: o `IN100_CHECKIN_MOTISTA` é `updatable="false"`, e o único POST que
  /// ele aceita é o da portaria, cujo `TIPO` mapeia `IN → 'L'` e `OUT → 'F'` —
  /// não há transição para `E`.
  ///
  /// Falhar aqui travaria a conferência inteira por causa de um campo de
  /// visibilidade. E a contagem não depende dele: `permiteContagem` aceita `L`
  /// e `E`, então o check-in que fica em `L` continua podendo ser contado e
  /// retomado depois de uma queda do coletor. O que se perde é a portaria
  /// enxergar "em entrega" enquanto o caminhão está na doca — o estado real da
  /// conferência está no `IN100ContagemACega`, criado logo em seguida por
  /// [garantirCabecalhoContagem].
  ///
  /// TODO(contagem-ecc): quando o time SAP publicar o `UPDATE_ENTITY` do
  /// `IN100_CHECKIN_MOTISTA` (ou um `TIPO` novo no POST), trocar por um MERGE.
  @override
  AsyncAppResult<bool> iniciarEntrega({
    required BackendService backend,
    required String checkin,
    required bool jaIniciado,
  }) {
    return runTask(() async => true);
  }

  // ── Gravação da contagem ───────────────────────────────────────────────────

  @override
  AsyncAppResult<bool> garantirCabecalhoContagem({
    required BackendService backend,
    required String checkin,
  }) {
    return runTask(() async {
      if (await _cabecalhoExiste(backend, checkin)) return true;

      try {
        final response = await _sap.write(
          backend: backend,
          service: _service,
          method: 'POST',
          path: ContagemCegaEccCampos.headerSet,
          // Sem `Credat`/`Cretim`: no ECC quem preenche é o `CREATE_ENTITY`,
          // com `SY-DATUM`/`SY-UZEIT`, e as duas propriedades estão declaradas
          // como não-creatable justamente por isso. Mandá-las daqui seria
          // deixar o relógio do coletor mandar no do servidor.
          body: {
            ContagemCegaEccCampos.checkin: checkin,
            ContagemCegaEccCampos.status: ContagemCegaEccCampos.statusCabecalho,
          },
        );
        final status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw ServerFailure(
            'O SAP respondeu $status ao abrir a contagem do check-in $checkin.',
          );
        }
        return true;
      } catch (erro) {
        // Dois coletores abriram o mesmo check-in: os dois leram 404, os dois
        // postaram, e o perdedor levou "já existe contagem". O cabeçalho
        // existe — que é tudo o que este método promete. Reler é mais barato e
        // mais robusto que parsear a mensagem de erro do SAP.
        if (await _cabecalhoExiste(backend, checkin)) return true;
        rethrow;
      }
    }, requiresNetwork: true);
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
  }) {
    return runTask(() async {
      // `Contagem` fica FORA do corpo: o `CREATE_ENTITY` do ECC numera a
      // tentativa e grava na mesma requisição. Mandar um número daqui
      // reintroduziria a corrida que o S/4HANA contorna com marca d'água.
      //
      // `LoteLido` também fica fora: a ZIN10011 não tem o campo, e propriedade
      // que a entidade não declara devolve 400.
      final response = await _sap.write(
        backend: backend,
        service: _service,
        method: 'POST',
        path: ContagemCegaEccCampos.logSet,
        body: <String, dynamic>{
          ContagemCegaEccCampos.checkin: checkin,
          ContagemCegaEccCampos.chave: chave,
          ContagemCegaEccCampos.accesskey: accesskey,
          ContagemCegaEccCampos.item: item,
          ContagemCegaEccCampos.lote: lote,
          ContagemCegaEccCampos.crenam: matricula,
          ContagemCegaEccCampos.quantidade: odataDecimalString(
            quantidade,
            casas: ContagemCegaEccCampos.casasQuantidade,
          ),
        },
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ServerFailure(
          'O SAP respondeu $status ao gravar a contagem do item $item.',
        );
      }

      final contagem = _contagemDaResposta(
        response.data,
        chave: chave,
        accesskey: accesskey,
        item: item,
      );

      // Só depois do 2xx: número que não chegou ao SAP não foi usado.
      _sequencia.registrar(
        chave: chave,
        accesskey: accesskey,
        item: item,
        contagem: contagem,
      );
      return contagem;
    }, requiresNetwork: true);
  }

  @override
  AsyncAppResult<List<ContagemLogRegistro>> lerContagens({
    required BackendService backend,
    required String chave,
    required String accesskey,
  }) {
    return runTask(() async {
      final linhas = await _sap.getAll(
        backend: backend,
        service: _service,
        path: ContagemCegaEccCampos.logSet,
        query: {r'$filter': _filtroNota(chave, accesskey)},
      );

      final registros = linhas
          .map(_logDaLinha)
          .map((dto) => dto.toRegistro())
          .toList(growable: false);

      // Semeia a marca d'água com o que já está gravado: é o que faz a
      // conferência retomada continuar de onde parou.
      for (final registro in registros) {
        _sequencia.registrar(
          chave: chave,
          accesskey: accesskey,
          item: registro.item,
          contagem: registro.contagem,
        );
      }
      return registros;
    }, requiresNetwork: true);
  }

  @override
  AsyncAppResult<bool> finalizarContagem({
    required BackendService backend,
    required String checkin,
    required bool comDevolucao,
  }) {
    return runTask(() async {
      final status = comDevolucao
          ? ContagemCegaEccCampos.statusFinalizadoDivergente
          : ContagemCegaEccCampos.statusFinalizadoConforme;

      final response = await _sap.write(
        backend: backend,
        service: _service,
        // MERGE e não PUT: o PUT do OData V2 substitui a entidade inteira e
        // apagaria `Credat`/`Cretim`, que não vão no corpo.
        method: 'MERGE',
        path: _pathCabecalho(checkin),
        body: {ContagemCegaEccCampos.status: status},
      );

      // MERGE responde 204: validar contra 200/201 rejeitaria o caminho feliz.
      final codigo = response.statusCode ?? 0;
      if (codigo < 200 || codigo >= 300) {
        throw ServerFailure(
          'O SAP respondeu $codigo ao finalizar o check-in $checkin.',
        );
      }

      // Só depois de o status estar gravado: o `IN100FinalizaCC` lê a ZIN10010
      // e processa a conferência já fechada. Disparar antes deixaria o ABAP
      // lendo um cabeçalho ainda em 'E'.
      await _dispararProcessamento(backend: backend, checkin: checkin);
      return true;
    }, requiresNetwork: true);
  }

  /// POST no `IN100FinalizaCC` — o gatilho do processamento no SAP.
  ///
  /// Falha aqui **propaga**: o cabeçalho já está em `C`/`D`, mas o
  /// processamento não aconteceu, e o conferente precisa saber disso enquanto
  /// ainda está na doca. O botão de finalizar é o retry — repetir o MERGE do
  /// mesmo status é inofensivo, e o POST volta a ser tentado.
  Future<void> _dispararProcessamento({
    required BackendService backend,
    required String checkin,
  }) async {
    final response = await _sap.write(
      backend: backend,
      service: _service,
      method: 'POST',
      path: ContagemCegaEccCampos.finalizaSet,
      body: {ContagemCegaEccCampos.checkin: checkin},
    );

    final codigo = response.statusCode ?? 0;
    if (codigo != 200 && codigo != 201) {
      throw ServerFailure(
        'O check-in $checkin foi fechado, mas o SAP respondeu $codigo ao '
        'processar a contagem. Tente finalizar de novo.',
      );
    }
  }

  // ── Leituras auxiliares ────────────────────────────────────────────────────

  /// NF-e vinculadas ao check-in (ZIN1008).
  Future<List<InCheckinItemDto>> _notasDoCheckin(
    BackendService backend,
    String checkin,
  ) async {
    final linhas = await _sap.getAll(
      backend: backend,
      service: _service,
      path: ContagemCegaEccCampos.checkinItensSet,
      query: {
        r'$filter':
            '${ContagemCegaEccCampos.checkin} eq ${odataLiteral(checkin)}',
      },
    );
    return linhas
        .map((l) => InCheckinItemDto(
              checkin: odataString(l[ContagemCegaEccCampos.checkin]),
              chave: odataString(l[ContagemCegaEccCampos.chave]),
              accesskey: odataString(l[ContagemCegaEccCampos.accesskey]),
              status: odataString(l[ContagemCegaEccCampos.status]),
            ))
        .toList(growable: false);
  }

  Future<List<In100VarDto>> _fornecedores(
    BackendService backend,
    List<(String, String)> pares,
  ) async {
    try {
      return await _buscar(
        backend: backend,
        entitySet: ContagemCegaEccCampos.varsSet,
        pares: pares,
        fromJson: In100VarDto.fromJson,
      );
    } catch (error) {
      // Falha aqui não derruba a conferência: sem fornecedor a tela mostra o
      // código, e o conferente ainda consegue contar.
      AppLogger.warning(
        'Contagem cega (ECC): não foi possível ler os fornecedores ($error). '
        'As notas ficam sem o nome.',
      );
      return const [];
    }
  }

  /// Cabeçalho fiscal da NF-e.
  ///
  /// Com `$select`, e aqui não é economia marginal: o `IN100AutomationHeader`
  /// do ECC expõe 25 propriedades, entre elas `InfCpl` — informações adicionais
  /// **sem MaxLength** no `$metadata`, que numa nota comprida carrega
  /// quilobytes por linha. A tela usa quatro campos.
  Future<List<In100AutomationHeaderDto>> _cabecalhos(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: ContagemCegaEccCampos.cabecalhoNfeSet,
        pares: pares,
        query: {
          r'$select': '${ContagemCegaEccCampos.chave},'
              '${ContagemCegaEccCampos.accesskey},'
              '${ContagemCegaEccCampos.modelo},'
              '${ContagemCegaEccCampos.serie},'
              '${ContagemCegaEccCampos.nNf}',
        },
        fromJson: In100AutomationHeaderDto.fromJson,
      );

  Future<List<In100AutomationItemDto>> _itensXml(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: ContagemCegaEccCampos.itensNfeSet,
        pares: pares,
        query: {
          r'$select': '${ContagemCegaEccCampos.chave},'
              '${ContagemCegaEccCampos.accesskey},'
              '${ContagemCegaEccCampos.item},'
              '${ContagemCegaEccCampos.cProd},'
              '${ContagemCegaEccCampos.xProd},'
              '${ContagemCegaEccCampos.uCom},'
              '${ContagemCegaEccCampos.qCom}',
        },
        fromJson: In100AutomationItemDto.fromJson,
      );

  /// Casamento XML × pedido (ZIN1006), via `IN100XmlItmConsByItmPo`.
  ///
  /// É a fonte do **lote** e da quantidade esperada por item de pedido. O
  /// `IN100AutomationItemsLotes` (ZIN1003) não serve no lugar: aquele é o que o
  /// XML declarou, este é o que foi casado com item de pedido — e só o segundo
  /// tem contra o que conferir.
  ///
  /// Sem `$select`: são nove propriedades e a tela usa oito. O que sobra
  /// (`AvisoRecebimento`) é um CHAR(10) por linha.
  Future<List<In100XmlItemConsumoDto>> _consumos(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: ContagemCegaEccCampos.consumoSet,
        pares: pares,
        fromJson: _consumoDaLinha,
      );

  Future<List<IncContagemACegaLogDto>> _contagensGravadas(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: ContagemCegaEccCampos.logSet,
        pares: pares,
        fromJson: _logDaLinha,
      );

  /// Itens de pedido citados pelos consumos.
  ///
  /// O `$filter` leva **só `Ebeln`**, e o par fino resolve no mapper — mesma
  /// assimetria de risco do S/4HANA: `Ebelp` é NUMC(5) e um valor normalizado
  /// de forma diferente pelos dois lados devolve lista vazia, deixando a tela
  /// **sem nenhum** nome de material. Filtrar largo devolve um superconjunto, e
  /// o `Map` do mapper escolhe o certo.
  ///
  /// O `GET_ENTITYSET` do ECC exige pedido ou material no filtro e recusa a
  /// chamada sem nenhum — daí o retorno antecipado quando não há pedido algum.
  Future<List<In100PoDto>> _pedidos(
    BackendService backend,
    List<In100XmlItemConsumoDto> consumos,
  ) async {
    final numeros = consumos
        .map((c) => c.pedido)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (numeros.isEmpty) return const [];

    final todos = <In100PoDto>[];
    for (final lote in emLotes(numeros, tamanho: _notasPorLote)) {
      final filtro = odataAnyOf(ContagemCegaEccCampos.ebeln, lote);
      if (filtro == null) continue;
      final linhas = await _sap.getAll(
        backend: backend,
        service: _service,
        path: ContagemCegaEccCampos.pedidosSet,
        query: {r'$filter': filtro},
      );
      todos.addAll(linhas.map(_pedidoDaLinha));
    }
    return todos;
  }

  /// Busca um entity set filtrando pelos pares `(Chave, Accesskey)`, em lotes.
  Future<List<T>> _buscar<T>({
    required BackendService backend,
    required String entitySet,
    required List<(String, String)> pares,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? query,
  }) async {
    final todos = <T>[];
    for (final lote in emLotes(pares, tamanho: _notasPorLote)) {
      final filtro = odataAnyOfPairs(
        ContagemCegaEccCampos.chave,
        ContagemCegaEccCampos.accesskey,
        lote,
      );
      if (filtro == null) continue;
      final linhas = await _sap.getAll(
        backend: backend,
        service: _service,
        path: entitySet,
        query: {r'$filter': filtro, ...?query},
      );
      todos.addAll(linhas.map(fromJson));
    }
    return todos;
  }

  // ── Cabeçalho da contagem ──────────────────────────────────────────────────

  String _pathCabecalho(String checkin) =>
      '${ContagemCegaEccCampos.headerSet}(${odataLiteral(checkin)})';

  String _filtroNota(String chave, String accesskey) =>
      '${ContagemCegaEccCampos.chave} eq ${odataLiteral(chave)} and '
      '${ContagemCegaEccCampos.accesskey} eq ${odataLiteral(accesskey)}';

  /// `false` **só** quando o cabeçalho não existe.
  Future<bool> _cabecalhoExiste(BackendService backend, String checkin) async =>
      (await _lerCabecalho(backend, checkin)) !=
      ContagemHeaderStatus.inexistente;

  /// Status do cabeçalho da contagem deste check-in.
  ///
  /// Nunca falha: esta leitura é acessória ao carregamento da conferência, e
  /// derrubar o check-in inteiro porque o cabeçalho não respondeu deixaria o
  /// conferente sem carga para contar por causa de uma trava que só vale no
  /// fim. [ContagemHeaderStatus.desconhecido] não bloqueia nada.
  Future<ContagemHeaderStatus> _statusContagem(
    BackendService backend, {
    required String checkin,
  }) async {
    try {
      return await _lerCabecalho(backend, checkin);
    } catch (_) {
      return ContagemHeaderStatus.desconhecido;
    }
  }

  /// Leitura do cabeçalho pela COLEÇÃO, não pela key — e isso não é estilo.
  ///
  /// Ler por key obriga a interpretar o código HTTP da ausência, e o ECC não
  /// devolve 404: o `GET_ENTITY` levanta `RESOURCE_NOT_FOUND` e este release
  /// do Gateway traduz para **400** (`/IWBEP/CX_MGW_BUSI_EXCEPTION`,
  /// "Resource not found for segment ''"). Com a leitura por key o app lia
  /// isso como erro de verdade e propagava — travando a abertura da nota e a
  /// finalização, as duas por causa de um cabeçalho que simplesmente ainda não
  /// existe.
  ///
  /// Com `$filter`, ausência é uma resposta **200 com lista vazia**. Não há
  /// status para adivinhar, e não depende de o release mapear a exceção para
  /// 404 ou 400.
  ///
  /// Mantém o `on DioException` para 404 porque um Gateway que responda certo
  /// continua tratado como ausência, não como falha.
  Future<ContagemHeaderStatus> _lerCabecalho(
    BackendService backend,
    String checkin,
  ) async {
    final List<Map<String, dynamic>> linhas;
    try {
      linhas = await _sap.getAll(
        backend: backend,
        service: _service,
        path: ContagemCegaEccCampos.headerSet,
        query: {
          r'$filter':
              '${ContagemCegaEccCampos.checkin} eq ${odataLiteral(checkin)}',
        },
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return ContagemHeaderStatus.inexistente;
      }
      rethrow;
    }

    if (linhas.isEmpty) return ContagemHeaderStatus.inexistente;

    return IncContagemACegaHeaderDto(
      checkin: odataString(linhas.first[ContagemCegaEccCampos.checkin]),
      status: odataString(linhas.first[ContagemCegaEccCampos.status]),
    ).statusContagem;
  }

  // ── Tradução das linhas do ECC ─────────────────────────────────────────────

  /// `IN100XmlItmConsByItmPo` → o DTO de consumo.
  ///
  /// Só o lote muda de nome em relação ao serviço CDS: `NLote` com N maiúsculo.
  /// `AvisoRecebimento` existe na entidade e é ignorado aqui — a conferência
  /// não decide nada pelo AR, e o DTO é compartilhado com o S/4HANA.
  static In100XmlItemConsumoDto _consumoDaLinha(Map<String, dynamic> json) =>
      In100XmlItemConsumoDto(
        chave: odataString(json[ContagemCegaEccCampos.chave]),
        accesskey: odataString(json[ContagemCegaEccCampos.accesskey]),
        item: odataString(json[ContagemCegaEccCampos.item]),
        lote: odataString(json[ContagemCegaEccCampos.lote]),
        pedido: odataString(json[ContagemCegaEccCampos.ebeln]),
        itemPedido: odataString(json[ContagemCegaEccCampos.ebelp]),
        quantidade: odataDecimal(json[ContagemCegaEccCampos.menge]),
        unidade: odataString(json[ContagemCegaEccCampos.meins]),
      );

  /// `IN100POs` → o DTO de item de pedido.
  ///
  /// Nomes bem diferentes do S/4HANA: a CDS renomeava para `PedidoCompra`,
  /// `Material`, `DescricaoMaterial` e `UnidadeMedida`; a estrutura DDIC do ECC
  /// mantém `Ebeln`, `Matnr`, `Maktx` e `Meins`.
  static In100PoDto _pedidoDaLinha(Map<String, dynamic> json) => In100PoDto(
        pedido: odataString(json[ContagemCegaEccCampos.ebeln]),
        item: odataString(json[ContagemCegaEccCampos.ebelp]),
        material: odataString(json[ContagemCegaEccCampos.matnr]),
        descricaoMaterial: odataString(json[ContagemCegaEccCampos.maktx]),
        unidade: odataString(json[ContagemCegaEccCampos.meins]),
      );

  /// `IN100ContagemACegaLog` → o DTO do log.
  ///
  /// `loteLido` vem vazio porque a ZIN10011 não tem o campo — igual ao S/4HANA,
  /// onde ele está atrás de um kill switch desligado.
  static IncContagemACegaLogDto _logDaLinha(Map<String, dynamic> json) =>
      IncContagemACegaLogDto(
        chave: odataString(json[ContagemCegaEccCampos.chave]),
        accesskey: odataString(json[ContagemCegaEccCampos.accesskey]),
        item: odataString(json[ContagemCegaEccCampos.item]),
        lote: odataString(json[ContagemCegaEccCampos.lote]),
        loteLido: '',
        contagem:
            int.tryParse(odataString(json[ContagemCegaEccCampos.contagem])) ??
                0,
        quantidade: odataDecimal(json[ContagemCegaEccCampos.quantidade]),
        crenam: odataString(json[ContagemCegaEccCampos.crenam]),
      );

  /// Número da tentativa que o SAP atribuiu, lido da entidade devolvida pelo
  /// POST.
  ///
  /// O OData V2 devolve a entidade criada dentro de `d`. Se por alguma
  /// configuração ela não vier, cai numa estimativa local — a gravação já
  /// aconteceu, e devolver `0` faria a tela contar a tentativa como se não
  /// existisse.
  int _contagemDaResposta(
    dynamic data, {
    required String chave,
    required String accesskey,
    required String item,
  }) {
    final corpo = data is Map ? (data['d'] ?? data) : null;
    if (corpo is Map) {
      final numero = int.tryParse(
            odataString(corpo[ContagemCegaEccCampos.contagem]),
          ) ??
          0;
      if (numero > 0) return numero;
    }

    final estimado = _sequencia.proxima(
      chave: chave,
      accesskey: accesskey,
      item: item,
      maiorNoSap: 0,
    );
    AppLogger.warning(
      'Contagem cega (ECC): o POST do log não devolveu o campo '
      '${ContagemCegaEccCampos.contagem}. A gravação ocorreu; a tela vai '
      'mostrar $estimado, que é uma estimativa local.',
    );
    return estimado;
  }

  /// Reexecuta as tentativas já gravadas sobre as notas recém-montadas, e
  /// semeia a marca d'água.
  List<ContagemNotaFiscal> _comContagens(
    List<ContagemNotaFiscal> notas,
    List<IncContagemACegaLogDto> contagens,
  ) {
    if (contagens.isEmpty) return notas;

    final porNota = <(String, String), List<ContagemLogRegistro>>{};
    for (final dto in contagens) {
      (porNota[dto.nota] ??= []).add(dto.toRegistro());
      _sequencia.registrar(
        chave: dto.chave,
        accesskey: dto.accesskey,
        item: dto.item,
        contagem: dto.contagem,
      );
    }

    return rehidratarNotas(notas: notas, registrosPorNota: porNota);
  }
}
