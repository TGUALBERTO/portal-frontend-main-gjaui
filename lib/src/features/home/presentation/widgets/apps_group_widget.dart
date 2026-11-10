import 'package:gjamobile/src/imports/core_imports.dart';

class AppsGroupWidget extends StatefulWidget {
  const AppsGroupWidget({
    super.key,
    required this.title,
    required this.apps,
  });

  final String title;
  final List<Widget> apps;

  @override
  State<AppsGroupWidget> createState() => _AppsGroupWidgetState();
}

class _AppsGroupWidgetState extends State<AppsGroupWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: context
              .responsive<TextStyle>(
                mobile: textTheme.headlineSmall!,
                tablet: textTheme.headlineMedium,
                desktop: textTheme.headlineLarge,
              )
              .copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: widget.apps,
        ),
      ],
    );
  }
}
