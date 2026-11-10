import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/data/repositories/timesheet_repository.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/catraca_acesso.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/ponto_dia.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/shared/enums/app_status.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Visões da tela de Timesheet.
enum TimesheetView { semanal, diaria }

/// Controller da feature Timesheet (signals).
///
/// Carrega o histórico de catraca do funcionário logado (matrícula vem do
/// vínculo em [AccessController.employeeLink]), sempre no recorte da semana
/// selecionada (dom 00:00:00 → sáb 23:59:59), e mantém o estado de navegação
/// entre as visões semanal e diária. Trocar de semana dispara nova busca.
class TimesheetController {
  TimesheetController({
    required TimesheetRepository repository,
    required AccessController accessController,
  })  : _repository = repository,
        _accessController = accessController;

  final TimesheetRepository _repository;
  final AccessController _accessController;

  late final Signal<AppStatus> _status = signal(AppStatus.initial);
  late final Signal<List<CatracaAcesso>> _acessos = signal(const []);
  late final Signal<List<PontoDia>> _pontos = signal(const []);
  late final Signal<List<Apontamento>> _apontamentos = signal(const []);
  late final Signal<AppFailure?> _error = signal(null);

  /// Erro não-bloqueante: uma das duas fontes (catraca / apontamentos) falhou,
  /// mas a outra carregou — a tela mostra os dados + um aviso, em vez de trocar
  /// tudo por uma tela de erro.
  late final Signal<AppFailure?> _partialError = signal(null);

  /// Chamados dos apontamentos carregados (`ticketsId → chamado`).
  /// Enriquecimento best-effort: falha aqui só deixa os cards sem título.
  ///
  /// Guarda o [Chamado] inteiro, não só o título, porque o UUID do portal vem
  /// de graça na mesma resposta e é o que o POST de apontamento exige — é ele
  /// que permite duplicar um apontamento sem uma busca extra.
  late final Signal<Map<int, Chamado>> _chamadosPorOrigem = signal(const {});

  /// Só os títulos (`ticketsId → titulo`), que é o que a UI consome.
  late final Computed<Map<int, String>> _titulosChamados = computed(
    () => _chamadosPorOrigem.value
        .map((origemId, chamado) => MapEntry(origemId, chamado.titulo)),
  );

  late final Signal<TimesheetView> _view = signal(TimesheetView.semanal);
  late final Signal<DateTime> _selectedDate = signal(dateOnly(DateTime.now()));

  /// Domingo da semana selecionada.
  late final Computed<DateTime> _weekStart =
      computed(() => sundayOfWeek(_selectedDate.value));

  /// Os 7 dias (dom→sáb) da semana selecionada.
  late final Computed<List<DateTime>> _weekDays = computed(
    () => List.generate(7, (i) => addDays(_weekStart.value, i)),
  );

