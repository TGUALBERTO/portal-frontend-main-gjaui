import 'package:flutter/widgets.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_quantidade.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_regras.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_checkin.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_lancamento.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_mensagem.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_header_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_mensagem_tipo.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_nf_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_resultado.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/repositories/contagem_cega_repository.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/services/rehidratar_nota.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/sap_backend_resolver.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/selecao_empresa_sap.dart';
import 'package:gjamobile/src/shared/enums/app_status.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Sessão de conferência da contagem cega, compartilhada pelos cinco
/// submódulos de tela (scan → notas → itens → contagem → resumo).
///
/// **App-scoped** (`addLazySingleton` no DI): o fluxo atravessa cinco rotas e um
/// controller por tela perderia a conferência a cada `context.go`. Quem zera o
/// estado é [reiniciar] — não o `dispose()` de uma tela.
///
/// A **gravação** é por tentativa e acontece antes de o estado local mudar (ver
/// [confirmarContagem]): o `INCContagemACegaLog` é a fonte da verdade, e
/// [abrirNota] reconstrói a conferência a partir dele quando o coletor cai.
///
/// **Nunca chame [abrirNota] nem [confirmarContagem] de `initState` ou `build`.**
/// Os dois escrevem signals, e escrever signal durante o build faz um
/// `SignalBuilder` já montado pedir rebuild no meio do build
/// (`SignalEffectException`). Os dois só saem de handler de toque/`onSubmitted`.
class ContagemCegaController with SelecaoEmpresaSap {
  ContagemCegaController({
    required ContagemCegaRepository repository,
    required SapBackendResolver backends,
    AccessController? access,
  })  : _repository = repository,
        _backends = backends,
        _access = access;

  final ContagemCegaRepository _repository;
  final SapBackendResolver _backends;
  final AccessController? _access;

  // ── Contrato do SelecaoEmpresaSap ─────────────────────────────────────────
  // A seleção de empresa, a resolução do backend e o erro de configuração vêm
  // do mixin, compartilhado com o CheckinCheckoutVeiculoController.

  @override
  AccessController? get accessDaSelecao => _access;

  @override
  SapBackendResolver get backendsDaSelecao => _backends;

  @override
  String get descricaoOperacao => 'a contagem cega';

  /// Trocar de empresa zera a conferência: as notas carregadas são do SAP
  /// anterior, e contar uma delas gravaria no sistema errado.
  @override
  void aoTrocarEmpresa() => reiniciar();

  @override
  bool get operacaoEmAndamento =>
      _status.value == AppStatus.loading ||
      _abrindoNota.value ||
      _gravando.value;

  /// Quantas contagens divergentes o conferente pode fazer antes de a NF-e ser
  /// marcada para devolução.
  ///
  /// Alias da constante do domínio: a reidratação reexecuta a mesma regra sobre
  /// o log do SAP, e duas cópias sairiam de sincronia.
  static const int maxTentativas = maxTentativasContagem;

  /// Chave do check-in no formato do SAP (NUMC(10) zero-padded), usada nas
  /// escritas. A tela mostra [checkinSignal], que guarda só os dígitos.
  String _checkinKey = '';

  /// Número do check-in — digitado, lido pelo leitor físico do coletor ou
  /// preenchido pelo scanner de QR Code.
  final checkinController = TextEditingController();
  final checkinFocus = FocusNode();

  final loteController = TextEditingController();
  final quantidadeController = TextEditingController();
  final quantidadeFocus = FocusNode();

  late final Signal<AppStatus> _status = signal(AppStatus.initial);
  late final Signal<String?> _checkin = signal(null);
  late final Signal<List<ContagemNotaFiscal>> _notas = signal(const []);
  late final Signal<ContagemMensagem?> _mensagem = signal(null);
  late final Signal<bool> _finalizado = signal(false);
  late final Signal<ContagemHeaderStatus> _statusContagem =
      signal(ContagemHeaderStatus.inexistente);
  late final Signal<bool> _contagemCega = signal(true);
  late final Signal<AppFailure?> _erro = signal(null);
  late final Signal<ContagemCheckin?> _checkinInfo = signal(null);
  late final Signal<bool> _abrindoNota = signal(false);
  late final Signal<bool> _gravando = signal(false);
  late final Signal<AppFailure?> _erroSap = signal(null);

