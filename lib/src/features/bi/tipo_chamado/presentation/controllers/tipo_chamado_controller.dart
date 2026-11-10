import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/utils/utils.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../data/models/tipo_chamado_dashboard.dart';
import '../../data/repositories/tipo_chamado_repository.dart';

/// Estado de um painel por tipo de chamado. **Screen-scoped**: cada tela
/// (Incidentes/Requisições/Mudanças) cria o seu com o [path] correspondente e o
/// descarta no `dispose`. Lê o filtro global no `load`.
class TipoChamadoController {
  TipoChamadoController({
    required TipoChamadoRepository repository,
    required BiFilterController filtro,
    required this.path,
  })  : _repo = repository,
        _filtro = filtro;

  final TipoChamadoRepository _repo;
  final BiFilterController _filtro;

  /// Endpoint do backend (ex.: `/dashboards/incidents`).
  final String path;

  final Signal<TipoChamadoDashboard?> data = signal(null);
  final Signal<bool> isLoading = signal(false);
  final Signal<AppFailure?> error = signal(null);

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    error.value = null;

    final result = await _repo.carregar(path, _filtro.filtro.value);

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
