import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/custos/data/models/custo.dart';
import 'package:gjamobile/src/features/teamsbot/custos/data/repositories/custos_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado da tela de relatório de custos (app-scoped).
class CustosController {
  CustosController({required CustosRepository repository})
      : _repository = repository;

  final CustosRepository _repository;

  final _relatorio = signal<CustoRelatorio?>(null);
  final _isLoading = signal(false);
  final _error = signal<AppFailure?>(null);
  final _dataInicio = signal<DateTime?>(null);
  final _dataFim = signal<DateTime?>(null);

  ReadonlySignal<CustoRelatorio?> get relatorio => _relatorio;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<AppFailure?> get error => _error;
  ReadonlySignal<DateTime?> get dataInicio => _dataInicio;
  ReadonlySignal<DateTime?> get dataFim => _dataFim;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result = await _repository.custos(
      dataInicio: _dataInicio.value,
      dataFim: _dataFim.value,
    );

    _isLoading.value = false;
    result.onSuccess((data) {
      _relatorio.value = data;
    }).onFailure((failure) {
      _error.value = failure;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  void aplicarPeriodo({DateTime? inicio, DateTime? fim}) {
    _dataInicio.value = inicio;
    _dataFim.value = fim;
    load();
  }

  void dispose() {
    _relatorio.dispose();
    _isLoading.dispose();
    _error.dispose();
    _dataInicio.dispose();
    _dataFim.dispose();
  }
}
