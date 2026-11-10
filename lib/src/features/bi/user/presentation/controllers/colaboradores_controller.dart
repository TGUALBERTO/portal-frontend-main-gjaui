import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/utils/utils.dart';

import '../../data/models/colaborador_ref.dart';
import '../../data/repositories/user_repository.dart';

/// Lista de colaboradores para o seletor do painel individual (app-scoped, carga
/// única e reaproveitada). Independe do filtro global — é dado de referência.
class ColaboradoresController {
  ColaboradoresController({required UserRepository repository})
      : _repo = repository;

  final UserRepository _repo;

  final Signal<List<ColaboradorRef>> itens = signal(const []);
  final Signal<bool> isLoading = signal(false);
  final Signal<AppFailure?> error = signal(null);

  bool get _carregado => itens.value.isNotEmpty;

  Future<void> load({bool force = false}) async {
    if (isLoading.value) return;
    if (_carregado && !force) return;
    isLoading.value = true;
    error.value = null;

    final result = await _repo.colaboradores();

    isLoading.value = false;
    result
        .onSuccess((lista) => itens.value = lista)
        .onFailure((f) => error.value = f);
  }

  /// Colaborador cujo e-mail bate com o do usuário logado (case-insensitive), ou
  /// nulo quando não há match — o seletor então fica em "Selecione um funcional".
  ColaboradorRef? porEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null;
    final alvo = email.trim().toLowerCase();
    for (final c in itens.value) {
      if (c.email.trim().toLowerCase() == alvo) return c;
    }
    return null;
  }

  void dispose() {
    itens.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
