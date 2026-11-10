import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/access/domain/enums/empresas.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/sap_backend.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/sap_backend_resolver.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Em qual SAP o controller de inbound está operando — e, para o consultor,
/// qual ele escolheu.
///
/// Existe porque a mesma lógica estava copiada em `ContagemCegaController` e
/// `CheckinCheckoutVeiculoController`: o signal da empresa, o `isConsultor`, a
/// guarda de cinco condições do seletor, a resolução do backend e o erro de
/// configuração. Duas cópias já saíam de sintonia (uma expunha a empresa como
/// signal, a outra como campo; uma resolvia o backend uma vez no `init`, a
/// outra a cada ação), e a chegada da **plataforma** — ECC × S/4HANA, que
/// decide qual serviço OData atende a empresa — daria uma terceira.
///
/// ## O contrato
///
/// Quem usa implementa quatro membros:
///
/// - [accessDaSelecao] — `null` em teste unitário, e aí o seletor fica
///   desligado (um fake sem `AccessController` não é consultor);
/// - [backendsDaSelecao] — resolve o SAP do **cadastro** do usuário;
/// - [operacaoEmAndamento] — trocar de empresa no meio de uma escrita
///   mandaria a continuação para o SAP errado;
/// - [aoTrocarEmpresa] — o que limpar quando a empresa muda (`reiniciar()`,
///   `novaOperacao()`); nunca é no-op, porque o estado carregado pertence ao
///   SAP anterior.
///
/// ## Consultor × colaborador
///
/// Colaborador opera **sempre** no SAP da própria empresa, resolvido pelo
/// `employeeLink`. Consultor (perfil funcional) escolhe, porque atende as três
/// empresas. É [podeSelecionarEmpresa] que separa os dois casos, e é por isso
/// que [backendSap] tem dois caminhos em vez de um valor guardado: para o
/// consultor, a verdade é o que está selecionado agora.
mixin SelecaoEmpresaSap {
  // ── Contrato ───────────────────────────────────────────────────────────────

  /// `null` quando o controller foi construído sem `AccessController` (teste).
  AccessController? get accessDaSelecao;

  SapBackendResolver get backendsDaSelecao;

  /// Há escrita ou leitura em curso? Bloqueia a troca de empresa.
  bool get operacaoEmAndamento;

  /// Como a operação se chama na mensagem de empresa sem SAP — "a contagem
  /// cega", "esta operação".
  String get descricaoOperacao;

  /// Limpa o estado que pertencia ao SAP anterior.
  void aoTrocarEmpresa();

  // ── Estado ─────────────────────────────────────────────────────────────────

  /// Escolha **explícita** do consultor. `null` significa "não escolheu", e não
  /// "nenhuma" — quem resolve o efetivo é [empresaSelecionada].
  final Signal<Empresa?> _empresa = signal(null);
  final Signal<String?> _configError = signal(null);

  /// Empresa em que o controller está operando: a escolhida, ou a do cadastro
  /// enquanto ninguém escolheu.
  ///
  /// O fallback é o que permite ao consultor abrir a tela já na própria empresa
  /// sem nenhum `init()` — e é por isso que ele mora no getter, e não numa
  /// atribuição de arranque: escrever signal fora de um handler é o que produz
  /// `SignalEffectException` quando a tela lê isto dentro do `build`.
  ///
  /// Empresa de cadastro sem SAP devolve `null` em vez dela mesma: oferecer no
  /// seletor uma empresa que não atende seria uma escolha que não funciona.
  Empresa? get empresaSelecionada {
    final escolhida = _empresa.value;
    if (escolhida != null) return escolhida;
    final cadastro = accessDaSelecao?.employeeLink?.empresa;
    return sapBackendForEmpresa(cadastro) == null ? null : cadastro;
  }

  /// Erro de **configuração** — empresa sem SAP, ou consultor que ainda não
  /// escolheu. Bloqueia a tela inteira, e é diferente de uma busca que falhou:
  /// aquela se tenta de novo, esta não.
  ReadonlySignal<String?> get configErrorSignal => _configError;

  /// O seletor de empresa aparece? Só para o perfil funcional.
  bool get podeSelecionarEmpresa => accessDaSelecao?.isConsultor ?? false;

  /// SAP Gateway que atende a operação agora.
  ///
  /// `null` bloqueia — nunca cair num backend padrão em silêncio, que liberaria
  /// carga no SAP errado.
  BackendService? get backendSap => podeSelecionarEmpresa
      ? sapBackendForEmpresa(empresaSelecionada)
      : backendsDaSelecao.resolve();

  /// ECC ou S/4HANA — qual contrato OData atende a empresa de agora.
  ///
  /// **Nenhuma ação precisa consultar isto**: quem despacha entre as duas
  /// implementações é o `ContagemCegaRepositoryRouter`, pelo backend que
  /// recebe. Fica exposto porque é aqui que alguém vai procurar a resposta
  /// para "em que SAP esta tela está falando", e para uma tela que precise
  /// esconder o que só existe num dos dois.
  SapPlataforma? get plataformaSap => backendSap?.sapPlataforma;

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  /// Opcional, para a tela já abrir bloqueada quando a empresa não tem SAP.
  ///
  /// Sem isto o bloqueio só aparece na primeira ação — o que faz o conferente
  /// digitar o check-in à toa. Quem tem um `init()` chama daqui; quem não tem
  /// (a contagem cega é app-scoped e não tem arranque de tela) fica com o
  /// bloqueio na primeira ação, que é o comportamento de hoje.
  void iniciarSelecaoEmpresa() {
    if (podeSelecionarEmpresa || backendSap != null) return;

    _configError.value = mensagemSemBackend;
    AppLogger.warning(
      '$runtimeType: empresa sem SAP mapeado '
      '(codigoEmpresa=${accessDaSelecao?.employeeLink?.codigoEmpresa}).',
    );
  }

  void selecionarEmpresa(Empresa? empresa) {
    if (!podeSelecionarEmpresa ||
        operacaoEmAndamento ||
        empresa == null ||
        sapBackendForEmpresa(empresa) == null ||
        empresa == empresaSelecionada) {
      return;
    }
    // Primeiro limpa, depois troca: o estado carregado é do SAP anterior, e
    // deixá-lo na tela por um frame já é tempo de alguém ler o dado errado.
    aoTrocarEmpresa();
    batch(() {
      _empresa.value = empresa;
      _configError.value = null;
    });
  }

  /// Chamado no `dispose()` do controller.
  void descartarSelecaoEmpresa() {
    _empresa.dispose();
    _configError.dispose();
  }

  // ── Uso pelas ações ────────────────────────────────────────────────────────

  /// Backend para esta ação, ou `null` com o motivo já publicado em
  /// [configErrorSignal].
  ///
  /// É o que as ações chamam no lugar de testar o backend e montar a mensagem
  /// cada uma do seu jeito — o que, nas duas cópias anteriores, produziu textos
  /// diferentes para a mesma situação.
  BackendService? exigirBackend() {
    final backend = backendSap;
    if (backend == null) {
      _configError.value = mensagemSemBackend;
    }
    return backend;
  }

  /// Limpa o erro de configuração ao começar uma ação que já tem backend.
  void limparConfigError() => _configError.value = null;

  String get mensagemSemBackend => podeSelecionarEmpresa
      ? 'Selecione a empresa para continuar.'
      : 'Sua empresa (${backendsDaSelecao.descricaoEmpresa}) não possui '
          'backend SAP configurado para $descricaoOperacao. Procure o suporte '
          'do portal.';
}
