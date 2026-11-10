import 'package:gja_ui/gja_ui.dart'
    show GjaIllustratedMessage, GjaIllustrationType, GjaThemeData;

import '../../imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Displays an empty state with an icon, title, optional subtitle, and action.
///
/// Desenhado pelo [GjaIllustratedMessage] (`sap.m.IllustratedMessage`).
/// Com o [icon] padrão, usa a ilustração `noData` do GJA; com um ícone da
/// tela, desenha-o no tamanho e na cor das ilustrações do GJA.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: GjaIcons.inbox,
///   title: 'No messages yet',
///   subtitle: 'Your inbox will appear here.',
///   actionLabel: 'Refresh',
///   onAction: _refresh,
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = defaultIcon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Ícone padrão; com ele, usa-se a ilustração `noData` do GJA.
  static const IconData defaultIcon = GjaIcons.inbox;

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          description: subtitle,
          illustrationType: GjaIllustrationType.noData,
          illustration: icon == defaultIcon
              ? null
              : gjaIllustrationIcon(context, icon),
          additionalContent: [
            if (actionLabel != null && onAction != null)
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: ButtonVariant.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// [icon] no tamanho e na cor das ilustrações do GJA (formato `dialog`).
Widget gjaIllustrationIcon(BuildContext context, IconData icon) {
  final theme = GjaThemeData.of(context);
  return Icon(icon, size: theme.icons.xLarge * 2, color: theme.colors.brand);
}
