import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/app_update/domain/entities/app_release.dart';
import 'package:gjamobile/src/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

bool _dialogOpen = false;

/// Abre o diálogo de atualização sobre a tela atual. Chamado pelo
/// `AppUpdateListener` ao abrir o app e pela entrada "Atualizar app" da Home.
///
/// Não empilha: uma segunda chamada com o diálogo aberto é ignorada.
Future<void> showAppUpdateDialog() async {
  if (_dialogOpen) return;
  _dialogOpen = true;
  try {
    // Sem fechar tocando fora: o alvo é o coletor operado com luva, e um toque
    // perdido não pode nem sumir com o aviso nem abandonar um download. Sair é
    // sempre por um botão.
    await showAppDialog<void>(
      child: const AppUpdateDialog(),
      dismissible: false,
    );
  } finally {
    _dialogOpen = false;
  }
}

/// Conduz a atualização: oferta → download → conferência → instalador.
///
/// É só a face do [AppUpdateController]; cada estado dele vira um corpo aqui.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, this.controller});

  /// Só para teste. Em uso normal vem do injector.
  final AppUpdateController? controller;

  @override
  Widget build(BuildContext context) {
    final controller =
        this.controller ?? AppInjector.get<AppUpdateController>();

    return SignalBuilder(builder: (context) {
      final status = controller.statusSignal.value;
      final release = controller.releaseSignal.value;
      final busy = status == AppUpdateStatus.downloading ||
          status == AppUpdateStatus.verifying;

      return PopScope(
        // O voltar do Android não abandona um download em andamento; para isso
        // existe o Cancelar.
        canPop: !busy,
        child: Dialog(
          insetPadding: EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            // Rolável: no coletor pequeno ou deitado o conteúdo é mais alto que
            // a tela, e sem isto os botões ficariam cortados.
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: [
                  const _Header(),
                  if (release == null)
                    ..._upToDate(context)
                  else
                    ...switch (status) {
                      AppUpdateStatus.downloading =>
                        _downloading(context, controller),
                      AppUpdateStatus.verifying => _verifying(context),
                      AppUpdateStatus.readyToInstall =>
                        _readyToInstall(context, controller),
                      AppUpdateStatus.failed => _failed(context, controller),
                      _ => _available(context, controller, release),
                    },
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _available(
    BuildContext context,
    AppUpdateController controller,
    AppRelease release,
  ) {
    final installed = controller.installedSignal.value;
    return [
      Text(
        'Há uma versão nova do Portal GJA para este aparelho.',
        style: context.textTheme.bodyMedium,
      ),
      Column(
        spacing: AppSpacing.xs,
        children: [
          _InfoRow(label: 'Nova versão', value: release.versionName),
          if (installed != null && installed.versionName.isNotEmpty)
            _InfoRow(label: 'Instalada', value: installed.versionName),
          _InfoRow(label: 'Tamanho', value: release.sizeLabel),
        ],
      ),
      AppButton(
        label: 'Atualizar agora',
        isFullWidth: true,
        onPressed: controller.startUpdate,
      ),
      _LaterButton(onPressed: () => Navigator.of(context).pop()),
    ];
  }

  List<Widget> _downloading(
    BuildContext context,
    AppUpdateController controller,
  ) {
    final progress = controller.progressSignal.value;
    return [
      Text(
        'Baixando a atualização… ${(progress * 100).round()}%',
        style: context.textTheme.bodyMedium,
      ),
      LinearProgressIndicator(value: progress),
      AppButton(
        label: 'Cancelar',
        variant: ButtonVariant.outline,
        isFullWidth: true,
        onPressed: controller.cancelDownload,
      ),
    ];
  }

  List<Widget> _verifying(BuildContext context) => [
        Text(
          'Conferindo o arquivo baixado…',
          style: context.textTheme.bodyMedium,
        ),
        const LinearProgressIndicator(),
      ];

  List<Widget> _readyToInstall(
    BuildContext context,
    AppUpdateController controller,
  ) {
    final error = controller.errorSignal.value;
    return [
      Text(
        'Download concluído. Toque em Instalar e confirme na tela do Android. '
        'O app fecha sozinho durante a instalação.',
        style: context.textTheme.bodyMedium,
      ),
      if (error != null) _ErrorText(message: error.message),
      AppButton(
        label: 'Instalar',
        isFullWidth: true,
        onPressed: controller.install,
      ),
      _LaterButton(onPressed: () => Navigator.of(context).pop()),
    ];
  }

  List<Widget> _failed(BuildContext context, AppUpdateController controller) => [
        _ErrorText(
          message: controller.errorSignal.value?.message ??
              'Não foi possível baixar a atualização.',
        ),
        AppButton(
          label: 'Tentar de novo',
          isFullWidth: true,
          onPressed: controller.startUpdate,
        ),
        _LaterButton(onPressed: () => Navigator.of(context).pop()),
      ];

  List<Widget> _upToDate(BuildContext context) => [
        Text(
          'O app já está na versão mais recente.',
          style: context.textTheme.bodyMedium,
        ),
        AppButton(
          label: 'Fechar',
          variant: ButtonVariant.outline,
          isFullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Icon(GjaIcons.downloadFromCloud, color: context.colors.primary),
        Expanded(
          child: Text(
            'Atualização do app',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.error,
      ),
    );
  }
}

class _LaterButton extends StatelessWidget {
  const _LaterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Depois',
      variant: ButtonVariant.ghost,
      isFullWidth: true,
      onPressed: onPressed,
    );
  }
}
