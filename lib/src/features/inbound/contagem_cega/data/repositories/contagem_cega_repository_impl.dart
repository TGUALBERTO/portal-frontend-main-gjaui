import 'dart:math';

import 'package:dio/dio.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_header_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_item_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_po_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_var_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_xml_item_consumo_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/contagem_sequencia.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in_checkin_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/inc_contagem_a_cega_campos.dart';
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
import 'package:gjamobile/src/features/inbound/shared/data/sap_odata_client.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Lê a carga da contagem cega no SAP Gateway (OData V2).
///
/// **Serviço diferente do check-in/check-out de veículos**: aquele usa
/// `ZGJAAUTO_GENERIC_SRV`; este usa `ZGJAAUTO_SB_GENERIC`, gerado por CDS. Mesmo
/// sistema e mesmo host — muda só o path e, com ele, a sessão (o
/// `SapSessionRepository` cacheia por `host|serviço`).
///
/// São **8 leituras fixas** para o check-in inteiro, independentemente de quantas
/// notas ele tem: a (1) abre o check-in, a (2) e as (3)–(7) vão em paralelo
/// filtrando todas as notas de uma vez, e a (8) depende do resultado da (6). A
/// alternativa ingênua — uma chamada por nota — daria `2 + 5N`, o que num
/// caminhão com 5 notas é 27 idas ao SAP com o conferente esperando de pé na
/// doca.
class ContagemCegaRepositoryImpl implements ContagemCegaRepository {
  ContagemCegaRepositoryImpl(this._sap);

  final SapODataClient _sap;

  /// Memória do último `Contagem` gravado por linha.
  ///
  /// Vive aqui porque o repositório é `addLazySingleton` no DI: a marca
  /// sobrevive de uma nota para a outra, e o app não reusa um número que ele
  /// mesmo já gravou nesta sessão nem que a releitura do SAP não o devolva.
  final ContagemSequencia _sequencia = ContagemSequencia();

  /// Serviço OData desta feature. É o MESMO valor mandado em
  /// `/sap/session?service=`, para um 403 de `S_SERVICE` aparecer na abertura da
  /// sessão e não no meio da conferência.
  static const String _service = 'sap/ZGJAAUTO_SB_GENERIC';

  /// Serviço do `IN100FinalizaCC` — o MESMO do check-in/check-out de veículos.
  ///
  /// A finalização é a única chamada desta feature que sai do
  /// `ZGJAAUTO_SB_GENERIC`: as tabelas Z da contagem vivem lá, mas o
  /// processamento do fim da conferência é do serviço genérico. Não há Dio novo
  /// — o host é o mesmo e o [SapODataClient] é parametrizado por serviço; o que
  /// muda é a sessão, que o `SapSessionRepository` cacheia por `host|serviço`.
  static const String _serviceFinaliza = 'sap/ZGJAAUTO_GENERIC_SRV';

  /// Quantas notas por `$filter`. Cada par (Chave 20 + Accesskey 44) custa ~95
  /// caracteres codificados; 20 pares ficam em ~1,9 KB, dentro de qualquer
  /// limite de URI.
  static const int _notasPorLote = 20;

