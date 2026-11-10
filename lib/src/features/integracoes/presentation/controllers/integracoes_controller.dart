import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/integracoes/data/models/models.dart';
import 'package:gjamobile/src/features/integracoes/data/repositories/integracoes_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Colunas ordenaveis da tabela de processos.
enum ProcessoSortColumn { nome, tipo, status, ultimaExecucao, proximaExecucao }

/// Estado da tela "Gerenciamento de Deltas" (app-scoped).
///
/// Auto-refresh enquanto houver processo executando ou bloqueado — o disparo
/// manual e assincrono no backend, entao a tela so descobre o desfecho
/// perguntando de novo.
///
/// Busca e ordenacao sao client-side: a lista tem menos de trinta itens e vem
/// inteira numa consulta.
class IntegracoesController {
  IntegracoesController({required IntegracoesRepository repository})
      : _repository = repository {
    _visiveis = computed(_computarVisiveis);
  }

  final IntegracoesRepository _repository;

  final _processos = signal<List<ProcessoIntegracao>>(const []);
  final _isLoading = signal(false);
  final _error = signal<AppFailure?>(null);
  final _busca = signal('');
  final _apenasAtivos = signal(false);
  final _executandoNome = signal<String?>(null);

  final _sortColumn = signal(ProcessoSortColumn.nome);
  final _sortAscending = signal(true);

  late final Computed<List<ProcessoIntegracao>> _visiveis;

  ReadonlySignal<List<ProcessoIntegracao>> get processos => _processos;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<AppFailure?> get error => _error;
  ReadonlySignal<String> get busca => _busca;
  ReadonlySignal<bool> get apenasAtivos => _apenasAtivos;

  /// Nome do processo cujo disparo esta em voo — spinner na linha.
  ReadonlySignal<String?> get executandoNome => _executandoNome;

  ReadonlySignal<ProcessoSortColumn> get sortColumn => _sortColumn;
  ReadonlySignal<bool> get sortAscending => _sortAscending;
  ReadonlySignal<List<ProcessoIntegracao>> get visiveis => _visiveis;

  static const _intervaloPolling = Duration(seconds: 5);
  Timer? _pollTimer;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result = await _repository.listar();

    _isLoading.value = false;
    result.onSuccess((lista) {
      _processos.value = lista;
      _sincronizarPolling();
    }).onFailure((failure) {
      _error.value = failure;
      AppLogger.warning('IntegracoesController.load falhou: ${failure.message}');
    });
  }

  Future<void> refresh() => load(showLoading: false);

  // ignore: use_setters_to_change_properties
  void setBusca(String value) => _busca.value = value;

  void alternarApenasAtivos() => _apenasAtivos.value = !_apenasAtivos.value;

  bool get temFiltroAtivo => _busca.value.trim().isNotEmpty || _apenasAtivos.value;

  void limparFiltros() {
    _busca.value = '';
    _apenasAtivos.value = false;
  }

  void ordenarPor(ProcessoSortColumn coluna, bool ascendente) {
    _sortColumn.value = coluna;
    _sortAscending.value = ascendente;
  }

  /// Dispara o processo. O backend aceita e devolve a execucao em andamento;
  /// o desfecho chega pelo polling.
  Future<void> executarAgora(String nome) async {
    _executandoNome.value = nome;
    final result = await _repository.executarAgora(nome);
    _executandoNome.value = null;

    result.onSuccess((_) {
      showGlobalToast(
        message: 'Processo "$nome" iniciado.',
        status: 'success',
      );
      refresh();
    }).onFailure((failure) {
      showGlobalToast(message: failure.message, status: 'error');
      // 409 significa que o estado do servidor mudou desde o ultimo refresh
      // (outro processo assumiu o grupo, ou a integracao caiu): reler corrige
      // a tela em vez de deixar o botao habilitado mentindo.
      if (failure is ApiFailure && (failure.isConflict || failure.isNotFound)) {
        refresh();
      }
    });
  }

  List<ProcessoIntegracao> _computarVisiveis() {
    final termo = _busca.value.trim().toLowerCase();
    final lista = _processos.value.where((p) {
      if (_apenasAtivos.value && !p.ativo) return false;
      if (termo.isEmpty) return true;
      return p.nome.toLowerCase().contains(termo) ||
          p.descricao.toLowerCase().contains(termo) ||
          p.grupoRecurso.toLowerCase().contains(termo);
    }).toList();

    final coluna = _sortColumn.value;
    final asc = _sortAscending.value;
    lista.sort((a, b) {
      final cmp = _comparar(a, b, coluna);
      return asc ? cmp : -cmp;
    });
    return lista;
  }

  int _comparar(ProcessoIntegracao a, ProcessoIntegracao b, ProcessoSortColumn c) {
    switch (c) {
      case ProcessoSortColumn.nome:
        return a.nome.compareTo(b.nome);
      case ProcessoSortColumn.tipo:
        return a.tipo.label.compareTo(b.tipo.label);
      case ProcessoSortColumn.status:
        return a.statusExibido.label.compareTo(b.statusExibido.label);
      case ProcessoSortColumn.ultimaExecucao:
        return _compararDatas(
            a.ultimaExecucao?.iniciadoEm, b.ultimaExecucao?.iniciadoEm);
      case ProcessoSortColumn.proximaExecucao:
        return _compararDatas(a.proximaExecucao, b.proximaExecucao);
    }
  }

  /// Sem data vai para o fim na ordem crescente: processo que nunca rodou nao
  /// deve encabecar a lista ordenada por ultima execucao.
  int _compararDatas(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  void _sincronizarPolling() {
    final precisa = _processos.value.any((p) => p.temAtividade);
    if (precisa) {
      _pollTimer ??= Timer.periodic(_intervaloPolling, (_) => refresh());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _visiveis.dispose();
    _processos.dispose();
    _isLoading.dispose();
    _error.dispose();
    _busca.dispose();
    _apenasAtivos.dispose();
    _executandoNome.dispose();
    _sortColumn.dispose();
    _sortAscending.dispose();
  }
}
