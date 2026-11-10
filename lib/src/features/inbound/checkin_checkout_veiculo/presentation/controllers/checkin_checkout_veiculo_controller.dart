import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/checkin_motorista.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/repositories/inbound_repository.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/sap_backend_resolver.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/selecao_empresa_sap.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/global_navigator.dart';
import 'package:gjamobile/src/shared/enums/app_status.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Controller screen-scoped da tela de check-in/check-out de veículos da
/// portaria. Registrado como factory (`i.add<T>`) no DI — a tela resolve uma
/// instância nova e a descarta no próprio `dispose()`.
class CheckinCheckoutVeiculoController with SelecaoEmpresaSap {
  CheckinCheckoutVeiculoController({
    required InboundRepository repository,
    required SapBackendResolver backends,
    required AccessController access,
  })  : _repository = repository,
        _backends = backends,
        _access = access;

  final InboundRepository _repository;
  final SapBackendResolver _backends;
  final AccessController _access;

  /// Quanto tempo o painel de sucesso fica na tela antes de voltar sozinho para
  /// a Home. Tempo de sobra para o segurança conferir placa/motorista.
  static const int segundosParaHome = 10;

  /// Campo do número do check-in — digitado, lido pelo leitor físico do coletor
  /// ou preenchido pelo scanner de QR Code.
  final checkinController = TextEditingController();
  final checkinFocus = FocusNode();

  late CheckinCheckoutVeiculoMode _mode;

  // ── Contrato do SelecaoEmpresaSap ─────────────────────────────────────────
  // A seleção de empresa, a resolução do backend e o erro de configuração vêm
  // do mixin, compartilhado com o ContagemCegaController.

  @override
  AccessController? get accessDaSelecao => _access;

  @override
  SapBackendResolver get backendsDaSelecao => _backends;

  @override
  String get descricaoOperacao => 'esta operação';

  /// Trocar de empresa descarta a busca: o check-in na tela é do SAP anterior,
  /// e liberar o veículo depois disso seria liberar no sistema errado.
  @override
  void aoTrocarEmpresa() => novaOperacao();

  @override
  bool get operacaoEmAndamento =>
      _lookupStatus.value == AppStatus.loading ||
      _submitStatus.value == AppStatus.loading;

  CheckinCheckoutVeiculoMode get mode => _mode;

  /// Contagem regressiva do painel de sucesso.
  Timer? _redirectTimer;
  bool _disposed = false;

  late final Signal<AppStatus> _lookupStatus = signal(AppStatus.initial);
  late final Signal<CheckinMotorista?> _checkin = signal(null);
  late final Signal<AppFailure?> _lookupError = signal(null);
  late final Signal<AppStatus> _submitStatus = signal(AppStatus.initial);
  late final Signal<int> _countdown = signal(segundosParaHome);

  ReadonlySignal<AppStatus> get lookupStatusSignal => _lookupStatus;
  ReadonlySignal<CheckinMotorista?> get checkinSignal => _checkin;
  ReadonlySignal<AppFailure?> get lookupErrorSignal => _lookupError;
  ReadonlySignal<AppStatus> get submitStatusSignal => _submitStatus;

  /// Segundos restantes até o retorno automático para a Home.
  ReadonlySignal<int> get countdownSignal => _countdown;

  /// Chamado no `initState()` da tela — **não** no `onReady()`, que o
  /// `BaseState` dispara num post-frame callback, ou seja, depois do primeiro
  /// `build`.
  void init(CheckinCheckoutVeiculoMode mode) {
    _mode = mode;
    iniciarSelecaoEmpresa();
  }

  /// Consulta o check-in no SAP. Disparada pelo botão "Buscar", pelo Enter do
  /// coletor e pelo retorno do scanner de QR Code.
  Future<void> buscarCheckin({required BuildContext context}) async {
    final backend = backendSap;
    if (backend == null) {
      if (podeSelecionarEmpresa) {
        showToast(context, message: 'Selecione a empresa', status: 'warning');
      }
      return;
    }
    if (_lookupStatus.value == AppStatus.loading) return;

    // O SAP usa NUMC(10): o guarda digita "9" e a busca vai em "0000000009".
    final digitos = checkinController.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) {
      showToast(
        context,
        message: 'Informe ou escaneie o número do check-in',
        status: 'warning',
      );
      return;
    }
    final numero = digitos.padLeft(10, '0');

    // Uma nova busca cancela um retorno automático pendente — senão a tela
    // pularia para a Home no meio da próxima liberação.
    _redirectTimer?.cancel();

    _lookupStatus.value = AppStatus.loading;
    _lookupError.value = null;
    _checkin.value = null;
    _submitStatus.value = AppStatus.initial;

    final result =
        await _repository.getCheckin(backend: backend, checkin: numero);

