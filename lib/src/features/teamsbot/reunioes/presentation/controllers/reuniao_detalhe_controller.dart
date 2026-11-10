import 'dart:async';

import 'package:result_dart/result_dart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/repositories/reunioes_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado do detalhe de uma reunião (`/teamsbot/reunioes/:id`). Escopado por rota.
///
/// Após reprocessar/reenfileirar, faz polling até o pipeline estabilizar.
class ReuniaoDetalheController {
  ReuniaoDetalheController(
      {required this.id, required ReunioesRepository repository})
      : _repository = repository;

  final int id;
  final ReunioesRepository _repository;

  final _detalhe = signal<MonitoredMeetingDetalhe?>(null);
  final _isLoading = signal(false);
  final _isMutating = signal(false);
  final _isPolling = signal(false);
  final _error = signal<AppFailure?>(null);

  ReadonlySignal<MonitoredMeetingDetalhe?> get detalhe => _detalhe;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<bool> get isMutating => _isMutating;
  ReadonlySignal<bool> get isPolling => _isPolling;
  ReadonlySignal<AppFailure?> get error => _error;

  static const _pollInterval = Duration(seconds: 8);
  Timer? _pollTimer;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result = await _repository.detalheMonitorada(id);

    _isLoading.value = false;
    result.onSuccess((data) {
      _detalhe.value = data;
    }).onFailure((failure) {
      _error.value = failure;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  Future<bool> reprocessar() => _mutate(
        _repository.reprocessar(id),
        sucesso: 'Reprocessamento iniciado…',
      );

  Future<bool> enfileirar() => _mutate(
        _repository.enfileirar(id),
        sucesso: 'Reunião reenfileirada para gerar a ATA…',
      );

  Future<bool> _mutate(AsyncAppResult<Unit> action,
      {required String sucesso}) async {
    _isMutating.value = true;
    final result = await action;
    _isMutating.value = false;

    return result.fold(
      (_) {
        showGlobalToast(message: sucesso, status: 'success');
        _startPolling();
        return true;
      },
      (failure) {
        showGlobalToast(message: failure.message, status: 'error');
        if (failure is ApiFailure && (failure.isNotFound || failure.isConflict)) {
          load(showLoading: false);
        }
        return false;
      },
    );
  }

  void _startPolling() {
    _isPolling.value = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await load(showLoading: false);
      _checkDone();
    });
    load(showLoading: false).then((_) => _checkDone());
  }

  void _checkDone() {
    final d = _detalhe.value;
    if (d != null && !d.emAndamento) _stopPolling();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling.value = false;
  }

  void dispose() {
    _stopPolling();
    _detalhe.dispose();
    _isLoading.dispose();
    _isMutating.dispose();
    _isPolling.dispose();
    _error.dispose();
  }
}
