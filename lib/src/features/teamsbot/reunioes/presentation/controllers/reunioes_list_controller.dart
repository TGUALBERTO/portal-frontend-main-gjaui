import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/atas/data/models/ata_status.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/repositories/reunioes_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Colunas ordenáveis da tabela de reuniões. A ordem casa 1-a-1 com a ordem das
/// colunas do `DataTable`.
enum ReuniaoSortColumn {
  assunto,
  organizador,
  inicio,
  online,
  participantes,
  status,
  transcricao,
  fila,
  ata,
}

/// Estado da tela de reuniões monitoradas (app-scoped).
///
/// Auto-refresh a cada 8s enquanto houver reuniões em estados transitórios.
///
/// A busca (assunto/organizador) e a ordenação são <b>client-side</b> via
/// [visibleReunioes]; os demais filtros (período, usuário, status, transcrição)
/// são server-side e recarregam a lista.
class ReunioesListController {
  ReunioesListController({required ReunioesRepository repository})
      : _repository = repository {
    _visibleReunioes = computed(_computeVisible);
  }

  final ReunioesRepository _repository;

  final _reunioes = signal<List<MonitoredMeetingResumo>>(const []);
  final _isLoading = signal(false);
  final _error = signal<AppFailure?>(null);

  // Filtros server-side.
  final _de = signal<DateTime?>(null);
  final _ate = signal<DateTime?>(null);
  final _usuario = signal('');
  final _statusReuniao = signal<ReuniaoProcessamentoStatus?>(null);
  final _statusAta = signal<AtaStatus?>(null);
  final _comTranscricao = signal<bool?>(null);

  // Busca client-side (assunto/organizador), instantânea.
  final _busca = signal('');

  // Ordenação client-side. Padrão: início mais recente primeiro.
  final _sortColumn = signal(ReuniaoSortColumn.inicio);
  final _sortAscending = signal(false);

  /// Lista exibida: [reunioes] filtrada pela [busca] e ordenada.
  late final Computed<List<MonitoredMeetingResumo>> _visibleReunioes;

  ReadonlySignal<List<MonitoredMeetingResumo>> get reunioes => _reunioes;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<AppFailure?> get error => _error;
  ReadonlySignal<DateTime?> get de => _de;
  ReadonlySignal<DateTime?> get ate => _ate;
  ReadonlySignal<String> get usuario => _usuario;
  ReadonlySignal<ReuniaoProcessamentoStatus?> get statusReuniao =>
      _statusReuniao;
  ReadonlySignal<AtaStatus?> get statusAta => _statusAta;
  ReadonlySignal<bool?> get comTranscricao => _comTranscricao;
  ReadonlySignal<String> get busca => _busca;
  ReadonlySignal<ReuniaoSortColumn> get sortColumn => _sortColumn;
  ReadonlySignal<bool> get sortAscending => _sortAscending;
  ReadonlySignal<List<MonitoredMeetingResumo>> get visibleReunioes =>
      _visibleReunioes;

  static const _pollInterval = Duration(seconds: 8);
  Timer? _pollTimer;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result = await _repository.listarMonitoradas(
      de: _de.value,
      ate: _ate.value,
      usuario: _usuario.value,
      statusReuniao: _statusReuniao.value?.apiValue,
      statusAta: _statusAta.value?.apiValue,
      comTranscricao: _comTranscricao.value,
    );

