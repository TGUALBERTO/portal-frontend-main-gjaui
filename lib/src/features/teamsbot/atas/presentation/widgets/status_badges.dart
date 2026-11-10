import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/atas/data/models/ata_status.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/index_status.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/sharepoint_status.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/status_pill.dart';

/// Badge do ciclo de vida da ATA ([AtaStatus]).
class AtaStatusBadge extends StatelessWidget {
  const AtaStatusBadge({super.key, required this.status});

  final AtaStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      AtaStatus.gerada => BadgeTone.success,
      AtaStatus.reprocessada => BadgeTone.info,
      AtaStatus.cancelada || AtaStatus.desconhecido => BadgeTone.neutral,
    };

    return Semantics(
      label: 'Status: ${status.label}',
      child: StatusPill.tone(context, label: status.label, tone: tone),
    );
  }
}

/// Badge da situação de indexação ([IndexStatus]).
///
/// Em `ATA_INDEXANDO` exibe um [CircularProgressIndicator] pequeno.
class IndexStatusBadge extends StatelessWidget {
  const IndexStatusBadge({super.key, required this.status});

  final IndexStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      IndexStatus.ataIndexada => BadgeTone.success,
      IndexStatus.ataIndexando => BadgeTone.info,
      IndexStatus.erroIndexacao => BadgeTone.error,
      IndexStatus.pendenteIndexacao || IndexStatus.desconhecido =>
        BadgeTone.neutral,
    };

    return Semantics(
      label: 'Indexação: ${status.label}',
      child: StatusPill.tone(
        context,
        label: status.label,
        tone: tone,
        spinner: status.isIndexando,
      ),
    );
  }
}

/// Badge do envio ao SharePoint ([SharePointStatus]).
///
/// Em `PENDENTE_ENVIO` (enviando) exibe um [CircularProgressIndicator] pequeno.
class SharePointStatusBadge extends StatelessWidget {
  const SharePointStatusBadge({super.key, required this.status});

  final SharePointStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      SharePointStatus.enviada => BadgeTone.success,
      SharePointStatus.pendenteEnvio => BadgeTone.info,
      SharePointStatus.erroEnvio => BadgeTone.error,
      SharePointStatus.naoEnviada || SharePointStatus.desconhecido =>
        BadgeTone.neutral,
    };

    return Semantics(
      label: 'SharePoint: ${status.label}',
      child: StatusPill.tone(
        context,
        label: status.label,
        tone: tone,
        spinner: status.isEnviando,
      ),
    );
  }
}
