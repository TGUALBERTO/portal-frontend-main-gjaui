import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/teamsbot/consulta/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/data/repositories/consulta_repository.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado da tela de histórico de consultas RAG do usuário (app-scoped).
///
/// A busca (pergunta/resposta) e a ordenação são <b>client-side</b> via
/// [visibleItens] — instantâneas, sobre a lista já carregada.
class ConsultaHistoricoController {
  ConsultaHistoricoController({required ConsultaRepository repository})
      : _repository = repository {
    _visibleItens = computed(_computeVisible);
  }

  final ConsultaRepository _repository;

  final _itens = signal<List<ConsultaHistoricoItem>>(const []);
  final _isLoading = signal(false);
  final _error = signal<AppFailure?>(null);

  // Busca client-side por pergunta/resposta (instantânea).
  final _busca = signal('');

  // Ordenação por data. Padrão: mais recentes primeiro.
  final _maisRecentesPrimeiro = signal(true);

  /// Lista exibida: [itens] filtrada pela [busca] e ordenada por data.
  late final Computed<List<ConsultaHistoricoItem>> _visibleItens;

  ReadonlySignal<List<ConsultaHistoricoItem>> get itens => _itens;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<AppFailure?> get error => _error;
  ReadonlySignal<String> get busca => _busca;
  ReadonlySignal<bool> get maisRecentesPrimeiro => _maisRecentesPrimeiro;
  ReadonlySignal<List<ConsultaHistoricoItem>> get visibleItens => _visibleItens;

  /// Guarda o usuário da última carga para o [refresh] recarregar o mesmo histórico.
  String _usuarioId = '';

  // ignore: use_setters_to_change_properties
  void setBusca(String value) => _busca.value = value;

  void alternarOrdem() =>
      _maisRecentesPrimeiro.value = !_maisRecentesPrimeiro.value;

  List<ConsultaHistoricoItem> _computeVisible() {
    final q = _busca.value.trim().toLowerCase();
    final list = q.isEmpty
        ? List.of(_itens.value)
        : _itens.value
            .where((e) =>
                e.pergunta.toLowerCase().contains(q) ||
                e.resposta.toLowerCase().contains(q))
            .toList();

    final desc = _maisRecentesPrimeiro.value;
    list.sort((a, b) {
      final cmp = _cmpDate(a.criadoEm, b.criadoEm);
      return desc ? -cmp : cmp;
    });
    return list;
  }

  int _cmpDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  Future<void> load(String usuarioId, {bool showLoading = true}) async {
    if (usuarioId.isEmpty) return;
    _usuarioId = usuarioId;
    if (showLoading) _isLoading.value = true;
    _error.value = null;

    final result = await _repository.historico(usuarioId);

    _isLoading.value = false;
    result.onSuccess((list) {
      _itens.value = list;
    }).onFailure((failure) {
      _error.value = failure;
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  Future<void> refresh() => load(_usuarioId, showLoading: false);

  void dispose() {
    _visibleItens.dispose();
    _itens.dispose();
    _isLoading.dispose();
    _error.dispose();
    _busca.dispose();
    _maisRecentesPrimeiro.dispose();
  }
}