    result.onSuccess((data) {
      _checkin.value = data;
      _lookupStatus.value = AppStatus.success;
    }).onFailure((failure) {
      _lookupError.value = failure;
      _lookupStatus.value = AppStatus.failure;
      if (context.mounted) {
        showToast(context, message: failure.message, status: 'error');
      }
      // Deixa o campo pronto para a próxima leitura sem nenhum toque na tela —
      // o segurança está num coletor com leitor físico.
      _prepararProximaLeitura();
    });
  }

  /// Libera a entrada/saída do veículo. Só é alcançável quando o status do
  /// check-in permite (o botão nem é renderizado no caso contrário) — a
  /// revalidação aqui é defesa em profundidade.
  Future<void> liberar({required BuildContext context}) async {
    final backend = backendSap;
    final checkin = _checkin.value;
    if (backend == null || checkin == null) return;
    if (_submitStatus.value == AppStatus.loading) return;

    if (!checkin.status.permitePara(_mode)) {
      showToast(
        context,
        message: 'Não é possível liberar a ${_mode.movimentoCurto}. '
            '${checkin.status.situacao}',
        status: 'warning',
      );
      return;
    }

    _submitStatus.value = AppStatus.loading;

    final result = _mode == CheckinCheckoutVeiculoMode.checkIn
        ? await _repository.checkIn(backend: backend, checkin: checkin.checkin)
        : await _repository.checkOut(
            backend: backend,
            checkin: checkin.checkin,
          );

    result.onSuccess((_) {
      // Não navega na hora: a tela troca para o painel de sucesso, que confirma
      // visualmente a liberação e só volta para a Home ao fim da contagem.
      _submitStatus.value = AppStatus.success;
      _iniciarRetornoAutomatico();
    }).onFailure((failure) {
      // Permanece na tela: o segurança pode tentar de novo sem refazer a busca.
      _submitStatus.value = AppStatus.failure;
      if (context.mounted) {
        showToast(context, message: failure.message, status: 'error');
      }
    });
  }

  /// Inicia a contagem regressiva do painel de sucesso. Ao chegar em zero volta
  /// para a Home; o segurança pode encurtar com [irParaHome] ou cancelar de vez
  /// com [novaOperacao].
  void _iniciarRetornoAutomatico() {
    _redirectTimer?.cancel();
    _countdown.value = segundosParaHome;
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final restante = _countdown.value - 1;
      _countdown.value = restante;
      if (restante > 0) return;

      timer.cancel();
      _voltarParaHome();
    });
  }

  /// Volta para a Home imediatamente, sem esperar a contagem.
  void irParaHome() {
    _redirectTimer?.cancel();
    _voltarParaHome();
  }

  /// Navega pelo contexto do navigator raiz, **não** por um `BuildContext`
  /// guardado: o contexto que dispara a liberação é o do card de dados, que sai
  /// da árvore assim que o painel de sucesso entra. Guardado, ele chegava
  /// defunto no fim da contagem e a navegação era descartada em silêncio.
  ///
  /// A tela pode ter saído da árvore no meio da contagem (back do sistema,
  /// deep-link); nesse caso o `dispose()` já cancelou o timer, e o guarda de
  /// [_disposed] cobre o tick que estivesse em voo.
  void _voltarParaHome() {
    if (_disposed) return;
    final context = rootContext;
    if (context == null) return;
    GoRouter.of(context).go(AppRoutes.home);
  }

  /// Reinicia a tela para a próxima leitura sem sair dela — cancela o retorno
  /// automático e limpa busca, resultado e campo.
  void novaOperacao() {
    _redirectTimer?.cancel();
    batch(() {
      _submitStatus.value = AppStatus.initial;
      _lookupStatus.value = AppStatus.initial;
      _checkin.value = null;
      _lookupError.value = null;
      _countdown.value = segundosParaHome;
    });
    _prepararProximaLeitura();
  }

  /// Preenche o campo com o código lido pelo scanner (o conteúdo do QR Code é o
  /// próprio número do check-in).
  void aplicarCodigoLido(String codigo) {
    checkinController.text = codigo.trim();
  }

  void _prepararProximaLeitura() {
    checkinController.clear();
    // O campo pode ainda não estar na árvore (ex.: saindo do painel de sucesso,
    // que o substitui) — pedir o foco depois do frame garante que o FocusNode
    // já foi reanexado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      checkinFocus.requestFocus();
    });
  }

  void dispose() {
    _disposed = true;
    _redirectTimer?.cancel();
    checkinController.dispose();
    checkinFocus.dispose();
    _lookupStatus.dispose();
    _checkin.dispose();
    _lookupError.dispose();
    _submitStatus.dispose();
    _countdown.dispose();
    descartarSelecaoEmpresa();
  }
}