  /// Acessos agrupados por dia (chave = data sem hora), cada dia em ordem
  /// crescente de horário (o backend devolve desc).
  late final Computed<Map<DateTime, List<CatracaAcesso>>> _acessosPorDia =
      computed(() {
    final byDay = <DateTime, List<CatracaAcesso>>{};
    for (final acesso in _acessos.value) {
      byDay.putIfAbsent(dateOnly(acesso.data), () => []).add(acesso);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.data.compareTo(b.data));
    }
    return byDay;
  });

  /// Acessos do dia selecionado, em ordem crescente.
  late final Computed<List<CatracaAcesso>> _acessosDoDia = computed(
    () => _acessosPorDia.value[_selectedDate.value] ?? const [],
  );

  /// Ponto diário por dia (chave = data sem hora) — no máximo um por dia,
  /// já agregado pelo backend (primeira/última marcação).
  late final Computed<Map<DateTime, PontoDia>> _pontosPorDia = computed(() {
    final byDay = <DateTime, PontoDia>{};
    for (final ponto in _pontos.value) {
      byDay[dateOnly(ponto.data)] = ponto;
    }
    return byDay;
  });

  /// Horas trabalhadas por dia (pareamento sequencial entrada→saída).
  late final Computed<Map<DateTime, Duration>> _totaisPorDia = computed(
    () => _acessosPorDia.value.map(
      (day, acessos) => MapEntry(day, _pairEntradaSaida(acessos)),
    ),
  );

  /// Apontamentos agrupados por dia (chave = data sem hora), cada dia em ordem
  /// crescente de horário. Apontamentos sem data são descartados.
  late final Computed<Map<DateTime, List<Apontamento>>> _apontamentosPorDia =
      computed(() {
    final byDay = <DateTime, List<Apontamento>>{};
    for (final ap in _apontamentos.value) {
      final data = ap.data;
      if (data == null) continue;
      byDay.putIfAbsent(dateOnly(data), () => []).add(ap);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.data!.compareTo(b.data!));
    }
    return byDay;
  });

  /// Apontamentos do dia selecionado, em ordem crescente.
  late final Computed<List<Apontamento>> _apontamentosDoDia = computed(
    () => _apontamentosPorDia.value[_selectedDate.value] ?? const [],
  );

  /// Tempo apontado por dia (soma de `actiontime`).
  late final Computed<Map<DateTime, Duration>> _apontadoPorDia = computed(
    () => _apontamentosPorDia.value.map(
      (day, aps) => MapEntry(
        day,
        aps.fold(Duration.zero, (total, ap) => total + ap.duration),
      ),
    ),
  );

  ReadonlySignal<AppStatus> get statusSignal => _status;
  ReadonlySignal<List<CatracaAcesso>> get acessosSignal => _acessos;
  ReadonlySignal<List<PontoDia>> get pontosSignal => _pontos;
  ReadonlySignal<List<Apontamento>> get apontamentosSignal => _apontamentos;
  ReadonlySignal<AppFailure?> get errorSignal => _error;
  ReadonlySignal<AppFailure?> get partialErrorSignal => _partialError;
  ReadonlySignal<Map<int, String>> get titulosChamadosSignal =>
      _titulosChamados;
  ReadonlySignal<Map<int, Chamado>> get chamadosPorOrigemSignal =>
      _chamadosPorOrigem;
  ReadonlySignal<TimesheetView> get viewSignal => _view;
  ReadonlySignal<DateTime> get selectedDateSignal => _selectedDate;
  ReadonlySignal<DateTime> get weekStartSignal => _weekStart;
  ReadonlySignal<List<DateTime>> get weekDaysSignal => _weekDays;
  ReadonlySignal<Map<DateTime, List<CatracaAcesso>>> get acessosPorDiaSignal =>
      _acessosPorDia;
  ReadonlySignal<List<CatracaAcesso>> get acessosDoDiaSignal => _acessosDoDia;
  ReadonlySignal<Map<DateTime, PontoDia>> get pontosPorDiaSignal =>
      _pontosPorDia;
  ReadonlySignal<Map<DateTime, Duration>> get totaisPorDiaSignal =>
      _totaisPorDia;
  ReadonlySignal<Map<DateTime, List<Apontamento>>>
      get apontamentosPorDiaSignal => _apontamentosPorDia;
  ReadonlySignal<List<Apontamento>> get apontamentosDoDiaSignal =>
      _apontamentosDoDia;
  ReadonlySignal<Map<DateTime, Duration>> get apontadoPorDiaSignal =>
      _apontadoPorDia;

  /// Matrícula do funcionário logado (nula quando o vínculo não existe).
  String? get matricula =>
      _accessController.employeeLink?.matricula?.toString();

  /// E-mail do usuário logado (usado para resolver o id no GLPI).
  String? get _email => _accessController.accessSignal.value?.user.email;

  /// Semana já carregada (domingo) e token para descartar resposta obsoleta
  /// quando o usuário navega mais rápido que a rede responde.
  DateTime? _loadedWeekStart;
  int _requestId = 0;

  /// Id do usuário no GLPI (resolvido do e-mail via `findByEmail`), cacheado
  /// entre semanas. O cache é vinculado ao e-mail que o produziu
  /// ([_resolvedEmail]): se o usuário logado muda (logout→login na mesma
  /// instância do app, sem reload), o id é reconsultado — evita vazar os
  /// apontamentos do usuário anterior.
  int? _usuarioId;
  bool _usuarioIdResolved = false;
  String? _resolvedEmail;

  int? get usuarioId => _usuarioId;

  /// (Re)carrega acessos (catraca), pontos (relógio de ponto) e apontamentos
  /// (tarefas) da semana.
  ///
  /// As fontes são independentes: catraca e ponto dependem da matrícula,
  /// apontamentos do id do usuário (e-mail→GLPI). Se uma falha e outra tem
  /// dados, a tela mostra o que carregou + um aviso ([_partialError]); só vira
  /// tela de erro quando não há nada a exibir.
  Future<void> load() async {
    final weekStart = _weekStart.value;
    _loadedWeekStart = weekStart;
    final requestId = ++_requestId;
    final dataIni = weekStart;
    final dataFim = endOfDay(addDays(weekStart, 6));

    _status.value = AppStatus.loading;
    _error.value = null;
    _partialError.value = null;

    // Passo 1: resolver o id do usuário no GLPI a partir do e-mail. Um 404
    // (sem conta helpdesk) não é erro; falha real vira erro dos apontamentos.
    final usuarioIdFailure = await _ensureUsuarioId();
    if (requestId != _requestId) return;

    final matricula = this.matricula;
    final usuarioId = _usuarioId;

    // Passo 2: acessos por matrícula (catraca).
    AppFailure? acessosFailure;
    if (matricula != null) {
      final result = await _repository.fetchAcessos(
          matricula: matricula, dataIni: dataIni, dataFim: dataFim);
      if (requestId != _requestId) return;
      result.onSuccess((data) => _acessos.value = data).onFailure((f) {
        acessosFailure = f;
        _acessos.value = const []; // não deixa dado obsoleto na tela
      });
    } else {
      _acessos.value = const [];
    }

    // Passo 2b: ponto diário por matrícula (relógio de ponto).
    AppFailure? pontosFailure;
    if (matricula != null) {
      final result = await _repository.fetchPontos(
          matricula: matricula, dataIni: dataIni, dataFim: dataFim);
      if (requestId != _requestId) return;
      result.onSuccess((data) => _pontos.value = data).onFailure((f) {
        pontosFailure = f;
        _pontos.value = const [];
      });
    } else {
      _pontos.value = const [];
    }

    // Passo 3: apontamentos por id do usuário (tarefas de chamado).
    AppFailure? apontamentosFailure = usuarioIdFailure;
    if (usuarioId != null) {
      final result = await _repository.fetchApontamentos(
          usuarioId: usuarioId, dataIni: dataIni, dataFim: dataFim);
      if (requestId != _requestId) return;
      result.onSuccess((data) => _apontamentos.value = data).onFailure((f) {
        apontamentosFailure = f;
        _apontamentos.value = const [];
      });
    } else {
      _apontamentos.value = const [];
    }

    // Passo 4: chamados dos apontamentos (best-effort — falha só deixa os
    // cards sem título e desabilita o duplicar, não vira erro na tela).
    final chamadoIds = _apontamentos.value
        .map((ap) => ap.chamadoId)
        .whereType<int>()
        .toSet();
    if (chamadoIds.isEmpty) {
      _chamadosPorOrigem.value = const {};
    } else {
      final chamadosResult =
          await _repository.fetchChamadosPorOrigem(origemIds: chamadoIds);
      if (requestId != _requestId) return;
      chamadosResult.onSuccess((chamados) {
        _chamadosPorOrigem.value = chamados;
      }).onFailure((f) {
        _chamadosPorOrigem.value = const {};
        AppLogger.warning('Chamados dos apontamentos falharam: ${f.message}');
      });
    }

    final anyData = _acessos.value.isNotEmpty ||
        _pontos.value.isNotEmpty ||
        _apontamentos.value.isNotEmpty;
    final anyFailure = acessosFailure ?? pontosFailure ?? apontamentosFailure;

    if (anyFailure != null && !anyData) {
      // Nada carregou e houve erro → tela de erro.
      _error.value = anyFailure;
      _status.value = AppStatus.failure;
      AppLogger.warning('TimesheetController.load failed: ${anyFailure.message}');
    } else {
      // Há dados (ou nada a buscar). Falha parcial vira aviso não-bloqueante.
      _partialError.value = anyFailure;
      _status.value = AppStatus.success;
      if (anyFailure != null) {
        AppLogger.warning(
            'TimesheetController.load partial failure: ${anyFailure.message}');
      }
    }
  }

  /// Resolve o id do usuário no GLPI a partir do e-mail logado. Retorna um
  /// [AppFailure] apenas para falhas reais (rede/servidor) — um 404 (sem conta
  /// helpdesk) resolve como `null` sem erro. Recacheado por e-mail; falha real
  /// não marca como resolvido (retenta no próximo [load]).
  Future<AppFailure?> _ensureUsuarioId() async {
    final email = _email;
    if (email == null || email.isEmpty) {
      _usuarioId = null;
      _resolvedEmail = null;
      _usuarioIdResolved = false;
      return null;
    }
    if (_usuarioIdResolved && _resolvedEmail == email) return null;

    // Cache é de outro e-mail (ou ainda não resolvido): invalida ANTES de
    // reconsultar. Assim, se a busca falhar de forma transitória, o id do
    // usuário anterior não permanece ativo (vazaria os apontamentos dele).
    _usuarioId = null;
    _usuarioIdResolved = false;
    _resolvedEmail = null;

    final result = await _repository.fetchUsuarioId(email: email);
    // O usuário logado mudou durante a busca (ou uma resolução concorrente já
    // corre para o novo e-mail): descarta este resultado sem escrever no cache,
    // para não ressuscitar o id de um usuário que não é mais o atual.
    if (_email != email) return null;
    return result.fold(
      (id) {
        _usuarioId = id;
        _resolvedEmail = email;
        _usuarioIdResolved = true;
        return null;
      },
      (failure) {
        if (failure is ApiFailure && failure.isNotFound) {
          // Sem conta helpdesk para este e-mail: resposta definitiva.
          _usuarioId = null;
          _resolvedEmail = email;
          _usuarioIdResolved = true;
          return null;
        }
        // Falha transitória: não cacheia, propaga para o aviso/erro.
        return failure;
      },
    );
  }

  // ── Ações sobre um apontamento ─────────────────────────────────────────────

  /// Chamado de um apontamento, a partir do `ticketsId` do GLPI. Leitura do
  /// mapa já carregado pelo [load] — sem rede.
  ///
  /// Devolve `null` quando o chamado não foi resolvido (passo 4 falhou, ou o
  /// chamado não existe mais no portal) e também quando veio sem UUID: sem ele
  /// não há como criar um apontamento novo, então duplicar não é possível.
  Chamado? chamadoDe(int? origemId) {
    if (origemId == null) return null;
    final chamado = _chamadosPorOrigem.value[origemId];
    if (chamado == null || chamado.id.isEmpty) return null;
    return chamado;
  }

  /// Exclui o apontamento [id]. Retorna `null` no sucesso ou a mensagem de
  /// erro — mesmo contrato do `ApontamentoController.excluir`, que é
  /// screen-scoped e precisaria ser criado e disposto só para isso.
  ///
  /// Não recarrega: quem chama decide (mostra o toast e chama [load]).
  Future<String?> excluirApontamento({required int id}) async {
    final result = await _repository.excluirApontamento(id: id);
    return result.fold((_) => null, (failure) => failure.message);
  }

  // ── Navegação de período/visão ─────────────────────────────────────────────

  set view(TimesheetView view) => _view.value = view;

  /// Seleciona um dia (tocado na visão semanal) e abre a visão diária.
  void openDay(DateTime day) {
    batch(() {
      _selectedDate.value = dateOnly(day);
      _view.value = TimesheetView.diaria;
    });
    _ensureWeekLoaded();
  }

  void goToToday() {
    _selectedDate.value = dateOnly(DateTime.now());
    _ensureWeekLoaded();
  }

  /// Seleciona uma data vinda dos pickers (dia exato ou início da semana).
  void selectDate(DateTime day) {
    _selectedDate.value = dateOnly(day);
    _ensureWeekLoaded();
  }

  void previousWeek() => _shiftDays(-7);
  void nextWeek() => _shiftDays(7);
  void previousDay() => _shiftDays(-1);
  void nextDay() => _shiftDays(1);

  void _shiftDays(int days) {
    _selectedDate.value = addDays(_selectedDate.value, days);
    _ensureWeekLoaded();
  }

  /// Busca a semana selecionada se ela ainda não for a carregada.
  void _ensureWeekLoaded() {
    if (_loadedWeekStart != _weekStart.value) load();
  }

  /// Soma os intervalos entrada→saída de um dia ([acessos] em ordem
  /// crescente). Entrada sem saída correspondente fica de fora do total.
  static Duration _pairEntradaSaida(List<CatracaAcesso> acessos) {
    var total = Duration.zero;
    DateTime? entrada;
    for (final acesso in acessos) {
      if (acesso.tipoAcesso.isEntrada) {
        entrada ??= acesso.data;
      } else if (entrada != null) {
        total += acesso.data.difference(entrada);
        entrada = null;
      }
    }
    return total;
  }

  void dispose() {
    _status.dispose();
    _acessos.dispose();
    _pontos.dispose();
    _apontamentos.dispose();
    _error.dispose();
    _partialError.dispose();
    _chamadosPorOrigem.dispose();
    _titulosChamados.dispose();
    _view.dispose();
    _selectedDate.dispose();
    _weekStart.dispose();
    _weekDays.dispose();
    _acessosPorDia.dispose();
    _acessosDoDia.dispose();
    _pontosPorDia.dispose();
    _totaisPorDia.dispose();
    _apontamentosPorDia.dispose();
    _apontamentosDoDia.dispose();
    _apontadoPorDia.dispose();
  }
}
