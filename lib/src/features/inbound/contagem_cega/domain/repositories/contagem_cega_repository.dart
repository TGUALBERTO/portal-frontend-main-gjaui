import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_checkin.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Leitura da carga a conferir no SAP (serviço `ZGJAAUTO_SB_GENERIC`).
///
/// O [backend] (qual SAP Gateway) vem de fora: quem conhece a empresa do usuário
/// é a camada de apresentação, então a data layer não depende do
/// `AccessController`.
///
/// O número do check-in é **String zero-padded em 10** — o SAP usa NUMC(10) e a
/// key predicate exige o valor completo (`'0000000003'`); `'3'` devolve 404.
///
/// A **gravação da contagem** vive nas tabelas Z `INCContagemACegaHeader`
/// (um registro por NF-e) e `INCContagemACegaLog` (append-only, um registro por
/// tentativa). O log é a fonte da verdade: é dele que a conferência se
/// reconstrói quando o coletor cai no meio de um caminhão.
abstract class ContagemCegaRepository {
  /// Lê o check-in e, **se o status permitir contagem**, as notas com os itens.
  ///
  /// Nunca falha por causa do status: devolve o cabeçalho com `notas` vazia e
  /// deixa a política com o controller, que sabe montar a mensagem para a tela.
  ///
  /// Traz também o `Status` do `INCContagemACegaHeader` em
  /// `ContagemCheckin.statusContagem` — é ele que diz se a conferência deste
  /// check-in **já foi finalizada**, e quem trava o botão de finalizar no
  /// resumo. Leitura acessória: se ela falhar, o check-in carrega assim mesmo
  /// com `desconhecido`, que não bloqueia nada.
  AsyncAppResult<ContagemCheckin> carregarCheckin({
    required BackendService backend,
    required String checkin,
  });

  /// Marca o check-in como "em entrega" (`Status = 'E'`).
  ///
  /// Idempotente: quando o check-in já está em `E` (contagem retomada depois de
  /// uma queda do coletor) não escreve nada.
  AsyncAppResult<bool> iniciarEntrega({
    required BackendService backend,
    required String checkin,
    required bool jaIniciado,
  });

  /// Garante que o check-in tem cabeçalho de contagem no SAP. **Idempotente.**
  ///
  /// O cabeçalho é do **caminhão**, não da nota: `INCContagemACegaHeader` tem
  /// key `(Checkin)` e nem sequer declara `Chave`/`Accesskey`. Abrir a segunda
  /// NF-e do mesmo check-in acha o cabeçalho já criado e não escreve nada.
  ///
  /// Lê pela key; 404 significa "primeira contagem deste check-in" e dispara o
  /// POST. Qualquer outra falha propaga: entrar na nota sem cabeçalho deixaria
  /// o log órfão, e a decisão do processo é bloquear a entrada explicando o
  /// motivo.
  AsyncAppResult<bool> garantirCabecalhoContagem({
    required BackendService backend,
    required String checkin,
  });

  /// Fecha a conferência do check-in: MERGE no `Status` do cabeçalho **e** o
  /// POST que dispara o processamento no SAP (`IN100FinalizaCC`).
  ///
  /// Nesta ordem, e as duas escritas: o gatilho processa uma conferência já
  /// fechada, então dispará-lo antes do MERGE deixaria o ABAP lendo um
  /// cabeçalho ainda em `'E'`. O POST leva só o check-in — o desfecho o ABAP
  /// deriva do log.
  ///
  /// [comDevolucao] escolhe o desfecho gravado — `'D'` quando **alguma** NF-e
  /// foi condenada à devolução, `'C'` quando todas foram conferidas. O
  /// cabeçalho é um por check-in, então o status é do caminhão inteiro; o
  /// desfecho item a item continua no log.
  ///
  /// É a única escrita do fluxo que **não** acontece durante a contagem: até
  /// aqui o cabeçalho fica em `'E'`, e um check-in abandonado no meio é
  /// exatamente isso — um cabeçalho que nunca saiu de `'E'`.
  AsyncAppResult<bool> finalizarContagem({
    required BackendService backend,
    required String checkin,
    required bool comDevolucao,
  });

  /// Todas as tentativas já gravadas de UMA NF-e, de todos os itens.
  ///
  /// Uma leitura por nota, não por item: a tela reidrata a nota inteira ao
  /// abrir, e N chamadas numa nota de 30 itens é o conferente esperando de pé
  /// na doca — mesma razão das seis leituras fixas de [carregarCheckin].
  AsyncAppResult<List<ContagemLogRegistro>> lerContagens({
    required BackendService backend,
    required String chave,
    required String accesskey,
  });

  /// Grava UMA tentativa e devolve o número de contagem efetivamente usado.
  ///
  /// O incremental é lido do SAP **imediatamente antes** do POST. Derivá-lo das
  /// tentativas da tela erraria em dois casos reais: uma contagem que bate não
  /// incrementa `tentativas` mas gera linha, e dois coletores na mesma nota não
  /// compartilham memória.
  ///
  /// [item] vai **literal** — é o CHAR(5) zero-padded que o próprio serviço
  /// devolveu em `IN100AutomationItems.Item`.
  ///
  /// [lote] é o lote da NF (identidade da linha, entra no filtro do
  /// incremental); [loteLido] é o que o conferente escaneou, só rastreabilidade.
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
  });
}
