import 'package:gjamobile/src/features/kba/presentation/controllers/kba_controller.dart';
import 'package:gjamobile/src/features/kba/presentation/widgets/kba_question_card.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Etapa de perguntas em [Stepper] vertical: uma pergunta visível por vez.
/// Só avança depois de responder a pergunta atual; perguntas já respondidas
/// podem ser revisitadas pelo cabeçalho do passo. O envio fica no último
/// passo e exige todas respondidas.
class KbaQuestionsStep extends StatelessWidget {
  const KbaQuestionsStep({super.key, required this.controller});

  final KbaController controller;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return SignalBuilder(builder: (context) {
      final session = controller.sessionSignal.value;
      if (session == null) return const AppLoading();
      final answers = controller.answersSignal.value;
      final current = controller.currentQuestionSignal.value;
      final canSubmit = controller.canSubmitSignal.value;
      final error = controller.errorSignal.value;
      final questions = session.questions;

      // Até onde o usuário pode navegar: a primeira pergunta sem resposta
      // (ou a última, quando todas já foram respondidas).
      var frontier = questions.length - 1;
      for (var i = 0; i < questions.length; i++) {
        if (!answers.containsKey(questions[i].id)) {
          frontier = i;
          break;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirme sua identidade',
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Responda às perguntas abaixo com base nos seus dados cadastrais. '
            'É preciso acertar todas.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (session.isLastAttempt) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: AppBorders.card,
                color: cs.errorContainer,
              ),
              child: Row(
                children: [
                  Icon(GjaIcons.warning,
                      color: cs.onErrorContainer, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Esta é sua última tentativa. Em caso de erro, o '
                      'desbloqueio dependerá da equipe responsável.',
                      style:
                          tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          Stepper(
            currentStep: current,
            physics: const NeverScrollableScrollPhysics(),
            margin: EdgeInsets.zero,
            onStepTapped: (index) {
              if (index <= frontier) controller.goToQuestion(index);
            },
            controlsBuilder: (context, details) => _StepControls(
              controller: controller,
              isFirst: details.stepIndex == 0,
              isLast: details.stepIndex == questions.length - 1,
              answered:
                  answers.containsKey(questions[details.stepIndex].id),
              canSubmit: canSubmit,
            ),
            steps: [
              for (var i = 0; i < questions.length; i++)
                Step(
                  title: Text('Pergunta ${i + 1} de ${questions.length}'),
                  state: _stateFor(
                      index: i,
                      current: current,
                      answered: answers.containsKey(questions[i].id)),
                  isActive: i == current,
                  content: KbaQuestionCard(
                    question: questions[i],
                    selectedIndex: answers[questions[i].id],
                    onSelect: (option) =>
                        controller.selectAnswer(questions[i].id, option),
                  ),
                ),
            ],
          ),
          if (error != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ],
        ],
      );
    });
  }

  static StepState _stateFor({
    required int index,
    required int current,
    required bool answered,
  }) {
    if (index == current) return StepState.editing;
    return answered ? StepState.complete : StepState.indexed;
  }
}

class _StepControls extends StatelessWidget {
  const _StepControls({
    required this.controller,
    required this.isFirst,
    required this.isLast,
    required this.answered,
    required this.canSubmit,
  });

  final KbaController controller;
  final bool isFirst;
  final bool isLast;
  final bool answered;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          if (isLast)
            Expanded(
              child: AppButton(
                label: 'Confirmar respostas',
                height: ButtonSize.small,
                onPressed: canSubmit ? controller.submitAnswers : null,
              ),
            )
          else
            Expanded(
              child: AppButton(
                label: 'Próxima',
                height: ButtonSize.small,
                onPressed: answered ? controller.nextQuestion : null,
              ),
            ),
          if (!isFirst) ...[
            SizedBox(width: AppSpacing.sm),
            AppButton(
              label: 'Voltar',
              height: ButtonSize.small,
              variant: ButtonVariant.ghost,
              onPressed: controller.previousQuestion,
            ),
          ],
        ],
      ),
    );
  }
}
