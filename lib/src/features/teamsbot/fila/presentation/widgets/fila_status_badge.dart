import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/fila/data/models/fila_status.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/status_pill.dart';

/// Badge do status de um item na fila FIFO de criação de ATAs.
class FilaStatusBadge extends StatelessWidget {
  const FilaStatusBadge({super.key, required this.status});

  final FilaStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      FilaStatus.aguardando => BadgeTone.warning,
      FilaStatus.processando => BadgeTone.info,
      FilaStatus.concluido => BadgeTone.success,
      FilaStatus.erro => BadgeTone.error,
      FilaStatus.desconhecido => BadgeTone.neutral,
    };
    final spinner = status == FilaStatus.processando;

    return Semantics(
      label: 'Status da fila: ${status.label}',
      child: StatusPill.tone(context,
          label: status.label, tone: tone, spinner: spinner),
    );
  }
}
