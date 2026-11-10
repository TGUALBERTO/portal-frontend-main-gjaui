import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/atas/data/models/requests.dart';

/// Abre o diálogo de geração de ATA e devolve o [GerarAtaRequest] preenchido,
/// ou `null` se cancelado.
Future<GerarAtaRequest?> showGerarAtaDialog() {
  return showAppDialog<GerarAtaRequest>(child: const _GerarAtaDialog());
}

class _GerarAtaDialog extends StatefulWidget {
  const _GerarAtaDialog();

  @override
  State<_GerarAtaDialog> createState() => _GerarAtaDialogState();
}

class _GerarAtaDialogState extends State<_GerarAtaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userId = TextEditingController();
  final _meetingId = TextEditingController();
  final _transcriptId = TextEditingController();
  bool _force = false;

  @override
  void dispose() {
    _userId.dispose();
    _meetingId.dispose();
    _transcriptId.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(
        GerarAtaRequest(
          userId: _userId.text.trim(),
          meetingId: _meetingId.text.trim(),
          transcriptId: _transcriptId.text.trim(),
          force: _force ? true : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerar ATA'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'User ID',
                controller: _userId,
                validator: _required,
                autofocus: true,
              ),
              SizedBox(height: AppSpacing.ms),
              AppTextField(
                label: 'Meeting ID',
                controller: _meetingId,
                validator: _required,
              ),
              SizedBox(height: AppSpacing.ms),
              AppTextField(
                label: 'Transcript ID',
                controller: _transcriptId,
                validator: _required,
              ),
              SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _force,
                onChanged: (v) => setState(() => _force = v),
                title: const Text('Reprocessar ATA existente'),
                subtitle:
                    const Text('Gera novamente mesmo que já exista uma ATA.'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(label: 'Gerar', onPressed: _submit, width: ButtonSize.small),
      ],
    );
  }
}