  /// Estado da leitura do check-in.
  ReadonlySignal<AppStatus> get statusSignal => _status;

  /// Número do check-in em conferência, ou `null` fora de uma sessão.
  ReadonlySignal<String?> get checkinSignal => _checkin;

  ReadonlySignal<List<ContagemNotaFiscal>> get notasSignal => _notas;

  /// Nota e item abertos. São **campos simples, não signals**: quem manda neles
  /// é a rota, e a tela já reconstrói ao navegar.
  ///
  /// Foram signals e isso quebrava o app: as telas sincronizam o índice da URL
  /// no `initState`, que roda **durante o build**, e escrever signal ali faz um
  /// `SignalBuilder` já montado pedir rebuild no meio do build
  /// (`SignalEffectException`). Índice de navegação não é estado reativo.
  int _notaIndex = 0;
  int _itemIndex = 0;

  int get notaIndex => _notaIndex;
  int get itemIndex => _itemIndex;

  /// Aviso da última contagem — some ao sair da tela ou abrir outro item.
  ReadonlySignal<ContagemMensagem?> get mensagemSignal => _mensagem;

  ReadonlySignal<bool> get finalizadoSignal => _finalizado;

  /// `Status` do `INCContagemACegaHeader` lido na abertura do check-in.
  ///
  /// `'C'`/`'D'` significam que **o SAP já fechou esta conferência** — outro
  /// coletor finalizou, ou esta sessão finalizou e o coletor caiu antes de a
  /// tela trocar. Ver [checkinJaFinalizadoSignal].
  ReadonlySignal<ContagemHeaderStatus> get statusContagemSignal =>
      _statusContagem;

  /// `false` liga o **modo supervisor**, que revela a quantidade da NF na tela
  /// de contagem. Na operação normal fica ligado — é o que torna a contagem
  /// cega.
  ReadonlySignal<bool> get contagemCegaSignal => _contagemCega;

  /// Falha da última leitura. Alimenta o toast e o bloco de erro da tela de
  /// leitura — quem exibe é a tela, não o controller (ver [carregarCheckin]).
  ReadonlySignal<AppFailure?> get erroSignal => _erro;

  /// Motorista, placa e CPF do check-in aberto. A tela precisa disso mesmo
  /// quando o status bloqueia a contagem, para o conferente explicar ao
  /// motorista o que está acontecendo.
  ReadonlySignal<ContagemCheckin?> get checkinInfoSignal => _checkinInfo;

  /// Empresa do usuário sem SAP mapeado — bloqueia a tela inteira e é diferente
  /// de uma falha de leitura, que é recuperável.

  /// Abertura de nota em curso: a lista de NF-es fica bloqueada até o cabeçalho
  /// existir no SAP e o histórico chegar.
  ReadonlySignal<bool> get abrindoNotaSignal => _abrindoNota;

  /// Gravação de contagem em curso — o botão "Confirmar" fica em loading.
  ReadonlySignal<bool> get gravandoSignal => _gravando;

  /// Última falha de **escrita/abertura** no SAP.
  ///
  /// Signal separado de [erroSignal] de propósito: aquele é da leitura do
  /// check-in e alimenta o bloco de erro da tela de leitura. Compartilhar os
  /// dois faria a tela de scan exibir um erro de gravação antigo ao voltar.
  ReadonlySignal<AppFailure?> get erroSapSignal => _erroSap;

  /// Nota aberta. Getter e não `Computed` porque o índice deixou de ser signal
  /// — o `Computed` cachearia e nunca reagiria à troca de nota.
  ///
  /// Ler `_notas.value` aqui dentro continua assinando o signal quando o getter
  /// é chamado de dentro de um `SignalBuilder`, então a tela segue reativa às
  /// contagens gravadas.
  ContagemNotaFiscal? get notaAtual {
    final notas = _notas.value;
    if (_notaIndex < 0 || _notaIndex >= notas.length) return null;
    return notas[_notaIndex];
  }

  /// Item aberto dentro da [notaAtual].
  ContagemItem? get itemAtual {
    final nota = notaAtual;
    if (nota == null || _itemIndex < 0 || _itemIndex >= nota.itens.length) {
      return null;
    }
    return nota.itens[_itemIndex];
  }

