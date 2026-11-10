import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_repository.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/kba/data/repositories/kba_repository.dart';
import 'package:gjamobile/src/features/kba/domain/entities/kba_question.dart';
import 'package:gjamobile/src/features/kba/domain/entities/kba_session.dart';
import 'package:gjamobile/src/features/kba/domain/entities/kba_submit_result.dart';
import 'package:gjamobile/src/features/kba/presentation/controllers/kba_controller.dart';
import 'package:gjamobile/src/utils/utils.dart';

class _FakeKbaRepository implements KbaRepository {
  int startCalls = 0;
  int submitCalls = 0;
  AppResult<KbaSession> Function(String cpf)? onStart;
  AppResult<KbaSubmitResult> Function(String sessionId, Map<String, int>)?
      onSubmit;

  @override
  AsyncAppResult<KbaSession> startSession(String cpf) async {
    startCalls++;
    return onStart!(cpf);
  }

  @override
  AsyncAppResult<KbaSubmitResult> submitAnswers(
    String sessionId,
    Map<String, int> answers,
  ) async {
    submitCalls++;
    return onSubmit!(sessionId, answers);
  }
}

class _FakeAccessRepository implements AccessRepository {
  @override
  AsyncAppResult<dynamic> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError();
}

/// AccessController com load() neutralizado (sem rede) e contado.
class _RecordingAccessController extends AccessController {
  _RecordingAccessController() : super(repository: _FakeAccessRepository());

  int loadCalls = 0;

  @override
  Future<void> load() async {
    loadCalls++;
  }
}

KbaSession _session({int attemptsRemaining = 2}) => KbaSession(
      sessionId: 's1',
      attemptNumber: 1,
      attemptsRemaining: attemptsRemaining,
      questions: const [
        KbaQuestion(id: 'q1', prompt: 'Bairro?', options: ['A', 'B', 'C']),
        KbaQuestion(id: 'q2', prompt: 'Ano?', options: ['1990', '1991']),
      ],
    );