  @override
  AsyncAppResult<ContagemCheckin> carregarCheckin({
    required BackendService backend,
    required String checkin,
  }) {
    return runTask(() async {
      final Map<String, dynamic> json;
      try {
        // (1) — o único $expand útil do serviço: cabeçalho + as NF-es do
        // caminhão numa ida só.
        json = await _sap.getEntity(
          backend: backend,
          service: _service,
          path: "INCheckin('$checkin')",
          query: const {r'$expand': 'to_Items'},
        );
      } on DioException catch (error) {
        if (error.response?.statusCode == 404) {
          throw ValidationFailure('Check-in $checkin não encontrado no SAP.');
        }
        rethrow;
      }

      final dto = InCheckinDto.fromJson(json);
      final cabecalho = ContagemCheckin(
        checkin: dto.checkin.isEmpty ? checkin : dto.checkin,
        status: CheckinStatus.fromApi(dto.status),
        motorista: dto.motorista,
        cpf: dto.cpf,
        placa: dto.placa,
      );

      // Status que não permite contagem para aqui: as leituras seguintes custam
      // caro e seriam jogadas fora. A tela ainda recebe motorista e placa para
      // explicar o bloqueio a quem está na doca.
      if (!cabecalho.status.permiteContagem) return cabecalho;
      if (dto.itens.isEmpty) return cabecalho;

      final pares = dto.itens
          .map((i) => (i.chave, i.accesskey))
          .toSet()
          .toList(growable: false);

      // (2) O `Status` do cabeçalho da CONTAGEM, que diz se este check-in já
      // foi finalizado. Vai junto das demais e não depende de nenhuma delas:
      // sem isto o resumo liberaria "Finalizar" num check-in que o SAP já
      // fechou, mandando um segundo `IN100FinalizaCC` para o mesmo caminhão.
      final statusContagem = _statusContagem(backend, checkin: cabecalho.checkin);

      // (3)–(7) em paralelo: nenhuma depende da outra.
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

      // (8) depende da (6): só dá para pedir os itens de pedido depois de saber
      // quais são.
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

  @override
  AsyncAppResult<bool> iniciarEntrega({
    required BackendService backend,
    required String checkin,
    required bool jaIniciado,
  }) {
    return runTask(() async {
      // Retomada de contagem: o check-in já está em 'E' e reescrever o mesmo
      // valor só gastaria uma ida ao SAP e um registro de modificação.
      if (jaIniciado) return true;

      final response = await _sap.write(
        backend: backend,
        service: _service,
        // MERGE e não PUT: o PUT do OData V2 substitui a entidade inteira e
        // apagaria motorista, placa e CPF, que não vão no corpo.
        method: 'MERGE',
        path: "INCheckin('$checkin')",
        body: {'Status': CheckinStatus.emEntrega.codigo},
      );

      // MERGE responde 204 No Content — validar contra 200/201, como faz o POST
      // do serviço de veículos, rejeitaria o caminho feliz.
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ServerFailure(
          'O SAP respondeu $status ao iniciar a contagem do check-in $checkin.',
        );
      }
      return true;
    }, requiresNetwork: true);
  }

  // ── Gravação da contagem ───────────────────────────────────────────────────

  @override
  AsyncAppResult<bool> garantirCabecalhoContagem({
    required BackendService backend,
    required String checkin,
  }) {
    return runTask(() async {
      final path = _pathCabecalho(checkin);
      if (await _cabecalhoExiste(backend, path)) return true;

      try {
        final response = await _sap.write(
          backend: backend,
          service: _service,
          method: 'POST',
          path: ContagemCegaCampos.headerSet,
          body: IncContagemACegaHeaderDto.corpoCriacao(
            checkin: checkin,
            momento: DateTime.now(),
          ),
        );
        final status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw ServerFailure(
            'O SAP respondeu $status ao abrir a contagem do check-in $checkin.',
          );
        }
        return true;
      } catch (erro) {
        // Dois coletores abriram o mesmo check-in (ou a segunda nota do mesmo
        // caminhão): os dois leram 404, os dois postaram, e o perdedor levou
        // erro de chave duplicada. O cabeçalho existe — que é tudo o que este
        // método promete. Reler é mais barato e muito mais robusto que parsear
        // o código de erro do SAP.
        if (await _cabecalhoExiste(backend, path)) return true;
        rethrow;
      }
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
          ? ContagemCegaCampos.statusFinalizadoDivergente
          : ContagemCegaCampos.statusFinalizadoConforme;

      final response = await _sap.write(
        backend: backend,
        service: _service,
        method: 'MERGE',
        path: _pathCabecalho(checkin),
        body: IncContagemACegaHeaderDto.corpoFinalizacao(status: status),
      );

      // MERGE responde **204**: validar contra 200/201 rejeitaria o caminho
      // feliz.
      final codigo = response.statusCode ?? 0;
      if (codigo < 200 || codigo >= 300) {
        throw ServerFailure(
          'O SAP respondeu $codigo ao finalizar o check-in $checkin.',
        );
      }

      // Só depois de o status estar gravado: o `IN100FinalizaCC` processa a
      // conferência já fechada. Disparar antes deixaria o ABAP lendo um
      // cabeçalho ainda em `'E'`.
      await _dispararProcessamento(backend: backend, checkin: checkin);
      return true;
    }, requiresNetwork: true);
  }

  /// POST no `IN100FinalizaCC` — o gatilho do processamento no SAP.
  ///
  /// Corpo com **só o check-in**: o desfecho (`'C'`/`'D'`) o ABAP deriva do log,
  /// que já está gravado quando isto roda. Entity set criado com SEGW, então o
  /// formato é o mesmo do `IN100_CHECKIN_MOTISTA` do check-in de veículos —
  /// POST com corpo JSON, e create no OData V2 responde 200 ou 201.
  ///
  /// Falha aqui **propaga**: o cabeçalho já está em `'C'`/`'D'`, mas o
  /// processamento não aconteceu, e o conferente precisa saber disso enquanto
  /// ainda está na doca. O botão de finalizar é o retry — repetir o MERGE do
  /// mesmo status é inofensivo, e o POST volta a ser tentado.
  Future<void> _dispararProcessamento({
    required BackendService backend,
    required String checkin,
  }) async {
    final response = await _sap.write(
      backend: backend,
      service: _serviceFinaliza,
      method: 'POST',
      path: ContagemCegaCampos.finalizaSet,
      body: {ContagemCegaCampos.checkin: checkin},
    );

    final codigo = response.statusCode ?? 0;
    if (codigo != 200 && codigo != 201) {
      throw ServerFailure(
        'O check-in $checkin foi fechado, mas o SAP respondeu $codigo ao '
        'processar a contagem. Tente finalizar de novo.',
      );
    }
  }

  @override
  AsyncAppResult<List<ContagemLogRegistro>> lerContagens({
    required BackendService backend,
    required String chave,
    required String accesskey,
  }) {
    return runTask(() async {
      // Sem `$select`, pela mesma razão de `_fornecedores`: os campos de lote
      // ainda não estão confirmados, e `$select` com campo inexistente devolve
      // 400.
      final linhas = await _sap.getAll(
        backend: backend,
        service: _service,
        path: ContagemCegaCampos.logSet,
        query: {r'$filter': _filtroNota(chave, accesskey)},
      );
      final registros = linhas
          .map(IncContagemACegaLogDto.fromJson)
          .map((dto) => dto.toRegistro())
          .toList(growable: false);

      // Semeia a marca d'água com o que já está gravado. É o que faz a contagem
      // retomada (coletor reaberto no meio do caminhão) continuar de onde
      // parou em vez de tentar o número 1 de novo.
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
      final contagem = await _proximaContagem(
        backend: backend,
        chave: chave,
        accesskey: accesskey,
        item: item,
      );

      final Response<dynamic> response;
      try {
        response = await _sap.write(
          backend: backend,
          service: _service,
          method: 'POST',
          path: ContagemCegaCampos.logSet,
          body: IncContagemACegaLogDto.corpoRegistro(
            checkin: checkin,
            chave: chave,
            accesskey: accesskey,
            item: item,
            lote: lote,
            loteLido: loteLido,
            contagem: contagem,
            quantidade: quantidade,
            matricula: matricula,
            momento: DateTime.now(),
          ),
        );
      } on DioException catch (error) {
        // O serviço não trata chave duplicada: o `INSERT` do ABAP dumpa e o
        // Gateway devolve 500 `RAISE_SHORTDUMP`. Sem esta tradução, o
        // conferente lê "erro do servidor" e não tem o que fazer — e quem for
        // investigar não sabe que ST22 é o lugar.
        if (error.response?.statusCode == 500) {
          throw ServerFailure(
            'O SAP recusou a contagem nº $contagem do item $item (erro interno '
            'do serviço). A causa mais comum é essa contagem já existir no log. '
            'Tente de novo; se repetir, o time SAP precisa olhar o dump em '
            'ST22.',
          );
        }
        rethrow;
      }

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ServerFailure(
          'O SAP respondeu $status ao gravar a contagem do item $item.',
        );
      }

      // Só depois do 2xx: número de tentativa que não chegou ao SAP não foi
      // usado, e queimá-lo à toa abriria buraco na sequência.
      _sequencia.registrar(
        chave: chave,
        accesskey: accesskey,
        item: item,
        contagem: contagem,
      );
      return contagem;
    }, requiresNetwork: true);
  }

