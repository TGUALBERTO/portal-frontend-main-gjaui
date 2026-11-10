import '../../imports/imports.dart';

/// Centres [child] horizontally and constrains it to [maxWidth]. Defaults to
/// the content max width for the current window size.
///
/// Use [maxWidth] for a custom constraint, or set [formWidth] `true` to use
/// the form max width (narrower — good for auth/settings forms).
class AppResponsiveContainer extends StatelessWidget {
  const AppResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.formWidth = false,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final bool formWidth;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designTokens;
    final effectiveMax = maxWidth ??
        (formWidth ? tokens.maxFormWidth : context.maxContentWidth);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMax),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
