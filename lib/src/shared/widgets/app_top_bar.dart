import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = true,
    this.onPressed,
    this.isTransparent = false,
    this.showBackButton = true,
  });

  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onPressed;
  final bool? centerTitle;
  final bool isTransparent;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bool canPop = context.canPop();

    void handleBack() {
      if (onPressed != null) {
        onPressed!();
      } else if (canPop) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return AppBar(
      centerTitle: centerTitle,
      // Fundo e sombra de cabeçalho do GJA vêm do `appBarTheme`; a barra
      // transparente fica sem sombra, para não flutuar sobre o conteúdo.
      elevation: isTransparent ? 0 : null,
      scrolledUnderElevation: isTransparent ? 0 : null,
      backgroundColor: isTransparent ? Colors.transparent : null,
      shadowColor: isTransparent ? Colors.transparent : null,
      title: titleWidget ??
          Text(
            title,
            style: theme.appBarTheme.titleTextStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ??
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
      leadingWidth: showBackButton ? kToolbarHeight : 0,
      leading: showBackButton
          ? IconButton(
              onPressed: handleBack,
              icon: Icon(
                GjaIcons.navBack,
                color: theme.appBarTheme.iconTheme?.color ??
                    theme.colorScheme.onSurface,
              ),
            )
          : const SizedBox.shrink(),
      iconTheme: theme.appBarTheme.iconTheme,
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
