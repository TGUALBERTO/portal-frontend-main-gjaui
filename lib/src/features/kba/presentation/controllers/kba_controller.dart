import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/kba/data/repositories/kba_repository.dart';
import 'package:gjamobile/src/features/kba/domain/entities/kba_session.dart';
import 'package:gjamobile/src/features/kba/domain/entities/kba_submit_result.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Etapas do wizard de vínculo (tela /vinculo).
enum KbaStep {
  cpf,
  loadingQuestions,
  questions,
  submitting,
  success,
  blocked,
  cpfNotFound,
  insufficientData,
}

/// Controller screen-scoped do fluxo Dynamic KBA. Mantém a etapa corrente,
/// a sessão de perguntas e as respostas selecionadas; valida tudo no backend.
class KbaController {
  KbaController({
    required KbaRepository repository,
    required AccessController accessController,
  })  : _repository = repository,
        _access = accessController;

  final KbaRepository _repository;
  final AccessController _access;

  final TextEditingController cpfController = TextEditingController();

  late final Signal<KbaStep> _step = signal(KbaStep.cpf);
  late final Signal<KbaSession?> _session = signal(null);
  late final MapSignal<String, int> _answers = mapSignal({});
  late final Signal<AppFailure?> _error = signal(null);

  /// Índice da pergunta exibida no Stepper (uma por vez).
  late final Signal<int> _currentQuestion = signal(0);
  late final Computed<bool> _canSubmit = computed(() {
    final session = _session.value;
    if (session == null) return false;
    return session.questions.every((q) => _answers.containsKey(q.id));
  });

  /// CPF (sem máscara) da sessão corrente — usado nos reinícios transparentes.
  String _lastCpf = '';

  ReadonlySignal<KbaStep> get stepSignal => _step;
  ReadonlySignal<KbaSession?> get sessionSignal => _session;
  ReadonlySignal<Map<String, int>> get answersSignal => _answers;
  ReadonlySignal<AppFailure?> get errorSignal => _error;
  ReadonlySignal<int> get currentQuestionSignal => _currentQuestion;
  ReadonlySignal<bool> get canSubmitSignal => _canSubmit;

  /// Coloca o fluxo direto na etapa de bloqueio (usuário já bloqueado em
  /// tentativa anterior, detectado no /users/me).
  void markBlocked() => _step.value = KbaStep.blocked;

  /// Envia o CPF digitado e carrega as perguntas da tentativa corrente.
  Future<void> submitCpf() async {
    final cpf = CpfInputFormatter.unmask(cpfController.text);
    if (cpf.length != 11) {
      _error.value = const ValidationFailure('Informe o CPF completo.');
      return;
    }
    _lastCpf = cpf;
    await _startSession(cpf);
  }

  void selectAnswer(String questionId, int optionIndex) {
    _answers[questionId] = optionIndex;
  }

  // ── Navegação do Stepper (uma pergunta por vez) ────────────────────────────

  void nextQuestion() {
    final total = _session.value?.questions.length ?? 0;
    if (_currentQuestion.value < total - 1) {
      _currentQuestion.value++;
    }
  }

  void previousQuestion() {
    if (_currentQuestion.value > 0) {
      _currentQuestion.value--;
    }
  }

  void goToQuestion(int index) {
    final total = _session.value?.questions.length ?? 0;
    if (index >= 0 && index < total) {
      _currentQuestion.value = index;
    }
  }

  /// Envia as respostas da sessão corrente.
  Future<void> submitAnswers() async {
    final session = _session.value;
    if (session == null || !_canSubmit.value) return;

    _step.value = KbaStep.submitting;
    _error.value = null;

    final result =
        await _repository.submitAnswers(session.sessionId, {..._answers});
    await result.fold(
      (submit) async {
        switch (submit.outcome) {
          case KbaSubmitOutcome.linked:
            _step.value = KbaStep.success;
            showGlobalToast(
              message: 'Matrícula vinculada com sucesso!',
              status: 'success',
            );
            // Recarrega o /users/me — o redirect global do router leva ao
            // home assim que needsEmployeeLink vira false.
            await _access.load();
          case KbaSubmitOutcome.wrongAnswers:
            showGlobalToast(
              message:
                  'Respostas incorretas. Você tem ${submit.attemptsRemaining} '
                  'tentativa restante.',
              status: 'warning',
            );
            // Nova tentativa = novo conjunto de perguntas.
            await _startSession(_lastCpf);
          case KbaSubmitOutcome.blocked:
            await _access.load();
            _step.value = KbaStep.blocked;
        }
      },
      (failure) async {
        final code = failure is ApiFailure ? failure.code : null;
        switch (code) {
          case KbaErrorCodes.sessionExpired:
            // Reinício transparente: mesma tentativa, mesmas perguntas.
            showGlobalToast(
              message: 'A sessão expirou; as perguntas foram recarregadas.',
              status: 'warning',
            );
            await _startSession(_lastCpf);
          case KbaErrorCodes.blocked:
            _step.value = KbaStep.blocked;
          case KbaErrorCodes.alreadyLinked:
            await _access.load();
            _step.value = KbaStep.success;
          default:
            _error.value = failure;
            _step.value = KbaStep.questions;
        }
      },
    );
  }

  /// Volta para a digitação de CPF (usado no "tentar novamente").
  void restart() {
    _session.value = null;
    _answers.clear();
    _currentQuestion.value = 0;
    _error.value = null;
    _step.value = KbaStep.cpf;
  }

  Future<void> _startSession(String cpf) async {
    _step.value = KbaStep.loadingQuestions;
    _error.value = null;
    _answers.clear();
    _currentQuestion.value = 0;

    final result = await _repository.startSession(cpf);
    await result.fold(
      (session) async {
        _session.value = session;
        _step.value = KbaStep.questions;
      },
      (failure) async {
        final code = failure is ApiFailure ? failure.code : null;
        switch (code) {
          case KbaErrorCodes.cpfNotFound:
            _step.value = KbaStep.cpfNotFound;
          case KbaErrorCodes.blocked:
            _step.value = KbaStep.blocked;
          case KbaErrorCodes.alreadyLinked:
            await _access.load();
            _step.value = KbaStep.success;
          case KbaErrorCodes.insufficientData:
            _step.value = KbaStep.insufficientData;
          case KbaErrorCodes.invalidCpf:
            _error.value = const ValidationFailure(
                'CPF inválido. Confira os dígitos informados.');
            _step.value = KbaStep.cpf;
          case KbaErrorCodes.rateLimited:
            _error.value = const ValidationFailure(
                'Muitas tentativas em sequência. Aguarde alguns minutos e '
                'tente novamente.');
            _step.value = KbaStep.cpf;
          default:
            _error.value = failure;
            _step.value = KbaStep.cpf;
        }
      },
    );
  }

  void dispose() {
    cpfController.dispose();
    _step.dispose();
    _session.dispose();
    _answers.dispose();
    _currentQuestion.dispose();
    _error.dispose();
    _canSubmit.dispose();
  }
}
