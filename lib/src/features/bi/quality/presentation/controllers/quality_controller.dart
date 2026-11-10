import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../data/models/quality_dashboard.dart';
import '../../data/repositories/quality_repository.dart';

/// Estado do painel de Qualidade (app-scoped). Lê o filtro global no `load`.
class QualityController {
  QualityController({
    required QualityRepository repository,
    required BiFilterController filtro,
  })  : _repo = repository,
        _filtro = filtro;

  final QualityRepository _repo;
  final BiFilterController _filtro;

  final Signal<QualityDashboard?> data = signal(null);
  final Signal<bool> isLoading = signal(false);
  final Signal<AppFailure?> error = signal(null);

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    error.value = null;

    final result = await _repo.carregar(_filtro.filtro.value);

    isLoading.value = false;
    result.onSuccess((d) => data.value = d).onFailure((f) => error.value = f);
  }

  Future<void> refresh() => load(showLoading: false);

  void dispose() {
    data.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
