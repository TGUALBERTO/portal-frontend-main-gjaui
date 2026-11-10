import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/reuniao_processamento_status.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/status_pill.dart';

/// Badge do status de processamento de uma reunião.
class ReuniaoStatusBadge extends StatelessWidget {
  const ReuniaoStatusBadge({super.key, required this.status});

  final ReuniaoProcessamentoStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      ReuniaoProcessamentoStatus.meetingFound ||
      ReuniaoProcessamentoStatus.meetingNotFinished ||
      ReuniaoProcessamentoStatus.meetingFinished ||
      ReuniaoProcessamentoStatus.transcriptionFound ||
      ReuniaoProcessamentoStatus.queuedForMinutesCreation =>
        BadgeTone.warning,
      ReuniaoProcessamentoStatus.minutesProcessing => BadgeTone.info,
      ReuniaoProcessamentoStatus.transcriptionDownloaded ||
      ReuniaoProcessamentoStatus.minutesCreated =>
        BadgeTone.success,
      ReuniaoProcessamentoStatus.transcriptionSaveError ||
      ReuniaoProcessamentoStatus.minutesCreationError =>
        BadgeTone.error,
      ReuniaoProcessamentoStatus.meetingCancelled ||
      ReuniaoProcessamentoStatus.notOnlineMeeting ||
      ReuniaoProcessamentoStatus.transcriptionNotFound ||
      ReuniaoProcessamentoStatus.desconhecido =>
        BadgeTone.neutral,
    };
    final spinner = status == ReuniaoProcessamentoStatus.minutesProcessing;

    return Semantics(
      label: 'Status da reunião: ${status.label}',
      child: StatusPill.tone(context,
          label: status.label, tone: tone, spinner: spinner),
    );
  }
}
