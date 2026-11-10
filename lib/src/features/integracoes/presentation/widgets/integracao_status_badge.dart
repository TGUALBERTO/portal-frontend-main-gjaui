import 'package:gjamobile/src/features/integracoes/data/models/status_execucao.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/widgets/status_pill.dart';

/// Badge do status de um processo de integracao. Mostra spinner enquanto a
/// execucao esta viva, para o administrador ver que a tela nao congelou.
class IntegracaoStatusBadge extends StatelessWidget {
  const IntegracaoStatusBadge({
    super.key,
    required this.status,
    this.ativo = true,
  });

  final StatusExecucao status;

  /// Quando falso, o processo esta desativado no ambiente e o status da ultima
  /// execucao seria enganoso — o badge diz "Desativado".
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    if (!ativo) {
      return Semantics(
        label: 'Integração desativada neste ambiente',
        child: StatusPill.tone(context,
            label: 'Desativado', tone: BadgeTone.neutral),
      );
    }
    return Semantics(
      label: 'Status da execução: ${status.label}',
      child: StatusPill.tone(
        context,
        label: status.label,
        tone: status.tone,
        spinner: status.isTransitorio,
      ),
    );
  }
}