void main() {
  // showGlobalToast lê rootNavigatorKey.currentContext (GlobalKey), que exige
  // o binding; sem árvore montada o contexto é nulo e o toast vira no-op.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeKbaRepository repository;
  late _RecordingAccessController access;
  late KbaController controller;

  setUp(() {
    repository = _FakeKbaRepository();
    access = _RecordingAccessController();
    controller = KbaController(
      repository: repository,
      accessController: access,
    );
  });

  tearDown(() {
    controller.dispose();
    access.dispose();
  });

  test('CPF incompleto nao chama o backend e mostra erro de validacao', () async {
    controller.cpfController.text = '529.982';
    await controller.submitCpf();

    expect(repository.startCalls, 0);
    expect(controller.stepSignal.value, KbaStep.cpf);
    expect(controller.errorSignal.value, isA<ValidationFailure>());
  });

  test('CPF valido carrega perguntas e vai para a etapa questions', () async {
    repository.onStart = (_) => Success(_session());
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();

    expect(repository.startCalls, 1);
    expect(controller.stepSignal.value, KbaStep.questions);
    expect(controller.sessionSignal.value?.questions, hasLength(2));
  });

  test('KBA_CPF_NOT_FOUND leva a etapa cpfNotFound', () async {
    repository.onStart = (_) => const Failure(
        ApiFailure('nao achou', status: 404, code: KbaErrorCodes.cpfNotFound));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();

    expect(controller.stepSignal.value, KbaStep.cpfNotFound);
  });

  test('KBA_BLOCKED leva a etapa blocked', () async {
    repository.onStart = (_) => const Failure(
        ApiFailure('bloqueado', status: 403, code: KbaErrorCodes.blocked));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();

    expect(controller.stepSignal.value, KbaStep.blocked);
  });

  test('canSubmit so habilita com todas as perguntas respondidas', () async {
    repository.onStart = (_) => Success(_session());
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();

    expect(controller.canSubmitSignal.value, isFalse);
    controller.selectAnswer('q1', 0);
    expect(controller.canSubmitSignal.value, isFalse);
    controller.selectAnswer('q2', 1);
    expect(controller.canSubmitSignal.value, isTrue);
  });

  test('respostas corretas: vincula, recarrega o access e vai para success',
      () async {
    repository.onStart = (_) => Success(_session());
    repository.onSubmit = (_, __) => const Success(
        KbaSubmitResult(outcome: KbaSubmitOutcome.linked, attemptsRemaining: 2));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();
    controller.selectAnswer('q1', 0);
    controller.selectAnswer('q2', 1);

    await controller.submitAnswers();

    expect(controller.stepSignal.value, KbaStep.success);
    expect(access.loadCalls, 1);
  });

  test('respostas erradas: reinicia com novo conjunto de perguntas', () async {
    repository.onStart = (_) => Success(_session());
    repository.onSubmit = (_, __) => const Success(KbaSubmitResult(
        outcome: KbaSubmitOutcome.wrongAnswers, attemptsRemaining: 1));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();
    controller.selectAnswer('q1', 0);
    controller.selectAnswer('q2', 1);

    await controller.submitAnswers();

    expect(repository.startCalls, 2); // reinicio automatico (tentativa 2)
    expect(controller.stepSignal.value, KbaStep.questions);
    expect(controller.answersSignal.value, isEmpty);
  });

  test('segunda falha: etapa blocked', () async {
    repository.onStart = (_) => Success(_session(attemptsRemaining: 1));
    repository.onSubmit = (_, __) => const Success(KbaSubmitResult(
        outcome: KbaSubmitOutcome.blocked, attemptsRemaining: 0));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();
    controller.selectAnswer('q1', 0);
    controller.selectAnswer('q2', 1);

    await controller.submitAnswers();

    expect(controller.stepSignal.value, KbaStep.blocked);
    expect(access.loadCalls, 1); // atualiza o employeeLink.bloqueado
  });

  test('sessao expirada no submit reinicia de forma transparente', () async {
    repository.onStart = (_) => Success(_session());
    repository.onSubmit = (_, __) => const Failure(ApiFailure('expirou',
        status: 410, code: KbaErrorCodes.sessionExpired));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();
    controller.selectAnswer('q1', 0);
    controller.selectAnswer('q2', 1);

    await controller.submitAnswers();

    expect(repository.startCalls, 2);
    expect(controller.stepSignal.value, KbaStep.questions);
  });

  test('navegacao do stepper respeita os limites das perguntas', () async {
    repository.onStart = (_) => Success(_session());
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();

    expect(controller.currentQuestionSignal.value, 0);
    controller.previousQuestion(); // já está na primeira
    expect(controller.currentQuestionSignal.value, 0);

    controller.nextQuestion();
    expect(controller.currentQuestionSignal.value, 1);
    controller.nextQuestion(); // já está na última (2 perguntas)
    expect(controller.currentQuestionSignal.value, 1);

    controller.goToQuestion(0);
    expect(controller.currentQuestionSignal.value, 0);
    controller.goToQuestion(99); // fora do intervalo: ignorado
    expect(controller.currentQuestionSignal.value, 0);
  });

  test('novo conjunto de perguntas volta o stepper para a primeira', () async {
    repository.onStart = (_) => Success(_session());
    repository.onSubmit = (_, __) => const Success(KbaSubmitResult(
        outcome: KbaSubmitOutcome.wrongAnswers, attemptsRemaining: 1));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();
    controller.selectAnswer('q1', 0);
    controller.selectAnswer('q2', 1);
    controller.nextQuestion();
    expect(controller.currentQuestionSignal.value, 1);

    await controller.submitAnswers(); // errou -> reinicia com novas perguntas

    expect(controller.currentQuestionSignal.value, 0);
  });

  test('restart volta para a etapa de CPF e limpa o estado', () async {
    repository.onStart = (_) => const Failure(
        ApiFailure('nao achou', status: 404, code: KbaErrorCodes.cpfNotFound));
    controller.cpfController.text = '529.982.247-25';
    await controller.submitCpf();
    expect(controller.stepSignal.value, KbaStep.cpfNotFound);

    controller.restart();

    expect(controller.stepSignal.value, KbaStep.cpf);
    expect(controller.sessionSignal.value, isNull);
    expect(controller.errorSignal.value, isNull);
  });
}