  /// `INCContagemACegaHeader('0000000123')`.
  ///
  /// Key de propriedade única vai **sem nome** — `(Checkin='123')` também é
  /// aceito pelo Gateway, mas a forma curta é a que o resto do inbound usa
  /// (`INCheckin('$checkin')`), e o valor ainda passa por [odataLiteral] para o
  /// escape ser o mesmo em todo lugar.
  String _pathCabecalho(String checkin) =>
      '${ContagemCegaCampos.headerSet}(${odataLiteral(checkin)})';

  String _filtroNota(String chave, String accesskey) =>
      '${ContagemCegaCampos.chave} eq ${odataLiteral(chave)} and '
      '${ContagemCegaCampos.accesskey} eq ${odataLiteral(accesskey)}';

  /// `false` **só** quando o cabeçalho não existe.
  Future<bool> _cabecalhoExiste(BackendService backend, String path) async =>
      (await _lerCabecalho(backend, path)) != ContagemHeaderStatus.inexistente;

  /// `Status` do cabeçalho da contagem deste check-in.
  ///
  /// Nunca falha: esta leitura é acessória ao carregamento da conferência, e
  /// derrubar o check-in inteiro porque o `INCContagemACegaHeader` não respondeu
  /// deixaria o conferente sem carga para contar por causa de uma trava que só
  /// vale no fim. [ContagemHeaderStatus.desconhecido] não bloqueia nada, então
  /// falhar para ele é degradar, não abrir uma porta.
  Future<ContagemHeaderStatus> _statusContagem(
    BackendService backend, {
    required String checkin,
  }) async {
    try {
      return await _lerCabecalho(backend, _pathCabecalho(checkin));
    } catch (_) {
      return ContagemHeaderStatus.desconhecido;
    }
  }