    _isLoading.value = false;
    result.onSuccess((list) {
      _reunioes.value = list;
      _syncPolling();
    }).onFailure((failure) {
      _error.value = failure;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  Future<void> refresh() => load(showLoading: false);

  // ── Setters de filtro (a tela decide quando recarregar via [load]) ────────

  // ignore: use_setters_to_change_properties
  void setBusca(String value) => _busca.value = value;

  // ignore: use_setters_to_change_properties
  void setUsuario(String value) => _usuario.value = value;

  void setPeriodo({DateTime? de, DateTime? ate}) {
    _de.value = de;
    _ate.value = ate;
  }

  // ignore: use_setters_to_change_properties
  void setStatusReuniao(ReuniaoProcessamentoStatus? status) =>
      _statusReuniao.value = status;

  // ignore: use_setters_to_change_properties
  void setStatusAta(AtaStatus? status) => _statusAta.value = status;

  // ignore: use_setters_to_change_properties
  void setComTranscricao(bool? value) => _comTranscricao.value = value;

  void clearFilters() {
    _de.value = null;
    _ate.value = null;
    _usuario.value = '';
    _statusReuniao.value = null;
    _statusAta.value = null;
    _comTranscricao.value = null;
    _busca.value = '';
    load();
  }

  /// `true` quando há qualquer filtro/busca ativo (habilita o "Limpar").
  bool get temFiltroAtivo =>
      _de.value != null ||
      _ate.value != null ||
      _usuario.value.isNotEmpty ||
      _statusReuniao.value != null ||
      _statusAta.value != null ||
      _comTranscricao.value != null ||
      _busca.value.trim().isNotEmpty;

  /// Aplica a ordenação por [coluna] na direção [ascendente].
  void ordenarPor(ReuniaoSortColumn coluna, bool ascendente) {
    _sortColumn.value = coluna;
    _sortAscending.value = ascendente;
  }

  /// Atalho do KPI de transcrição: alterna o filtro "com transcrição" (server-side).
  void alternarTranscricao() {
    _comTranscricao.value = (_comTranscricao.value ?? false) ? null : true;
    load();
  }

  List<MonitoredMeetingResumo> _computeVisible() {
    final q = _busca.value.trim().toLowerCase();
    final list = q.isEmpty
        ? List.of(_reunioes.value)
        : _reunioes.value.where((r) {
            final assunto = (r.assunto ?? '').toLowerCase();
            final org = (r.organizador ?? '').toLowerCase();
            return assunto.contains(q) || org.contains(q);
          }).toList();

    final coluna = _sortColumn.value;
    final asc = _sortAscending.value;
    list.sort((a, b) {
      final cmp = _compare(a, b, coluna);
      return asc ? cmp : -cmp;
    });
    return list;
  }

  int _compare(
      MonitoredMeetingResumo a, MonitoredMeetingResumo b, ReuniaoSortColumn c) {
    switch (c) {
      case ReuniaoSortColumn.assunto:
        return _str(a.assunto).compareTo(_str(b.assunto));
      case ReuniaoSortColumn.organizador:
        return _str(a.organizador).compareTo(_str(b.organizador));
      case ReuniaoSortColumn.inicio:
        return _cmpDate(a.inicio, b.inicio);
      case ReuniaoSortColumn.online:
        return _boolKey(a.online).compareTo(_boolKey(b.online));
      case ReuniaoSortColumn.participantes:
        return a.totalParticipantes.compareTo(b.totalParticipantes);
      case ReuniaoSortColumn.status:
        return a.statusProcessamento.label
            .compareTo(b.statusProcessamento.label);
      case ReuniaoSortColumn.transcricao:
        return _boolKey(a.temTranscricao).compareTo(_boolKey(b.temTranscricao));
      case ReuniaoSortColumn.fila:
        return _str(a.statusFila?.label).compareTo(_str(b.statusFila?.label));
      case ReuniaoSortColumn.ata:
        return _str(a.statusAta?.label).compareTo(_str(b.statusAta?.label));
    }
  }

  String _str(String? v) => (v ?? '').toLowerCase();
  int _boolKey(bool v) => v ? 1 : 0;

  int _cmpDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  void _syncPolling() {
    final precisa = _reunioes.value.any((r) => r.emAndamento);
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
    _visibleReunioes.dispose();
    _reunioes.dispose();
    _isLoading.dispose();
    _error.dispose();
    _de.dispose();
    _ate.dispose();
    _usuario.dispose();
    _statusReuniao.dispose();
    _statusAta.dispose();
    _comTranscricao.dispose();
    _busca.dispose();
    _sortColumn.dispose();
    _sortAscending.dispose();
  }
}
