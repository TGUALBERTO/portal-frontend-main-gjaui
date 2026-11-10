import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/atas/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/repositories/atas_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado do detalhe de uma ATA. Escopado por rota (`/teamsbot/atas/:id`).
///
/// Após reindexar/editar/reprocessar, faz polling do detalhe a cada 5s até a
/// indexação estabilizar ([IndexStatus.isEstavel]).
class AtaDetalheController {
  AtaDetalheController({required this.id, required AtasRepository repository})
      : _repository = repository;

  final int id;
  final AtasRepository _repository;

  final _detalhe = signal<AtaDetalhe?>(null);
  final _isLoading = signal(false);
  final _isMutating = signal(false);
  final _isPolling = signal(false);
  final _error = signal<AppFailure?>(null);

  ReadonlySignal<AtaDetalhe?> get detalhe => _detalhe;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<bool> get isMutating => _isMutating;
  ReadonlySignal<bool> get isPolling => _isPolling;
  ReadonlySignal<AppFailure?> get error => _error;

  static const _pollInterval = Duration(seconds: 5);
  Timer? _pollTimer;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result = await _repository.detalhe(id);

    _isLoading.value = false;
    result.onSuccess((data) {
      _detalhe.value = data;
    }).onFailure((failure) {
      _error.value = failure;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  Future<bool> editar(String markdown) => _mutate(
        () => _repository.editar(id, markdown),
        sucesso: 'ATA salva — nova versão gerada. Reindexando…',
        pollAfter: true,
      );

  Future<bool> indexar() => _mutate(
        () => _repository.indexar(id),
        sucesso: 'Reindexação solicitada…',
        pollAfter: true,
      );

  /// (Re)envia o .docx ao SharePoint — cobre o backfill de ATAs geradas antes da
  /// integração. O envio é assíncrono no backend (202); recarregamos o detalhe ao
  /// final para refletir o novo estado (PENDENTE_ENVIO → ENVIADA/ERRO_ENVIO).
  Future<bool> enviarSharepoint() async {
    final ok = await _mutate(
      () => _repository.reenviarSharepoint(id),
      sucesso: 'Envio ao SharePoint solicitado…',
    );
    if (ok) await load(showLoading: false);
    return ok;
  }

  /// Reprocessa a ATA: regera o conteúdo a partir da transcrição existente
  /// (`gerar` com `force: true`). A regeração é assíncrona no backend (202),
  /// então recarregamos o detalhe ao final para refletir a mudança de estado.
  Future<bool> reprocessar() async {
    final d = _detalhe.value;
    if (d == null) return false;
    final ok = await _mutate(
      () => _repository.gerar(GerarAtaRequest(
        userId: d.userId,
        meetingId: d.meetingId,
        transcriptId: d.transcriptId,
        force: true,
      )),
      sucesso: 'Reprocessamento solicitado…',
    );
    if (ok) await load(showLoading: false);
    return ok;
  }

  /// Executa uma mutação que atualiza (ou não) o detalhe e trata falhas.
  Future<bool> _mutate<T extends Object>(
    AsyncAppResult<T> Function() action, {
    required String sucesso,
    bool pollAfter = false,
  }) async {
    _isMutating.value = true;
    final result = await action();
    _isMutating.value = false;

    return result.fold(
      (value) {
        if (value is AtaDetalhe) _detalhe.value = value;
        showGlobalToast(message: sucesso, status: 'success');
        if (pollAfter) _startIndexPolling();
        return true;
      },
      (failure) {
        _handleFailure(failure);
        return false;
      },
    );
  }

  void _handleFailure(AppFailure failure) {
    showGlobalToast(message: failure.message, status: 'error');
    // 404 (não encontrada) / 409 (conflito de estado): re-sincroniza.
    if (failure is ApiFailure && (failure.isNotFound || failure.isConflict)) {
      load(showLoading: false);
    }
  }

  void _startIndexPolling() {
    _isPolling.value = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await load(showLoading: false);
      _checkPollingDone();
    });
    // Checagem imediata (captura ATA_INDEXANDO logo após a ação).
    load(showLoading: false).then((_) => _checkPollingDone());
  }

  void _checkPollingDone() {
    final d = _detalhe.value;
    if (d != null && d.indexStatus.isEstavel) {
      _stopPolling();
    }
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