  late final Computed<bool> _todasResolvidas = computed(() {
    final notas = _notas.value;
    return notas.isNotEmpty &&
        notas.every((n) => n.status != ContagemNfStatus.pendente);
  });

  late final Computed<String> _resumoFinal = computed(() {
    final notas = _notas.value;
    final recebidas =
        notas.where((n) => n.status == ContagemNfStatus.ok).length;
    final devolvidas =
        notas.where((n) => n.status == ContagemNfStatus.devolver).length;
    return '$recebidas NF(s) recebida(s) · '
        '$devolvidas NF(s) para devolução ao fornecedor';
  });

  /// Nenhuma nota pendente — libera o botão de finalizar o check-in.
  ReadonlySignal<bool> get todasResolvidasSignal => _todasResolvidas;

  /// O SAP já finalizou este check-in (`Status` do cabeçalho em `'C'`/`'D'`).
  ///
  /// Trava o botão de finalizar: repetir o fecho mandaria um segundo
  /// `IN100FinalizaCC` para o mesmo caminhão, e o MERGE ainda poderia
  /// **rebaixar** o desfecho — um check-in fechado em `'D'` por outro coletor
  /// voltaria a `'C'` se esta sessão não enxergasse a nota condenada.
  ///
  /// Vale só para quem **não** finalizou aqui: depois de [finalizar] com
  /// sucesso a tela troca para o painel de finalizado, que não tem botão.
  late final Computed<bool> _checkinJaFinalizado =
      computed(() => _statusContagem.value.finalizado);

  ReadonlySignal<bool> get checkinJaFinalizadoSignal => _checkinJaFinalizado;

  /// Frase do bloqueio, vazia quando não há bloqueio.
  String get situacaoContagem => _statusContagem.peek().situacao;

  /// "1 NF(s) recebida(s) · 1 NF(s) para devolução ao fornecedor"
  ReadonlySignal<String> get resumoFinalSignal => _resumoFinal;

  /// Tentativa em curso do item aberto, no formato "2/3".
  String get tentativaLabel {
    final item = itemAtual;
    final atual = item == null ? 1 : (item.tentativas + 1);
    return '${atual.clamp(1, maxTentativas)}/$maxTentativas';
  }

  /// Índice do próximo item a contar na nota aberta, ou `-1`.
  int get proximoItemPendente => notaAtual?.primeiroItemPendente ?? -1;

  /// A nota inteira já foi condenada: os itens que sobraram não devem ser
  /// contados, porque a carga volta completa para o fornecedor.
  bool get notaBloqueada => notaAtual?.status == ContagemNfStatus.devolver;

  /// Há item a contar e a nota ainda não foi condenada.
  bool get temItemPendente => !notaBloqueada && proximoItemPendente >= 0;

  /// Abre o check-in para conferência: lê a carga e marca a entrega como
  /// iniciada.
  ///
  /// Devolve `false` quando não há o que abrir, para a tela não navegar. **O
  /// motivo vai por [erroSignal]/[configErrorSignal], não por exceção** — quem
  /// mostra toast é a tela: este controller é app-scoped singleton e segurar um
  /// `BuildContext` aqui daria `!mounted` depois do primeiro `context.go`.
  Future<bool> carregarCheckin(String numero) async {
    if (_status.value == AppStatus.loading) return false;

    final backend = exigirBackend();
    if (backend == null) return false;

    final digitos = numero.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return false;
    // O SAP usa NUMC(10): o conferente digita "3" e a key vai "0000000003".
    // Sem o padding a leitura devolve 404.
    final chave = digitos.padLeft(10, '0');

    batch(() {
      _status.value = AppStatus.loading;
      _erro.value = null;
      limparConfigError();
    });

    final result =
        await _repository.carregarCheckin(backend: backend, checkin: chave);

    final info = result.getOrNull();
    if (info == null) {
      _falhar(result.exceptionOrNull()!);
      return false;
    }

    _checkinInfo.value = info;

    if (!info.status.permiteContagem) {
      _falhar(ValidationFailure(
        'Não é possível iniciar a contagem. ${info.status.situacao}',
      ));
      return false;
    }
    if (info.notas.isEmpty) {
      _falhar(const ValidationFailure(
        'Este check-in não tem notas fiscais para conferir.',
      ));
      return false;
    }

    final entrega = await _repository.iniciarEntrega(
      backend: backend,
      checkin: chave,
      // Já está em 'E': é uma contagem retomada, não uma nova.
      jaIniciado: info.status == CheckinStatus.emEntrega,
    );
    final falhaEntrega = entrega.exceptionOrNull();
    if (falhaEntrega != null) {
      _falhar(falhaEntrega);
      return false;
    }

    _checkinKey = chave;
    batch(() {
      // Dígitos, não a chave: o app bar mostra "Check-in 3", e
      // "Check-in 0000000003" é ruído para quem está na doca.
      _checkin.value = digitos;
      _notas.value = info.notas;
      _notaIndex = 0;
      _itemIndex = 0;
      _mensagem.value = null;
      _finalizado.value = false;
      _statusContagem.value = info.statusContagem;
      _status.value = AppStatus.success;
    });
    return true;
  }

