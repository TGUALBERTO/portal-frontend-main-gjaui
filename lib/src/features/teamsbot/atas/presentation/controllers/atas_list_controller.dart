import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/atas/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/repositories/atas_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Colunas ordenáveis da tabela de ATAs. A ordem dos valores casa 1-a-1 com a
/// ordem das colunas do `DataTable` — usada para o `sortColumnIndex`.
enum AtaSortColumn {
  assunto,
  dataReuniao,
  status,
  indexStatus,
  sharepoint,
  versao,
  custo,
  criadoEm
}

/// Estado da tela de listagem de ATAs (app-scoped).
///
/// Faz auto-refresh a cada 5s enquanto houver alguma ATA com indexação em
/// andamento ([AtaResumo.indexEmAndamento]).
///
/// A busca por assunto e a ordenação são <b>client-side</b> (sobre a lista já
/// carregada) via [visibleAtas] — instantâneas e sem ida ao backend. Os filtros
/// de status/empresa continuam server-side (recarregam a lista).
class AtasListController {
  AtasListController({required AtasRepository repository})
      : _repository = repository {
    _visibleAtas = computed(_computeVisible);
  }

  final AtasRepository _repository;

  final _atas = signal<List<AtaResumo>>(const []);
  final _isLoading = signal(false);
  final _error = signal<AppFailure?>(null);

  // Filtros server-side.
  final _statusFilter = signal<AtaStatus?>(null);
  final _empresaFilter = signal('');

  // Busca client-side por assunto (instantânea).
  final _buscaAssunto = signal('');

  // Filtro client-side por situação de indexação (a API só filtra por status).
  final _indexFilter = signal<IndexStatus?>(null);

  // Ordenação client-side. Padrão: mais recentes primeiro (Criado em ↓).
  final _sortColumn = signal(AtaSortColumn.criadoEm);
  final _sortAscending = signal(false);

  /// Lista efetivamente exibida: [atas] filtrada pela [buscaAssunto] e ordenada
  /// por [sortColumn]/[sortAscending]. Recalcula sozinha quando qualquer um deles muda.
  late final Computed<List<AtaResumo>> _visibleAtas;

  ReadonlySignal<List<AtaResumo>> get atas => _atas;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<AppFailure?> get error => _error;
  ReadonlySignal<AtaStatus?> get statusFilter => _statusFilter;
  ReadonlySignal<String> get empresaFilter => _empresaFilter;
  ReadonlySignal<String> get buscaAssunto => _buscaAssunto;
  ReadonlySignal<IndexStatus?> get indexFilter => _indexFilter;
  ReadonlySignal<AtaSortColumn> get sortColumn => _sortColumn;
  ReadonlySignal<bool> get sortAscending => _sortAscending;
  ReadonlySignal<List<AtaResumo>> get visibleAtas => _visibleAtas;

  static const _pollInterval = Duration(seconds: 5);
  Timer? _pollTimer;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result = await _repository.listar(
      status: _statusFilter.value?.apiValue,
      empresa: _empresaFilter.value,
    );

