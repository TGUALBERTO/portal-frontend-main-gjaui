import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../data/models/user_dashboard.dart';
import '../../data/repositories/user_repository.dart';

/// Estado do painel "Performance Individual". **Screen-scoped**: a tela cria o
/// controller já com o [userId] resolvido (rota, match por e-mail ou GLPI via
/// `findByEmail`) e o descarta no `dispose`.
class UserController {
  UserController({
    required UserRepository repository,
    required BiFilterController filtro,
    required this.userId,
  })  : _repo = repository,
        _filtro = filtro;

  final UserRepository _repo;
  final BiFilterController _filtro;

  /// Id do colaborador (usuário GLPI) a exibir.
  final int userId;

  final Signal<UserDashboard?> data = signal(null);
  final Signal<bool> isLoading = signal(false);
  final Signal<AppFailure?> error = signal(null);

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    error.value = null;

    final result = await _repo.carregar(userId, _filtro.filtro.value);

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
