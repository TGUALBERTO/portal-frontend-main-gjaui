import 'package:gja_ui/gja_ui.dart'
    show GjaIllustratedMessage, GjaIllustrationType;

import '../../imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Displays an error state with an icon, title, optional body, and retry button.
///
/// Desenhado pelo [GjaIllustratedMessage] (`sap.m.IllustratedMessage`).
/// Com o [icon] padrão, usa a ilustração `error` do GJA; com um ícone da
/// tela, desenha-o no tamanho e na cor das ilustrações do GJA.
///
/// Usage:
/// ```dart
/// AppErrorWidget(
///   title: 'Algo deu errado',
///   message: error.toString(),
///   onRetry: () => ref.invalidate(myProvider),
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.title = 'Algo deu errado',
    this.message,
    this.onRetry,
    this.icon = defaultIcon,
  });

  /// Ícone padrão; com ele, usa-se a ilustração `error` do GJA.
  static const IconData defaultIcon = GjaIcons.error;

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsive<double>(
          mobile: AppSpacing.xl,
          tablet: AppSpacing.xxl,
          desktop: AppSpacing.xxxl,
        )),
        child: GjaIllustratedMessage(
          title: title,
          description: message,
          illustrationType: GjaIllustrationType.error,
          illustration: icon == defaultIcon
              ? null
              : gjaIllustrationIcon(context, icon),
          additionalContent: [
            if (onRetry != null)
              AppButton(
                label: 'Tentar novamente',
                onPressed: onRetry,
                variant: ButtonVariant.outline,
              ),
          ],
        ),
      ),
    );
  }
}
