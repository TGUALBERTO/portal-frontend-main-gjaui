import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../data/models/sla_backlog_dashboard.dart';
import '../../data/repositories/sla_backlog_repository.dart';

/// Estado do painel "SLA e Backlog" (app-scoped). Compartilhado pelas abas SLA e
/// Backlog e Aging — uma única chamada alimenta as duas visões.
class SlaBacklogController {
  SlaBacklogController({
    required SlaBacklogRepository repository,
    required BiFilterController filtro,
  })  : _repo = repository,
        _filtro = filtro;

  final SlaBacklogRepository _repo;
  final BiFilterController _filtro;

  final Signal<SlaBacklogDashboard?> data = signal(null);
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