  /// Leitura crua do cabeçalho pela key. 404 é
  /// [ContagemHeaderStatus.inexistente] — "nunca teve contagem", não erro.
  Future<ContagemHeaderStatus> _lerCabecalho(
    BackendService backend,
    String path,
  ) async {
    try {
      final json = await _sap.getEntity(
        backend: backend,
        service: _service,
        path: path,
      );
      return IncContagemACegaHeaderDto.fromJson(json).statusContagem;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return ContagemHeaderStatus.inexistente;
      }
      rethrow;
    }
  }

  /// Próximo `Contagem` = **maior conhecido + 1**, onde "conhecido" é o maior
  /// entre o que o SAP devolve e o que este app já gravou (ver
  /// [ContagemSequencia]).
  ///
  /// Máximo e não quantidade de linhas: uma linha apagada pelo suporte abriria
  /// um buraco, e `linhas.length + 1` reescreveria uma chave já usada — num log
  /// append-only isso é sobrescrever a tentativa de outra pessoa.
  ///
  /// **O filtro leva só `Chave`, `Accesskey` e `Item`** — nem `Checkin`, nem
  /// `nLote`, embora os dois façam parte da chave. A regra aqui não é simetria
  /// com a chave, é assimetria de risco: filtro mais estreito que a chave gera
  /// número duplicado (e este serviço responde a chave duplicada com um **500
  /// `RAISE_SHORTDUMP`**, na cara do conferente), mais largo só pula número.
  ///
  /// - `Checkin` não separa nada: `Chave`+`Accesskey` já identificam a NF-e, que
  ///   pertence a um check-in só.
  /// - `nLote` **separaria demais**. O serviço não persiste o `nLote` que o app
  ///   envia — POST com `nLote: 'C2212026'` volta na leitura com `nLote` vazio —
  ///   então filtrar por ele devolve `results: []` mesmo com a linha gravada, e
  ///   a 2ª contagem repete o número 1 em cima da 1ª.
  Future<int> _proximaContagem({
    required BackendService backend,
    required String chave,
    required String accesskey,
    required String item,
  }) async {
    final termos = <String>[
      _filtroNota(chave, accesskey),
      '${ContagemCegaCampos.item} eq ${odataLiteral(item)}',
    ];
    final filtro = termos.join(' and ');

    final linhas = await _sap.getAll(
      backend: backend,
      service: _service,
      path: ContagemCegaCampos.logSet,
      query: {r'$filter': filtro},
    );

    final maiorNoSap = linhas
        .map((l) =>
            int.tryParse(odataString(l[ContagemCegaCampos.contagem])) ?? 0)
        .fold<int>(0, max);

    // Diagnóstico do sintoma que motivou a marca d'água: o SAP devolveu menos
    // do que já gravamos. A contagem segue certa (a marca cobre), mas o filtro
    // ou a visibilidade do commit merecem olhada — sem este aviso o problema
    // volta a ser invisível.
    final jaGravado = _sequencia.conhecida(
      chave: chave,
      accesskey: accesskey,
      item: item,
    );
    if (maiorNoSap < jaGravado) {
      AppLogger.warning(
        'Contagem cega: o SAP devolveu Contagem máx. $maiorNoSap para o item '
        '$item, mas este app já gravou $jaGravado. Seguindo pela marca local '
        'para não repetir chave. Filtro usado: $filtro',
      );
    }

    return _sequencia.proxima(
      chave: chave,
      accesskey: accesskey,
      item: item,
      maiorNoSap: maiorNoSap,
    );
  }

  // ── Leituras ───────────────────────────────────────────────────────────────

  Future<List<In100VarDto>> _fornecedores(
    BackendService backend,
    List<(String, String)> pares,
  ) async {
    // Sem `$select` de propósito: `NomeFornecedor` ainda vai ser publicado pelo
    // time SAP, e um `$select` com campo inexistente devolve 400 — sem ele o
    // campo simplesmente não vem e a nota cai no código do fornecedor.
    try {
      return await _buscar(
        backend: backend,
        entitySet: 'IN100Vars',
        pares: pares,
        fromJson: In100VarDto.fromJson,
      );
    } catch (error) {
      // Falha aqui não derruba a conferência: sem fornecedor a tela mostra o
      // código, e o conferente ainda consegue contar.
      AppLogger.warning(
        'Contagem cega: não foi possível ler os fornecedores ($error). '
        'As notas ficam sem o nome.',
      );
      return const [];
    }
  }

  Future<List<In100AutomationHeaderDto>> _cabecalhos(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: 'IN100AutomationHeader',
        pares: pares,
        query: const {r'$select': 'Chave,Accesskey,Mod,Serie,NNf'},
        fromJson: In100AutomationHeaderDto.fromJson,
      );

  Future<List<In100AutomationItemDto>> _itensXml(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: 'IN100AutomationItems',
        pares: pares,
        query: const {
          r'$select': 'Chave,Accesskey,Item,CProd,XProd,UCom,QCom',
        },
        fromJson: In100AutomationItemDto.fromJson,
      );

  /// (7) — o log de contagem de **todas** as notas do caminhão, numa ida só.
  ///
  /// Existe porque o status da nota (`Pendente`/`Devolver`/`OK`) é derivado dos
  /// itens, e os itens só sabem o que foi contado depois da reidratação. Sem
  /// esta leitura, reabrir o app mostrava a lista inteira como `Pendente` até o
  /// conferente entrar em cada nota — inclusive uma nota já marcada para
  /// devolução, que é justamente a que ninguém pode contar de novo.
  ///
  /// Filtra por `(Chave, Accesskey)` como as demais, e **não** por `Checkin`:
  /// é o formato de filtro que este serviço comprovadamente honra, e a NF-e
  /// pertence a um check-in só.
  Future<List<IncContagemACegaLogDto>> _contagensGravadas(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: ContagemCegaCampos.logSet,
        pares: pares,
        fromJson: IncContagemACegaLogDto.fromJson,
      );

  /// Reexecuta as tentativas já gravadas sobre as notas recém-montadas.
  ///
  /// Também **semeia a marca d'água** de [ContagemSequencia]: depois disto o
  /// primeiro `registrarContagem` da sessão já sabe em que número parou, mesmo
  /// que o conferente não tenha aberto a nota antes.
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

  Future<List<In100XmlItemConsumoDto>> _consumos(
    BackendService backend,
    List<(String, String)> pares,
  ) =>
      _buscar(
        backend: backend,
        entitySet: 'IN100XmlItemsConsumByItemPO',
        pares: pares,
        fromJson: In100XmlItemConsumoDto.fromJson,
      );

  /// (7) — os itens de pedido citados pelos consumos. É a **única fonte do nome
  /// do material do SAP** (`Material` + `DescricaoMaterial`).
  ///
  /// O casamento é por `(PedidoCompra, Item)`, mas o `$filter` leva **só
  /// `PedidoCompra`** e o par fino resolve no mapper. Não é economia de código,
  /// é a mesma assimetria de risco do incremental: `Item` é NUMC(5) e este
  /// serviço não serializa NUMC de forma consistente (já voltou `'1'` onde a
  /// tabela guarda `'00001'`). Um `Item` no `$filter` que o ABAP normalize
  /// diferente devolve lista vazia e a tela fica **sem nenhum** nome de
  /// material; filtrar largo devolve um superconjunto — o pedido costuma cobrir
  /// vários itens que a nota vai precisar de qualquer forma — e o `Map` do
  /// mapper, que compara os dois lados já normalizados, escolhe o certo.
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
      final filtro = odataAnyOf('PedidoCompra', lote);
      if (filtro == null) continue;
      final linhas = await _sap.getAll(
        backend: backend,
        service: _service,
        path: 'IN100POs',
        query: {
          r'$filter': filtro,
          r'$select':
              'PedidoCompra,Item,Material,DescricaoMaterial,UnidadeMedida',
        },
      );
      todos.addAll(linhas.map(In100PoDto.fromJson));
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
      final filtro = odataAnyOfPairs('Chave', 'Accesskey', lote);
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
}