    _isLoading.value = false;
    result.onSuccess((list) {
      _atas.value = list;
      _syncPolling();
    }).onFailure((failure) {
      _error.value = failure;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  Future<void> refresh() => load(showLoading: false);

  /// Dispara a geração de uma ATA (202) e atualiza a lista.
  Future<void> gerar(GerarAtaRequest req) async {
    final result = await _repository.gerar(req);
    result.onSuccess((_) {
      showGlobalToast(
        message:
            'Geração iniciada — a ATA aparecerá e será indexada automaticamente em instantes.',
        status: 'success',
      );
      refresh();
      // A geração é assíncrona; um refresh extra captura a nova ATA.
      Future.delayed(const Duration(seconds: 3), refresh);
    }).onFailure((failure) {
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  // ignore: use_setters_to_change_properties
  void setBuscaAssunto(String value) => _buscaAssunto.value = value;

  /// Filtro server-side de status (sem recarregar — use [applyFilters] ou
  /// [load] para efetivar no backend).
  // ignore: use_setters_to_change_properties
  void setStatusFilter(AtaStatus? status) => _statusFilter.value = status;

  /// Filtro client-side de indexação (instantâneo).
  // ignore: use_setters_to_change_properties
  void setIndexFilter(IndexStatus? index) => _indexFilter.value = index;

  void applyFilters({AtaStatus? status, String? empresa}) {
    _statusFilter.value = status;
    _empresaFilter.value = empresa ?? '';
    load();
  }

  void clearFilters() {
    _statusFilter.value = null;
    _empresaFilter.value = '';
    _buscaAssunto.value = '';
    _indexFilter.value = null;
    load();
  }

  /// `true` quando há qualquer filtro/busca ativo (habilita o "Limpar").
  bool get temFiltroAtivo =>
      _statusFilter.value != null ||
      _indexFilter.value != null ||
      _empresaFilter.value.isNotEmpty ||
      _buscaAssunto.value.trim().isNotEmpty;

  /// Atalho dos cards de resumo: filtra por indexação (client-side, instantâneo).
  /// Alterna — clicar no filtro já ativo remove-o.
  void alternarIndex(IndexStatus index) {
    _indexFilter.value = _indexFilter.value == index ? null : index;
  }

  /// Aplica a ordenação por [coluna]. Se for a coluna já ativa, inverte a direção;
  /// caso contrário, ordena por ela na direção [ascendente] pedida pela tabela.
  void ordenarPor(AtaSortColumn coluna, bool ascendente) {
    _sortColumn.value = coluna;
    _sortAscending.value = ascendente;
  }

  List<AtaResumo> _computeVisible() {
    final busca = _buscaAssunto.value.trim().toLowerCase();
    final index = _indexFilter.value;
    final list = _atas.value.where((a) {
      if (busca.isNotEmpty && !a.assunto.toLowerCase().contains(busca)) {
        return false;
      }
      if (index != null && a.indexStatus != index) return false;
      return true;
    }).toList();

    final coluna = _sortColumn.value;
    final asc = _sortAscending.value;
    list.sort((a, b) {
      final cmp = _compare(a, b, coluna);
      return asc ? cmp : -cmp;
    });
    return list;
  }

  int _compare(AtaResumo a, AtaResumo b, AtaSortColumn coluna) {
    switch (coluna) {
      case AtaSortColumn.assunto:
        return a.assunto.toLowerCase().compareTo(b.assunto.toLowerCase());
      case AtaSortColumn.dataReuniao:
        return _cmpDate(a.dataReuniao, b.dataReuniao);
      case AtaSortColumn.status:
        return a.status.label.compareTo(b.status.label);
      case AtaSortColumn.indexStatus:
        return a.indexStatus.label.compareTo(b.indexStatus.label);
      case AtaSortColumn.sharepoint:
        return a.sharepointStatus.label.compareTo(b.sharepointStatus.label);
      case AtaSortColumn.versao:
        return a.versaoAta.compareTo(b.versaoAta);
      case AtaSortColumn.custo:
        return _cmpNum(a.custoUsd, b.custoUsd);
      case AtaSortColumn.criadoEm:
        return a.criadoEm.compareTo(b.criadoEm);
    }
  }

  /// Nulos por último (tratados como menores — vão para o fim quando descendente).
  int _cmpDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  int _cmpNum(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  /// Liga/desliga o polling conforme existam ATAs em indexação.
  void _syncPolling() {
    final precisaPolling = _atas.value.any((a) => a.indexEmAndamento);
    if (precisaPolling) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => refresh());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _visibleAtas.dispose();
    _atas.dispose();
    _isLoading.dispose();
    _error.dispose();
    _statusFilter.dispose();
    _empresaFilter.dispose();
    _buscaAssunto.dispose();
    _indexFilter.dispose();
    _sortColumn.dispose();
    _sortAscending.dispose();
  }
}
