import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/rhprocesso/data/repositories/estrutura_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/estrutura_rota.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado da tela Estrutura Comercial (app-scoped).
///
/// O período vem da lista do Workflow: é dele que a importação lê, e a
/// listagem mostra o que o RH Processo já tem para o mesmo período.
class EstruturaController {
  EstruturaController({required EstruturaRepository repository})
      : _repository = repository {
    _visiveis = computed(_filtrar);
  }

  final EstruturaRepository _repository;

  final _periodos = signal<List<Periodo>>(const []);
  final _periodo = signal<Periodo?>(null);
  final _rotas = signal<List<EstruturaRota>>(const []);
  final _carregando = signal(false);
  final _importando = signal(false);
  final _salvandoChave = signal<String?>(null);
  final _erro = signal<AppFailure?>(null);
  final _busca = signal('');

  late final Computed<List<EstruturaRota>> _visiveis;

  ReadonlySignal<List<Periodo>> get periodos => _periodos;
  ReadonlySignal<Periodo?> get periodo => _periodo;
  ReadonlySignal<List<EstruturaRota>> get rotas => _rotas;
  ReadonlySignal<List<EstruturaRota>> get visiveis => _visiveis;
  ReadonlySignal<bool> get carregando => _carregando;
  ReadonlySignal<bool> get importando => _importando;

  /// Rota (unidade|rota) cuja alteração está em voo.
  ReadonlySignal<String?> get salvandoChave => _salvandoChave;
  ReadonlySignal<AppFailure?> get erro => _erro;
  ReadonlySignal<String> get busca => _busca;

  /// Carrega os períodos do Workflow e a estrutura do mais recente.
  Future<void> iniciar() async {
    if (_periodos.value.isNotEmpty) {
      await listar();
      return;
    }
    _carregando.value = true;
    _erro.value = null;
    final result = await _repository.periodosWorkflow();
    result.onSuccess((lista) {
      _periodos.value = lista;
      _periodo.value = lista.isEmpty ? null : lista.first;
    }).onFailure((failure) {
      _erro.value = failure;
    });
    if (_periodo.value == null) {
      _carregando.value = false;
      return;
    }
    await listar();
  }

  Future<void> selecionarPeriodo(Periodo? p) async {
    if (p == null || p == _periodo.value) return;
    _periodo.value = p;
    await listar();
  }

  Future<void> listar() async {
    final p = _periodo.value;
    if (p == null) return;
    batch(() {
      _carregando.value = true;
      _erro.value = null;
    });
    final result = await _repository.listar(p);
    _carregando.value = false;
    result.onSuccess((lista) => _rotas.value = lista).onFailure((failure) {
      batch(() {
        _rotas.value = const [];
        _erro.value = failure;
      });
    });
  }

  /// Importa do Workflow as rotas que faltam no período e recarrega a lista.
  Future<ResultadoImportacao?> importar() async {
    final p = _periodo.value;
    if (p == null || _importando.value) return null;
    _importando.value = true;
    final result = await _repository.importar(p);
    _importando.value = false;

    ResultadoImportacao? resultado;
    result.onSuccess((r) {
      resultado = r;
      showGlobalToast(
        message: r.rotasIncluidas == 0
            ? 'Nenhuma rota nova no Workflow para ${p.rotulo}.'
            : '${r.rotasIncluidas} rota(s) incluída(s) em ${p.rotulo}.',
        status: 'success',
      );
    }).onFailure((failure) {
      showGlobalToast(message: failure.message, status: 'error');
    });
    if (resultado != null) await listar();
    return resultado;
  }

  /// Grava a nova hierarquia da rota. `true` quando salvou.
  Future<bool> alterar(EstruturaRota rota) async {
    _salvandoChave.value = rota.chave;
    final result = await _repository.alterar(rota);
    _salvandoChave.value = null;

    return result.fold((salva) {
      _rotas.value = [
        for (final r in _rotas.value) r.chave == salva.chave ? salva : r,
      ];
      showGlobalToast(message: 'Rota ${salva.rota} atualizada.', status: 'success');
      return true;
    }, (failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return false;
    });
  }

  // ignore: use_setters_to_change_properties
  void setBusca(String valor) => _busca.value = valor;

  List<EstruturaRota> _filtrar() {
    final termo = _busca.value.trim().toLowerCase();
    if (termo.isEmpty) return _rotas.value;
    return _rotas.value.where((r) {
      return [
        r.unidade,
        r.rota,
        r.matriculaConsultor,
        r.nomeConsultor,
        r.matriculaSupervisor,
        r.nomeSupervisor,
        r.nomeGerenteVendas,
      ].any((c) => c != null && c.toLowerCase().contains(termo));
    }).toList(growable: false);
  }

  void dispose() {
    _visiveis.dispose();
    _periodos.dispose();
    _periodo.dispose();
    _rotas.dispose();
    _carregando.dispose();
    _importando.dispose();
    _salvandoChave.dispose();
    _erro.dispose();
    _busca.dispose();
  }
}