  void _falhar(AppFailure failure) {
    batch(() {
      _erro.value = failure;
      _status.value = AppStatus.failure;
    });
  }

  /// Preenche o campo com o código lido pelo scanner — o conteúdo do QR Code é
  /// o próprio número do check-in.
  void aplicarCodigoLido(String codigo) {
    checkinController.text = codigo.trim();
  }

  /// Alinha os índices com o que veio na URL.
  ///
  /// Chamada do `initState` das telas, ou seja, **durante o build**. Por isso só
  /// mexe em campos simples: escrever signal aqui faria um `SignalBuilder` já
  /// montado pedir rebuild no meio do build e o app quebraria com
  /// `SignalEffectException`. Quem limpa mensagem e campos é [selecionarNota] /
  /// [abrirItem], chamados dos handlers de toque.
  void sincronizarRota({int? nota, int? item}) {
    if (nota != null) _notaIndex = nota;
    if (item != null) _itemIndex = item;
  }

  void selecionarNota(int index) {
    batch(() {
      _notaIndex = index;
      _mensagem.value = null;
      _erroSap.value = null;
    });
  }

  /// Abre uma NF-e para conferência: garante o cabeçalho da contagem no SAP e
  /// **reidrata** as tentativas já gravadas.
  ///
  /// Devolve `false` quando não dá para entrar — **o motivo vai por
  /// [erroSapSignal]/[configErrorSignal], não por exceção**: este controller é
  /// app-scoped singleton e segurar um `BuildContext` aqui daria `!mounted`
  /// depois do primeiro `context.go`. Quem mostra toast é a tela.
  ///
  /// Cabeçalho **antes** do histórico, sem `Future.wait`: falha no cabeçalho
  /// impede a entrada, e um `wait` já teria disparado a leitura. Se o serviço
  /// tiver integridade referencial Header→Log, o momento de descobrir é aqui e
  /// não no meio da contagem.
  Future<bool> abrirNota(int index) async {
    if (_abrindoNota.value) return false;

    final notas = _notas.value;
    if (index < 0 || index >= notas.length) return false;
    final nota = notas[index];

    final backend = exigirBackend();
    if (backend == null) return false;

    batch(() {
      _abrindoNota.value = true;
      _erroSap.value = null;
      limparConfigError();
    });

    try {
      final cabecalho = await _repository.garantirCabecalhoContagem(
        backend: backend,
        checkin: _checkinKey,
      );
      final falhaCabecalho = cabecalho.exceptionOrNull();
      if (falhaCabecalho != null) {
        _erroSap.value = falhaCabecalho;
        return false;
      }

      final historico = await _repository.lerContagens(
        backend: backend,
        chave: nota.chave,
        accesskey: nota.chaveAcesso,
      );
      final registros = historico.getOrNull();
      if (registros == null) {
        _erroSap.value = historico.exceptionOrNull()!;
        return false;
      }

      final atualizadas = [...notas];
      atualizadas[index] = rehidratarNota(nota: nota, registros: registros);

      batch(() {
        _notas.value = atualizadas;
        _notaIndex = index;
        _itemIndex = 0;
        _mensagem.value = null;
      });
      return true;
    } finally {
      // `finally` e não no fim do caminho feliz: o loading precisa sumir também
      // nos `return false` acima, senão a lista de notas trava para sempre.
      _abrindoNota.value = false;
    }
  }

