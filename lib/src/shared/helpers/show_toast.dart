import '../../imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

void showToast(
  BuildContext context, {
  required String message,
  String? status = 'success',
  IconData? icon,
  Duration? duration,
  bool? autoDismiss,
}) {
  final toastStatus = status ?? 'info';
  final colorScheme = context.colors;
  final appColors = context.appColors;

  final (backgroundColor, foregroundColor, iconColor) = switch (toastStatus) {
    'error' => (
      colorScheme.errorContainer,
      colorScheme.onErrorContainer,
      colorScheme.error,
    ),
    'success' => (
      appColors.successContainer ?? appColors.success,
      appColors.onSuccessContainer ?? appColors.onSuccess,
      appColors.success,
    ),
    'warning' => (
      appColors.warningContainer ?? appColors.warning,
      appColors.onWarningContainer ?? appColors.onWarning,
      appColors.warning,
    ),
    'info' => (
      appColors.infoContainer ?? appColors.info,
      appColors.onInfoContainer ?? appColors.onInfo,
      appColors.info,
    ),
    _ => (
      context.theme.scaffoldBackgroundColor,
      colorScheme.onSurface,
      colorScheme.onSurfaceVariant,
    ),
  };

  final toastIcon = icon ??
      switch (toastStatus) {
        'success' => GjaIcons.sysEnter2,
        'error' => GjaIcons.error,
        'warning' => GjaIcons.warning,
        _ => GjaIcons.information,
      };

  return ToastBar(
    position: ToastPosition.top,
    autoDismiss: autoDismiss ?? true,
    toastDuration: duration ?? const Duration(seconds: 2),
    animationDuration: const Duration(milliseconds: 150),
    animationCurve: Curves.easeIn,
    builder: (context) => ToastCard(
      // Os tokens *Container têm alpha baixo; o blend sobre a surface evita
      // que o toast fique translúcido flutuando sobre o conteúdo.
      color: Color.alphaBlend(backgroundColor, colorScheme.surface),
      borderColor: iconColor.withValues(alpha: 0.35),
      leading: Icon(toastIcon, color: iconColor, size: 20),
      title: Text(
        message,
        style: context.textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),
    ),
  ).show(context);
}

void showGlobalToast({
  required String message,
  String? status = 'success',
  IconData? icon,
  Duration? duration,
  bool? autoDismiss,
}) {
  final ctx = rootContext;
  if (ctx == null) return;

  showToast(
    ctx,
    message: message,
    status: status,
    icon: icon,
    duration: duration,
    autoDismiss: autoDismiss,
  );
}
