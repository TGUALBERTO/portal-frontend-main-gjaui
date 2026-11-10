import 'package:signals_flutter/signals_flutter.dart';

import '../models/dashboard_filter.dart';

/// Filtro global do BI (app-scoped): mantém o [DashboardFilter] ativo para que
/// ele persista ao trocar de dashboard. Cada tela lê este filtro no `load` e
/// recarrega quando ele muda.
class BiFilterController {
  final Signal<DashboardFilter> filtro = signal(const DashboardFilter());

  // ignore: use_setters_to_change_properties
  void aplicar(DashboardFilter novo) => filtro.value = novo;

  void limpar() => filtro.value = const DashboardFilter();

  bool get temFiltroAtivo => !filtro.value.vazio;

  void dispose() => filtro.dispose();
}