  /// Abre a contagem de um item com o **lote já preenchido** a partir da NF-e e
  /// a **quantidade zerada**.
  ///
  /// A assimetria é de propósito: o que se conta às cegas é a *quantidade*, e
  /// reaproveitar o número digitado antes anularia a recontagem. O lote não —
  /// ele identifica a linha, o conferente só confirma ou corrige contra a
  /// etiqueta do volume, e redigitá-lo a cada item custa tempo de doca.
  ///
  /// O preenchimento vem **depois** do `batch`: é [itemAtual] que dá o lote, e
  /// ele depende do `_itemIndex` recém-atribuído.
  void abrirItem(int index) {
    quantidadeController.clear();
    batch(() {
      _itemIndex = index;
      _mensagem.value = null;
      _erroSap.value = null;
    });
    final item = itemAtual;
    loteController.text = item == null ? '' : _loteDaNf(item);
  }

  void limparMensagem() => _mensagem.value = null;

  /// Mock do leitor de código de barras do lote.
  void aplicarLoteLido() {
    final item = itemAtual;
    if (item == null) return;
    loteController.text = _loteDaNf(item);
  }

  /// `S/LOTE` quando a linha da NF-e não tem lote: o campo é obrigatório em
  /// [confirmarContagem] e deixar vazio travaria a gravação de item sem lote.
  String _loteDaNf(ContagemItem item) =>
      item.loteNf.isEmpty ? 'S/LOTE' : item.loteNf;

