import 'package:gjamobile/src/imports/imports.dart';

/// Transforma a falha guardada no controller em toast.
///
/// Existe porque o `ContagemCegaController` é app-scoped e **não segura
/// `BuildContext`** — segurar daria `!mounted` depois do primeiro `context.go`.
/// Quem tem contexto é a tela, então a conversão falha → toast mora aqui.
///
/// `NetworkFailure` sai **calada**: `runTask` já dispara um toast global quando
/// não há rede (`task_runner.dart`), e repetir empilharia dois avisos iguais na
/// tela do coletor.
void avisarFalhaContagem(
  BuildContext context,
  AppFailure? falha, [
  String? configError,
]) {
  final mensagem = falha?.message ?? configError;
  if (mensagem == null) return;
  if (falha is NetworkFailure) return;

  showToast(context, message: mensagem, status: 'error');
}
