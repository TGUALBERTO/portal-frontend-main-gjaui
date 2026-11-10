import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/fila/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/fila/data/repositories/fila_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Colunas ordenáveis da tabela da fila. A ordem casa 1-a-1 com as colunas
/// ordenáveis do `DataTable` (as demais — ATA, Ações — não entram aqui).
enum FilaSortColumn {
  id,
  reuniao,
  status,
  tentativas,
  criado,
  iniciado,
  concluido,
}

/// Estado da tela da fila de criação de ATAs (app-scoped).
///
/// Auto-refresh enquanto houver itens AGUARDANDO/PROCESSANDO.
///
/// Busca (por número de item/reunião/ATA/transcrição) e ordenação são
/// <b>client-side</b> via [visibleItens]; o filtro de status é server-side.
class FilaController {
  FilaController({required FilaRepository repository})
      : _repository = repository {
    _visibleItens = computed(_computeVisible);
  }

  final FilaRepository _repository;

  final _itens = signal<List<FilaItem>>(const []);
  final _isLoading = signal(false);
  final _error = signal<AppFailure?>(null);
  final _statusFilter = signal<FilaStatus?>(null);
  final _retryingId = signal<int?>(null);

  // Busca client-side (número de item/reunião/ATA ou transcriptId).
  final _busca = signal('');

  // Ordenação client-side. Padrão: item mais recente primeiro.
  final _sortColumn = signal(FilaSortColumn.id);
  final _sortAscending = signal(false);

  /// Lista exibida: [itens] filtrada pela [busca] e ordenada.
  late final Computed<List<FilaItem>> _visibleItens;

  ReadonlySignal<List<FilaItem>> get itens => _itens;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<AppFailure?> get error => _error;
  ReadonlySignal<FilaStatus?> get statusFilter => _statusFilter;
  ReadonlySignal<int?> get retryingId => _retryingId;
  ReadonlySignal<String> get busca => _busca;
  ReadonlySignal<FilaSortColumn> get sortColumn => _sortColumn;
  ReadonlySignal<bool> get sortAscending => _sortAscending;
  ReadonlySignal<List<FilaItem>> get visibleItens => _visibleItens;

  static const _pollInterval = Duration(seconds: 6);
  Timer? _pollTimer;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result =
        await _repository.listarFila(status: _statusFilter.value?.apiValue);

    _isLoading.value = false;
    result.onSuccess((list) {
      _itens.value = list;
      _syncPolling();
    }).onFailure((failure) {
      _error.value = failure;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  Future<void> refresh() => load(showLoading: false);

  // ignore: use_setters_to_change_properties
  void setBusca(String value) => _busca.value = value;

  void aplicarFiltro(FilaStatus? status) {
    _statusFilter.value = status;
    load();
  }

  /// Atalho dos KPIs: alterna o filtro de status (server-side).
  void alternarStatus(FilaStatus status) {
    _statusFilter.value = _statusFilter.value == status ? null : status;
    load();
  }

  void limparFiltros() {
    _statusFilter.value = null;
    _busca.value = '';
    load();
  }

  /// `true` quando há filtro de status ou busca ativa.
  bool get temFiltroAtivo =>
      _statusFilter.value != null || _busca.value.trim().isNotEmpty;

  void ordenarPor(FilaSortColumn coluna, bool ascendente) {
    _sortColumn.value = coluna;
    _sortAscending.value = ascendente;
  }

  List<FilaItem> _computeVisible() {
    final q = _busca.value.trim().toLowerCase();
    final list = q.isEmpty
        ? List.of(_itens.value)
        : _itens.value.where((e) {
            final campos = [
              '${e.id}',
              '${e.reuniaoId}',
              if (e.ataId != null) '${e.ataId}',
              if (e.transcriptId != null) e.transcriptId!.toLowerCase(),
            ];
            return campos.any((c) => c.contains(q));
          }).toList();

    final coluna = _sortColumn.value;
    final asc = _sortAscending.value;
    list.sort((a, b) {
      final cmp = _compare(a, b, coluna);
      return asc ? cmp : -cmp;
    });
    return list;
  }

  int _compare(FilaItem a, FilaItem b, FilaSortColumn c) {
    switch (c) {
      case FilaSortColumn.id:
        return a.id.compareTo(b.id);
      case FilaSortColumn.reuniao:
        return a.reuniaoId.compareTo(b.reuniaoId);
      case FilaSortColumn.status:
        return a.status.label.compareTo(b.status.label);
      case FilaSortColumn.tentativas:
        return a.tentativas.compareTo(b.tentativas);
      case FilaSortColumn.criado:
        return _cmpDate(a.criadoEm, b.criadoEm);
      case FilaSortColumn.iniciado:
        return _cmpDate(a.iniciadoEm, b.iniciadoEm);
      case FilaSortColumn.concluido:
        return _cmpDate(a.concluidoEm, b.concluidoEm);
    }
  }

  int _cmpDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  Future<void> retry(int queueId) async {
    _retryingId.value = queueId;
    final result = await _repository.retryFila(queueId);
    _retryingId.value = null;
    result.onSuccess((item) {
      showGlobalToast(
          message: 'Item reenviado para processamento.', status: 'success');
      // Atualiza o item localmente e re-sincroniza para acompanhar o progresso.
      _itens.value = [
        for (final e in _itens.value)
          if (e.id == item.id) item else e,
      ];
      refresh();
    }).onFailure((failure) {
      showGlobalToast(message: failure.message, status: 'error');
      if (failure is ApiFailure && (failure.isNotFound || failure.isConflict)) {
        refresh();
      }
    });
  }

  void _syncPolling() {
    final precisa = _itens.value.any((e) => e.status.isTransitorio);
    if (precisa) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => refresh());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _visibleItens.dispose();
    _itens.dispose();
    _isLoading.dispose();
    _error.dispose();
    _statusFilter.dispose();
    _retryingId.dispose();
    _busca.dispose();
    _sortColumn.dispose();
    _sortAscending.dispose();
  }
}