  /// Grava a contagem do item aberto **no SAP** e devolve o desfecho para a
  /// tela decidir se volta para a lista de itens ou fica para a recontagem.
  ///
  /// A linha do log é escrita **antes** de o item mudar de estado: se o POST
  /// falhar, nada muda — a tentativa não é consumida, o item não é marcado e a
  /// tela permanece aberta com a faixa de erro. Uma contagem que não chegou ao
  /// SAP não aconteceu.
  Future<ContagemResultado> confirmarContagem() async {
    // Backstop de duplo toque (o leitor físico do coletor dispara `onSubmitted`
    // e é comum ele emitir duas vezes). Não mexe em `_mensagem`: a faixa atual
    // continua na tela.
    if (_gravando.value) return ContagemResultado.invalido;

    final nota = notaAtual;
    final item = itemAtual;
    if (nota == null || item == null) return ContagemResultado.invalido;

    final lote = loteController.text.trim();
    // Decimal, com vírgula ou ponto: a contagem é na unidade do pedido, e
    // material em KG/L/M tem fração. `int.tryParse` aqui rejeitava "2,5" como
    // "não informado" e arredondar mudaria a quantidade que o conferente viu.
    final quantidade = parseQuantidade(quantidadeController.text);
    if (lote.isEmpty || quantidade == null) {
      _mensagem.value = const ContagemMensagem(
        texto: 'Informe o lote e a quantidade contada.',
        tipo: ContagemMensagemTipo.reconte,
      );
      return ContagemResultado.invalido;
    }

    // Diagnóstico da doca: "digitei X e deu divergente" só se investiga vendo
    // o texto cru, o número que ele virou e o que a NF esperava — os três, na
    // unidade do pedido. Antes da rede, para aparecer mesmo quando o POST
    // falha.
    final confere = quantidadesConferem(quantidade, item.quantidadeNf);
    AppLogger.info(
      'Contagem cega: NF-e ${nota.numero} item ${item.itemXml} '
      'lote "${item.loteNf}" (lido "$lote") · '
      'digitado "${quantidadeController.text}" → '
      '${formatarQuantidade(quantidade)} ${item.unidade} · '
      'esperado ${item.quantidadeNfLabel} · '
      '${confere ? 'CONFERE' : 'DIVERGE'} '
      '(tentativa ${item.tentativas + 1}/$maxTentativas)',
    );

    final backend = exigirBackend();
    if (backend == null) return ContagemResultado.falhaGravacao;

    // Sem matrícula não há autor para o registro de auditoria. Bloquear antes
    // de qualquer rede: gravar com `Crenam` vazio seria pior que travar.
    final matricula = _backends.matricula;
    if (matricula == null || matricula.isEmpty) {
      return _falharGravacao(const ValidationFailure(
        'Seu usuário não tem matrícula vinculada. A contagem precisa de autor '
        'para ser gravada — procure o suporte do portal.',
      ));
    }

    batch(() {
      _gravando.value = true;
      _erroSap.value = null;
    });

    final AppFailure? falhaGravacao;
    try {
      final gravado = await _repository.registrarContagem(
        backend: backend,
        checkin: _checkinKey,
        chave: nota.chave,
        accesskey: nota.chaveAcesso,
        // Literal, zero-padded como o SAP devolveu — repadronizar aqui é como
        // se perde uma linha na releitura.
        item: item.itemXml,
        lote: item.loteNf,
        loteLido: lote,
        quantidade: quantidade,
        matricula: matricula,
      );
      falhaGravacao = gravado.exceptionOrNull();
    } finally {
      _gravando.value = false;
    }
    if (falhaGravacao != null) return _falharGravacao(falhaGravacao);

    if (confere) {
      _atualizarItemAtual(item.copyWith(
        status: ContagemItemStatus.ok,
        quantidadeContada: quantidade,
        loteLido: lote,
      ));
      _mensagem.value = ContagemMensagem(
        texto:
            'Item ${item.itemXmlLabel} conferido: ${item.descricaoPrincipal}',
        tipo: ContagemMensagemTipo.sucesso,
      );
      return ContagemResultado.conferido;
    }

    final tentativas = item.tentativas + 1;
    if (tentativas >= maxTentativas) {
      _atualizarItemAtual(item.copyWith(
        status: ContagemItemStatus.divergente,
        tentativas: tentativas,
        quantidadeContada: quantidade,
        loteLido: lote,
      ));
      _mensagem.value = ContagemMensagem(
        texto: 'Divergência confirmada — NF-e ${nota.numero} marcada para '
            'devolução.',
        tipo: ContagemMensagemTipo.devolucao,
      );
      return ContagemResultado.divergenciaConfirmada;
    }

    // Ainda há tentativa: o item continua pendente e a tela permanece aberta,
    // com a quantidade zerada para a recontagem. O lote fica — o material é o
    // mesmo.
    _atualizarItemAtual(item.copyWith(tentativas: tentativas));
    quantidadeController.clear();
    quantidadeFocus.requestFocus();
    _mensagem.value = ContagemMensagem(
      texto: 'Quantidade divergente. Reconte o material — tentativa '
          '${tentativas + 1} de $maxTentativas.',
      tipo: ContagemMensagemTipo.reconte,
    );
    return ContagemResultado.reconte;
  }

  /// A gravação não aconteceu: registra a falha e devolve o desfecho, **sem
  /// tocar no item**. A tentativa não é consumida e o campo de quantidade fica
  /// como está, para o conferente só tocar "Confirmar" de novo.
  ContagemResultado _falharGravacao(AppFailure falha) {
    batch(() {
      _erroSap.value = falha;
      _mensagem.value = ContagemMensagem(
        texto: 'A contagem NÃO foi gravada no SAP. ${falha.message} '
            'Tente confirmar novamente.',
        tipo: ContagemMensagemTipo.erro,
      );
    });
    return ContagemResultado.falhaGravacao;
  }

