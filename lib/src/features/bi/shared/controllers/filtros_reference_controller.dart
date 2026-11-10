import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/utils/utils.dart';

import '../data/filtros_repository.dart';
import '../models/filtro_opcao.dart';

/// Dados de referência dos seletores de filtro (empresas/squads), app-scoped:
/// carga única e reaproveitada por todas as telas. Não confundir com o
/// [BiFilterController] (que guarda o filtro ATIVO). Falha é best-effort — a barra
/// simplesmente não mostra o seletor sem opções.
class FiltrosReferenceController {
  FiltrosReferenceController({required FiltrosRepository repository})
      : _repo = repository;

  final FiltrosRepository _repo;

  final Signal<List<String>> empresas = signal(const []);
  final Signal<List<FiltroOpcao>> squads = signal(const []);
  final Signal<bool> isLoading = signal(false);
  final Signal<AppFailure?> error = signal(null);

  bool get _carregado => empresas.value.isNotEmpty || squads.value.isNotEmpty;

  Future<void> load({bool force = false}) async {
    if (isLoading.value) return;
    if (_carregado && !force) return;
    isLoading.value = true;
    error.value = null;

    final result = await _repo.carregar();

    isLoading.value = false;
    result.onSuccess((ref) {
      empresas.value = ref.empresas;
      squads.value = ref.squads;
    }).onFailure((f) => error.value = f);
  }

  void dispose() {
    empresas.dispose();
    squads.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
