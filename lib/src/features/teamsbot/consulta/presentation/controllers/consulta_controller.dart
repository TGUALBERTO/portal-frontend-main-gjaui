import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/consulta/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/data/repositories/consulta_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado da tela de consulta RAG (app-scoped).
class ConsultaController {
  ConsultaController({required ConsultaRepository repository})
      : _repository = repository;

  final ConsultaRepository _repository;

  final _resposta = signal<RagResposta?>(null);
  final _isLoading = signal(false);
  final _hasSearched = signal(false);
  final _error = signal<AppFailure?>(null);

  ReadonlySignal<RagResposta?> get resposta => _resposta;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<bool> get hasSearched => _hasSearched;
  ReadonlySignal<AppFailure?> get error => _error;

  Future<void> consultar({
    required String pergunta,
    ConsultaFiltros? filtros,
    String? usuarioId,
  }) async {
    _isLoading.value = true;
    _error.value = null;
    _hasSearched.value = true;

    final result = await _repository.consultar(
      ConsultaRequest(
        pergunta: pergunta,
        filtros: filtros,
        usuarioId: usuarioId,
      ),
    );

    _isLoading.value = false;
    result.onSuccess((data) {
      _resposta.value = data;
    }).onFailure((failure) {
      _error.value = failure;
      _resposta.value = null;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  void dispose() {
    _resposta.dispose();
    _isLoading.dispose();
    _hasSearched.dispose();
    _error.dispose();
  }
}
