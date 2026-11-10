import '../../imports/imports.dart';

/// Standard page scaffold: handles SafeArea, responsive horizontal page
/// padding and an optional content-width constraint so content stays
/// readable on tablet/desktop.
///
/// Use [formWidth] `true` for auth/settings forms (narrower column).
/// Pass [scrollable] `false` for pages that manage their own scrolling
/// (e.g. lists, custom scroll views).
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.endDrawer,
    this.backgroundColor,
    this.formWidth = false,
    this.maxContentWidth,
    this.scrollable = true,
    this.centerVertically = false,
    this.padding,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  /// Painel lateral acessível por gesto/botão. Usado por telas que mostram um
  /// painel fixo ao lado do conteúdo no desktop e o recolhem em telas estreitas.
  final Widget? endDrawer;

  final Color? backgroundColor;

  /// Constrain body to [AppDesignTokens.maxFormWidth].
  final bool formWidth;

  /// Override the max content width.
  final double? maxContentWidth;

  /// Wraps body in a [SingleChildScrollView]. Defaults to true.
  final bool scrollable;

  /// Center content vertically (useful for auth screens).
  final bool centerVertically;

  /// Override the default responsive horizontal page padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.pagePadding;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: context.isCompact ? 16 : 24,
        );

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      endDrawer: endDrawer,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget content = AppResponsiveContainer(
              formWidth: formWidth,
              maxWidth: maxContentWidth,
              padding: effectivePadding,
              child: body,
            );

            if (centerVertically) {
              content = ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - bottomInset)
                      .clamp(0, double.infinity),
                ),
                child: Center(child: content),
              );
            }

            if (scrollable) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: content,
              );
            }

            return centerVertically
                ? content
                : Align(alignment: Alignment.topCenter, child: content);
          },
        ),
      ),
    );
  }
}
