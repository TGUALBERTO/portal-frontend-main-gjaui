import '../../imports/imports.dart';

/// Initialises [ScreenUtil] with design sizes tuned per window class so `.w` /
/// `.h` / `.sp` don't blow up on desktop. Mobile keeps the 360×690 baseline;
/// tablet/desktop switch to wider baselines that keep scaling near 1.0× on
/// typical viewports.
class ScreenUtilWrapper extends StatelessWidget {
  final Widget child;
  final Size mobileDesignSize;
  final Size tabletDesignSize;
  final Size desktopDesignSize;
  final bool minTextAdapt;
  final bool splitScreenMode;

  const ScreenUtilWrapper({
    super.key,
    required this.child,
    this.mobileDesignSize = const Size(360, 690),
    this.tabletDesignSize = const Size(768, 1024),
    this.desktopDesignSize = const Size(1440, 900),
    this.minTextAdapt = true,
    this.splitScreenMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = AppBreakpoints.fromWidth(constraints.maxWidth);
        final design = switch (window) {
          AppWindowSize.compact => mobileDesignSize,
          AppWindowSize.medium => tabletDesignSize,
          AppWindowSize.expanded ||
          AppWindowSize.large ||
          AppWindowSize.extraLarge =>
            desktopDesignSize,
        };

        return ScreenUtilInit(
          designSize: design,
          minTextAdapt: minTextAdapt,
          splitScreenMode: splitScreenMode,
          builder: (context, _) => child,
        );
      },
    );
  }
}
