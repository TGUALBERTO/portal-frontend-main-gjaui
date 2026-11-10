import 'package:gjamobile/src/features/helpdesk/timesheet/data/repositories/timesheet_repository.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado.dart';
import 'package:gjamobile/src/shared/enums/app_status.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Controller do formulário de novo apontamento (screen-scoped: criado pelo
/// sheet, que deve dar `dispose()`).
///
/// Mantém a busca de chamados com debounce e o estado de seleção/envio; as
/// horas e a descrição vivem no formulário (widget), que monta os `DateTime`
/// no dia selecionado do Timesheet e chama [criar].
class ApontamentoController {
  ApontamentoController({required TimesheetRepository repository})
      : _repository = repository;

  final TimesheetRepository _repository;
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 400));

  late final Signal<AppStatus> _buscaStatus = signal(AppStatus.initial);
  late final Signal<List<Chamado>> _resultados = signal(const []);
  late final Signal<Chamado?> _chamadoSelecionado = signal(null);
  late final Signal<bool> _enviando = signal(false);

  ReadonlySignal<AppStatus> get buscaStatusSignal => _buscaStatus;
  ReadonlySignal<List<Chamado>> get resultadosSignal => _resultados;
  ReadonlySignal<Chamado?> get chamadoSelecionadoSignal => _chamadoSelecionado;
  ReadonlySignal<bool> get enviandoSignal => _enviando;

  /// Token para descartar resposta obsoleta quando o usuário digita mais
  /// rápido que a rede responde (mesmo padrão do TimesheetController).
  int _requestId = 0;

  /// Busca chamados por [termo] (título ou id de origem), com debounce.
  void buscar(String termo) {
    final query = termo.trim();
    _chamadoSelecionado.value = null;
    if (query.length < 2) {
      _debouncer.dispose();
      _resultados.value = const [];
      _buscaStatus.value = AppStatus.initial;
      return;
    }
    _debouncer.run(() async {
      final requestId = ++_requestId;
      _buscaStatus.value = AppStatus.loading;
      final result = await _repository.searchChamados(termo: query);
      if (requestId != _requestId) return;
      result.onSuccess((data) {
        batch(() {
          _resultados.value = data;
          _buscaStatus.value = AppStatus.success;
        });
      }).onFailure((failure) {
        batch(() {
          _resultados.value = const [];
          _buscaStatus.value = AppStatus.failure;
        });
        AppLogger.warning(
            'ApontamentoController.buscar failed: ${failure.message}');
      });
    });
  }

  /// Seleciona um chamado do resultado e limpa a lista de sugestões.
  void selecionar(Chamado chamado) {
    batch(() {
      _chamadoSelecionado.value = chamado;
      _resultados.value = const [];
      _buscaStatus.value = AppStatus.initial;
    });
  }

  /// Envia o apontamento. Retorna `null` no sucesso ou a mensagem de erro
  /// (padrão dos form-sheets do projeto).
  Future<String?> criar({
    required DateTime inicio,
    required DateTime fim,
    required String descricao,
    required bool privado,
  }) async {
    final chamado = _chamadoSelecionado.value;
    if (chamado == null) return 'Selecione um chamado.';
    _enviando.value = true;
    try {
      final result = await _repository.criarApontamento(
        chamadoId: chamado.id,
        inicio: inicio,
        fim: fim,
        descricao: descricao,
        privado: privado,
      );
      return result.fold((_) => null, (failure) => failure.message);
    } finally {
      _enviando.value = false;
    }
  }

  /// Edita o apontamento [id] enviando só os campos alterados (nulo = não
  /// mudou). Não exige chamado selecionado: o chamado não é editável.
  /// Retorna `null` no sucesso ou a mensagem de erro.
  Future<String?> atualizar({
    required int id,
    DateTime? inicio,
    DateTime? fim,
    String? descricao,
    bool? privado,
  }) async {
    _enviando.value = true;
    try {
      final result = await _repository.atualizarApontamento(
        id: id,
        inicio: inicio,
        fim: fim,
        descricao: descricao,
        privado: privado,
      );
      return result.fold((_) => null, (failure) => failure.message);
    } finally {
      _enviando.value = false;
    }
  }

  /// Exclui o apontamento [id]. Retorna `null` no sucesso ou a mensagem de erro.
  Future<String?> excluir({required int id}) async {
    _enviando.value = true;
    try {
      final result = await _repository.excluirApontamento(id: id);
      return result.fold((_) => null, (failure) => failure.message);
    } finally {
      _enviando.value = false;
    }
  }

  void dispose() {
    _debouncer.dispose();
    _buscaStatus.dispose();
    _resultados.dispose();
    _chamadoSelecionado.dispose();
    _enviando.dispose();
  }
}
