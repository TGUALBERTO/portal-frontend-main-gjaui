import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/rhprocesso/data/repositories/cadastros_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/produto.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado da tela Características de Produto (app-scoped): duas listas, os
/// produtos sem característica (a associar) e os já caracterizados.
class CaracteristicasController {
  CaracteristicasController({required CadastrosRepository repository})
      : _repository = repository {
    _visiveis = computed(_filtrar);
  }

  final CadastrosRepository _repository;

  final _caracterizados = signal(false);
  final _produtos = signal<List<Produto>>(const []);
  final _grupos = signal<List<String>>(const []);
  final _carregando = signal(false);
  final _erro = signal<AppFailure?>(null);
  final _busca = signal('');
  final _salvandoCodigo = signal<String?>(null);

  late final Computed<List<Produto>> _visiveis;

  /// `false`: lista dos sem característica; `true`: dos caracterizados.
  ReadonlySignal<bool> get caracterizados => _caracterizados;
  ReadonlySignal<List<Produto>> get produtos => _produtos;
  ReadonlySignal<List<Produto>> get visiveis => _visiveis;
  ReadonlySignal<List<String>> get grupos => _grupos;
  ReadonlySignal<bool> get carregando => _carregando;
  ReadonlySignal<AppFailure?> get erro => _erro;
  ReadonlySignal<String> get busca => _busca;
  ReadonlySignal<String?> get salvandoCodigo => _salvandoCodigo;

  Future<void> carregar() async {
    batch(() {
      _carregando.value = true;
      _erro.value = null;
    });
    final result =
        await _repository.produtos(caracterizados: _caracterizados.value);
    _carregando.value = false;
    result.onSuccess((lista) => _produtos.value = lista).onFailure((failure) {
      batch(() {
        _produtos.value = const [];
        _erro.value = failure;
      });
    });
  }

  Future<void> mostrarCaracterizados(bool valor) async {
    if (valor == _caracterizados.value) return;
    _caracterizados.value = valor;
    await carregar();
  }

  /// Grupos para o diálogo de associação, lidos uma vez.
  Future<List<String>> carregarGrupos() async {
    if (_grupos.value.isNotEmpty) return _grupos.value;
    final result = await _repository.grupos();
    return result.fold((lista) {
      _grupos.value = lista;
      return lista;
    }, (failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return const [];
    });
  }

  Future<List<String>> subgrupos(String grupo) async {
    final result = await _repository.subgrupos(grupo);
    return result.fold((lista) => lista, (failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return const [];
    });
  }

  /// Associa a característica. O produto sai da lista atual: na dos sem
  /// característica porque deixou de ser; na dos caracterizados é trocado pela
  /// versão nova.
  Future<bool> associar(
    Produto produto, {
    required String grupo,
    required String subgrupo,
    required double fator,
  }) async {
    _salvandoCodigo.value = produto.codigo;
    final result = await _repository.associar(
      produto.codigo,
      grupo: grupo,
      subgrupo: subgrupo,
      fator: fator,
    );
    _salvandoCodigo.value = null;

    return result.fold((salvo) {
      _produtos.value = _caracterizados.value
          ? [for (final p in _produtos.value) p.codigo == salvo.codigo ? salvo : p]
          : _produtos.value.where((p) => p.codigo != produto.codigo).toList();
      showGlobalToast(
        message: 'Produto ${produto.codigo} associado a $grupo / $subgrupo.',
        status: 'success',
      );
      return true;
    }, (failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return false;
    });
  }

  Future<bool> remover(Produto produto) async {
    _salvandoCodigo.value = produto.codigo;
    final result = await _repository.remover(produto.codigo);
    _salvandoCodigo.value = null;

    return result.fold((_) {
      _produtos.value =
          _produtos.value.where((p) => p.codigo != produto.codigo).toList();
      showGlobalToast(
        message: 'Característica do produto ${produto.codigo} removida.',
        status: 'success',
      );
      return true;
    }, (failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return false;
    });
  }

  // ignore: use_setters_to_change_properties
  void setBusca(String valor) => _busca.value = valor;

  List<Produto> _filtrar() {
    final termo = _busca.value.trim().toLowerCase();
    if (termo.isEmpty) return _produtos.value;
    return _produtos.value.where((p) {
      return [p.codigo, p.descricao, p.grupo, p.subgrupo]
          .any((c) => c != null && c.toLowerCase().contains(termo));
    }).toList(growable: false);
  }

  void dispose() {
    _visiveis.dispose();
    _caracterizados.dispose();
    _produtos.dispose();
    _grupos.dispose();
    _carregando.dispose();
    _erro.dispose();
    _busca.dispose();
    _salvandoCodigo.dispose();
  }
}
