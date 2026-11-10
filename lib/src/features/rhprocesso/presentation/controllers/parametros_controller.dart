import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/rhprocesso/data/repositories/cadastros_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/parametro.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado da tela Parâmetros Gerais (app-scoped).
class ParametrosController {
  ParametrosController({required CadastrosRepository repository})
      : _repository = repository;

  final CadastrosRepository _repository;

  final _parametros = signal<List<Parametro>>(const []);
  final _carregando = signal(false);
  final _erro = signal<AppFailure?>(null);
  final _salvandoId = signal<int?>(null);

  ReadonlySignal<List<Parametro>> get parametros => _parametros;
  ReadonlySignal<bool> get carregando => _carregando;
  ReadonlySignal<AppFailure?> get erro => _erro;
  ReadonlySignal<int?> get salvandoId => _salvandoId;

  Future<void> carregar() async {
    batch(() {
      _carregando.value = true;
      _erro.value = null;
    });
    final result = await _repository.parametros();
    _carregando.value = false;
    result
        .onSuccess((lista) => _parametros.value = lista)
        .onFailure((failure) => _erro.value = failure);
  }

  /// Grava descrição e valor. `true` quando salvou. A validação local é a
  /// mesma da API; a API valida de novo.
  Future<bool> alterar(Parametro atual, {required String descricao, required String valor}) async {
    final invalido = atual.validar(valor);
    if (invalido != null) {
      showGlobalToast(message: invalido, status: 'error');
      return false;
    }
    final desc = descricao.trim();
    if (desc.isEmpty) {
      showGlobalToast(message: 'Informe a descrição.', status: 'error');
      return false;
    }

    _salvandoId.value = atual.id;
    final result = await _repository.alterarParametro(
      atual.id,
      descricao: desc,
      valor: int.parse(valor.trim()),
    );
    _salvandoId.value = null;

    return result.fold((salvo) {
      _parametros.value = [
        for (final p in _parametros.value) p.id == salvo.id ? salvo : p,
      ];
      showGlobalToast(message: 'Parâmetro ${salvo.id} atualizado.', status: 'success');
      return true;
    }, (failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return false;
    });
  }

  void dispose() {
    _parametros.dispose();
    _carregando.dispose();
    _erro.dispose();
    _salvandoId.dispose();
  }
}
