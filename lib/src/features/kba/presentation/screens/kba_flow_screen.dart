import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/kba/presentation/controllers/kba_controller.dart';
import 'package:gjamobile/src/features/kba/presentation/widgets/kba_cpf_step.dart';
import 'package:gjamobile/src/features/kba/presentation/widgets/kba_questions_step.dart';
import 'package:gjamobile/src/features/kba/presentation/widgets/kba_result_step.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Tela do fluxo de vínculo de matrícula (Dynamic KBA) — rota /vinculo.
/// Wizard em etapa única controlado por [KbaController] (screen-scoped).
class KbaFlowScreen extends StatefulWidget {
  const KbaFlowScreen({super.key});

  @override
  State<KbaFlowScreen> createState() => _KbaFlowScreenState();
}

class _KbaFlowScreenState extends State<KbaFlowScreen> {
  final KbaController _controller = AppInjector.get<KbaController>();

  @override
  void initState() {
    super.initState();
    // Usuário já bloqueado em login anterior cai direto no aviso.
    final link = AppInjector.get<AccessController>().employeeLink;
    if (link != null && link.bloqueado) {
      _controller.markBlocked();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      formWidth: true,
      centerVertically: true,
      body: SignalBuilder(builder: (context) {
        final step = _controller.stepSignal.value;
        return switch (step) {
          KbaStep.cpf => KbaCpfStep(controller: _controller),
          KbaStep.loadingQuestions ||
          KbaStep.submitting =>
            const AppLoading(),
          KbaStep.questions => KbaQuestionsStep(controller: _controller),
          KbaStep.success => KbaResultStep.success(context),
          KbaStep.blocked => KbaResultStep.blocked(),
          KbaStep.cpfNotFound =>
            KbaResultStep.cpfNotFound(onRetry: _controller.restart),
          KbaStep.insufficientData => KbaResultStep.insufficientData(),
        };
      }),
    );
  }
}