  /// Fecha o check-in **no SAP** e só então marca a sessão como finalizada.
  ///
  /// Devolve `false` quando o MERGE falha — o motivo vai por [erroSapSignal],
  /// como no resto do fluxo, e a tela continua no resumo com o botão servindo
  /// de retry. Marcar `_finalizado` antes da resposta trocaria a tela pelo
  /// painel de "finalizado" com o SAP ainda em `'E'`, e aí não há mais caminho
  /// de volta: o painel não tem botão de voltar, só "Novo Check-in".
  ///
  /// `'D'` quando **alguma** nota foi condenada à devolução, `'C'` quando todas
  /// passaram. Uma nota basta: o cabeçalho é um por check-in e o desfecho do
  /// caminhão é o pior desfecho entre as notas.
  Future<bool> finalizar() async {
    if (_gravando.value) return false;
    if (!_todasResolvidas.value) return false;
    // Cabeçalho já em 'C'/'D': o SAP fechou esta conferência. A tela não
    // oferece o botão nesse caso, mas a guarda fica — é a mesma razão do
    // backstop de duplo toque, e aqui o efeito colateral é um segundo
    // processamento no SAP.
    if (_checkinJaFinalizado.value) return false;

    final backend = exigirBackend();
    if (backend == null) return false;

    batch(() {
      _gravando.value = true;
      _erroSap.value = null;
    });

    final AppResult<bool> gravado;
    try {
      gravado = await _repository.finalizarContagem(
        backend: backend,
        checkin: _checkinKey,
        comDevolucao: _temDevolucao,
      );
    } finally {
      _gravando.value = false;
    }

    final falha = gravado.exceptionOrNull();
    if (falha != null) {
      _erroSap.value = falha;
      return false;
    }

    _finalizado.value = true;
    return true;
  }

  /// Alguma NF-e condenada à devolução — decide entre `'D'` e `'C'`.
  bool get _temDevolucao =>
      _notas.value.any((n) => n.status == ContagemNfStatus.devolver);

  /// Volta ao início para o próximo check-in, zerando a conferência.
  void reiniciar() {
    checkinController.clear();
    loteController.clear();
    quantidadeController.clear();
    _checkinKey = '';
    batch(() {
      _status.value = AppStatus.initial;
      _checkin.value = null;
      _notas.value = const [];
      _notaIndex = 0;
      _itemIndex = 0;
      _mensagem.value = null;
      _finalizado.value = false;
      _statusContagem.value = ContagemHeaderStatus.inexistente;
      _erro.value = null;
      _checkinInfo.value = null;
      limparConfigError();
      _abrindoNota.value = false;
      _gravando.value = false;
      _erroSap.value = null;
    });
  }

  /// A conferência inteira, achatada em uma linha por `(item, lote)`.
  ///
  /// É o **estado final** da sessão, não o que se grava: a gravação é por
  /// tentativa e acontece em [confirmarContagem]. Serve ao resumo do check-in e
  /// ao log de auditoria local.
  List<ContagemLancamento> get lancamentos {
    final saida = <ContagemLancamento>[];
    for (final nota in _notas.value) {
      for (final item in nota.itens) {
        saida.add(ContagemLancamento(
          checkin: _checkinKey,
          chave: nota.chave,
          accesskey: nota.chaveAcesso,
          item: item.itemXml,
          lote: item.loteNf,
          quantidadeContada: item.quantidadeContada,
          loteLido: item.loteLido,
          tentativas: item.tentativas,
          status: item.status,
        ));
      }
    }
    return saida;
  }

  /// Liga/desliga o modo supervisor (ver [contagemCegaSignal]).
  set contagemCega(bool cega) => _contagemCega.value = cega;

  void _atualizarItemAtual(ContagemItem atualizado) {
    final notas = [..._notas.value];
    final notaIndex = _notaIndex;
    final itemIndex = _itemIndex;
    if (notaIndex < 0 || notaIndex >= notas.length) return;

    final itens = [...notas[notaIndex].itens];
    if (itemIndex < 0 || itemIndex >= itens.length) return;

    itens[itemIndex] = atualizado;
    notas[notaIndex] = notas[notaIndex].copyWith(itens: itens);
    _notas.value = notas;
  }

  void dispose() {
    checkinController.dispose();
    checkinFocus.dispose();
    loteController.dispose();
    quantidadeController.dispose();
    quantidadeFocus.dispose();
    _status.dispose();
    _checkin.dispose();
    _notas.dispose();
    _mensagem.dispose();
    _finalizado.dispose();
    _statusContagem.dispose();
    _contagemCega.dispose();
    _erro.dispose();
    _checkinInfo.dispose();
    _abrindoNota.dispose();
    _gravando.dispose();
    _erroSap.dispose();
    _checkinJaFinalizado.dispose();
    _todasResolvidas.dispose();
    _resumoFinal.dispose();
    descartarSelecaoEmpresa();
  }
}
