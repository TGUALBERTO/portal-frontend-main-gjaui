import 'package:gja_ui/gja_ui.dart' show GjaThemeData;

import '../../../imports/imports.dart';
import '../../../theme/gja_theme_bridge.dart';

/// Compact floating card used by toasts.
///
/// Shrink-wraps its content and caps the width at
/// [AppBreakpoints.maxToastWidth], so it stays proportional on wide
/// (desktop/web) windows instead of stretching edge to edge.
class ToastCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? color;
  final Color? borderColor;
  final void Function()? onTap;

  const ToastCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.color,
    this.borderColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: AppSpacing.ms),
        ],
        Flexible(
          child: subtitle == null
              ? title
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    SizedBox(height: AppSpacing.xxs),
                    subtitle!,
                  ],
                ),
        ),
        if (trailing != null) ...[
          SizedBox(width: AppSpacing.ms),
          trailing!,
        ],
      ],
    );

    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          constraints:
              const BoxConstraints(maxWidth: AppBreakpoints.maxToastWidth),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.ms,
          ),
          decoration: BoxDecoration(
            color: color ?? context.theme.dialogTheme.backgroundColor,
            // Raio `popover` e sombra `popover` do GJA.
            borderRadius: AppBorders.sm,
            border: Border.all(
              color: borderColor ?? context.colors.outlineVariant,
            ),
            boxShadow: GjaThemeBridge.boxShadows(
              GjaThemeData.of(context),
              GjaThemeData.of(context).shadows.popover,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
