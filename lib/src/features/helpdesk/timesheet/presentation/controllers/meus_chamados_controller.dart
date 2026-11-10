import 'package:gjamobile/src/features/helpdesk/timesheet/data/repositories/meus_chamados_repository.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado_resumo.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/meus_chamados_filtro.dart';
import 'package:gjamobile/src/shared/enums/app_status.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Controller do painel "Meus chamados" do Timesheet (signals).
///
/// App-scoped, como o [TimesheetController]: a tela usa `BaseState`, que resolve
/// o controller pelo injector e nunca chama `dispose`.
///
/// A lista é **paginada e acumulativa** — cada página nova é anexada ao que já
/// está na tela, para o usuário não perder a posição ao rolar. Trocar qualquer
/// filtro reinicia da página zero.
class MeusChamadosController {
  MeusChamadosController({required MeusChamadosRepository repository})
      : _repository = repository;

  final MeusChamadosRepository _repository;

  /// Debounce **apenas** da busca por texto. Filtros de dropdown e paginação
  /// chamam direto: passar o "carregar mais" por aqui travaria a rolagem em
  /// 400 ms a cada página.
  final Debouncer _debouncer =
      Debouncer(delay: const Duration(milliseconds: 400));

  /// Meses de histórico que a lista abre carregando. O backend não impõe janela
  /// padrão; quem define o recorte inicial é a tela, e ele precisa ser largo o
  /// bastante para incluir os chamados antigos que continuam em aberto.
  static const _mesesIniciais = 12;

  static const _pageSize = 20;

  late final Signal<AppStatus> _status = signal(AppStatus.initial);
  late final Signal<List<ChamadoResumo>> _chamados = signal(const []);
  late final Signal<AppFailure?> _error = signal(null);
  late final Signal<MeusChamadosFiltro> _filtro = signal(_filtroInicial());
  late final Signal<int> _pagina = signal(0);
  late final Signal<int> _totalPaginas = signal(0);
  late final Signal<int> _totalElementos = signal(0);

  /// Carregando a PRÓXIMA página (a lista já tem itens). Distinto de
  /// `status.isLoading`, que troca o corpo inteiro do painel por um spinner.
  late final Signal<bool> _carregandoMais = signal(false);

  late final Computed<bool> _temMais =
      computed(() => _pagina.value + 1 < _totalPaginas.value);

  ReadonlySignal<AppStatus> get statusSignal => _status;
  ReadonlySignal<List<ChamadoResumo>> get chamadosSignal => _chamados;
  ReadonlySignal<AppFailure?> get errorSignal => _error;
  ReadonlySignal<MeusChamadosFiltro> get filtroSignal => _filtro;
  ReadonlySignal<int> get totalElementosSignal => _totalElementos;
  ReadonlySignal<bool> get carregandoMaisSignal => _carregandoMais;
  ReadonlySignal<bool> get temMaisSignal => _temMais;

  /// Token para descartar resposta obsoleta quando o usuário troca o filtro mais
  /// rápido que a rede responde. É **compartilhado** com [carregarMais] de
  /// propósito: sem isso, a página 2 de um filtro abandonado seria concatenada
  /// na lista do filtro novo.
  int _requestId = 0;

  /// Últimos [_mesesIniciais] meses, sem filtros de recorte.
  static MeusChamadosFiltro _filtroInicial() {
    final hoje = DateTime.now();
    return MeusChamadosFiltro(
      dataIni: DateTime(hoje.year, hoje.month - _mesesIniciais, hoje.day),
      dataFim: hoje,
    );
  }

  /// (Re)carrega a primeira página, descartando o que já estava na tela.
  Future<void> load() async {
    final requestId = ++_requestId;
    batch(() {
      _status.value = AppStatus.loading;
      _error.value = null;
      _pagina.value = 0;
      // Um `carregarMais` em voo acabou de ser invalidado pelo requestId e não
      // vai baixar a própria flag: sem zerar aqui, a nova lista nunca mais
      // pagina.
      _carregandoMais.value = false;
    });

    final result = await _repository.buscar(
      filtro: _filtro.peek(),
      page: 0,
      size: _pageSize,
    );
    if (requestId != _requestId) return;

    result.onSuccess((pagina) {
      batch(() {
        _chamados.value = pagina.itens;
        _pagina.value = pagina.pagina;
        _totalPaginas.value = pagina.totalPaginas;
        _totalElementos.value = pagina.totalElementos;
        _status.value = AppStatus.success;
      });
    }).onFailure((failure) {
      batch(() {
        // Não deixa dado obsoleto na tela junto de uma mensagem de erro.
        _chamados.value = const [];
        _totalPaginas.value = 0;
        _totalElementos.value = 0;
        _error.value = failure;
        _status.value = AppStatus.failure;
      });
      AppLogger.warning('MeusChamadosController.load failed: ${failure.message}');
    });
  }

  /// Anexa a próxima página. Silencioso quando já está carregando ou acabou.
  Future<void> carregarMais() async {
    if (_carregandoMais.peek() || !_temMais.peek()) return;

    final requestId = ++_requestId;
    final proxima = _pagina.peek() + 1;
    _carregandoMais.value = true;

    final result = await _repository.buscar(
      filtro: _filtro.peek(),
      page: proxima,
      size: _pageSize,
    );

    // O filtro mudou enquanto a página vinha: descarta sem tocar na lista. A
    // flag já foi zerada pelo `load` que assumiu o lugar deste ciclo.
    if (requestId != _requestId) return;
    _carregandoMais.value = false;

    result.onSuccess((pagina) {
      batch(() {
        _chamados.value = [..._chamados.peek(), ...pagina.itens];
        _pagina.value = pagina.pagina;
        _totalPaginas.value = pagina.totalPaginas;
        _totalElementos.value = pagina.totalElementos;
      });
    }).onFailure((failure) {
      // Falha ao paginar não derruba o que já está na tela — o usuário
      // simplesmente tenta rolar de novo.
      AppLogger.warning(
          'MeusChamadosController.carregarMais failed: ${failure.message}');
    });
  }

  /// Aplica um filtro estrutural (dropdowns, período) e recarrega na hora.
  void aplicarFiltro(MeusChamadosFiltro filtro) {
    _filtro.value = filtro;
    load();
  }

  /// Busca por título ou número, com debounce.
  void buscar(String termo) {
    _filtro.value = _filtro.peek().copyWith(termo: termo);
    _debouncer.run(load);
  }

  /// Volta ao estado inicial (últimos 12 meses, só em aberto).
  void limparFiltros() {
    _debouncer.dispose();
    _filtro.value = _filtroInicial();
    load();
  }

  void dispose() {
    _debouncer.dispose();
    _status.dispose();
    _chamados.dispose();
    _error.dispose();
    _filtro.dispose();
    _pagina.dispose();
    _totalPaginas.dispose();
    _totalElementos.dispose();
    _carregandoMais.dispose();
    _temMais.dispose();
  }
}
