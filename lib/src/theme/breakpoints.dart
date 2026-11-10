/// Material 3 window size classes. Use via `context.windowSize` /
/// `context.responsive(...)` from [ContextExtension].
enum AppWindowSize {
  /// Phone portrait, < 600 dp wide.
  compact,

  /// Phone landscape / small tablet, 600–839 dp.
  medium,

  /// Tablet / small laptop, 840–1199 dp.
  expanded,

  /// Laptop / small desktop, 1200–1599 dp.
  large,

  /// Desktop, ≥ 1600 dp.
  extraLarge;

  bool get isMobile => this == AppWindowSize.compact;
  bool get isTablet => this == AppWindowSize.medium;
  bool get isDesktop =>
      this == AppWindowSize.expanded ||
      this == AppWindowSize.large ||
      this == AppWindowSize.extraLarge;
}

abstract final class AppBreakpoints {
  AppBreakpoints._();

  /// < 600 dp
  static const double compact = 600;

  /// 600–839 dp
  static const double medium = 840;

  /// 840–1199 dp
  static const double expanded = 1200;

  /// 1200–1599 dp
  static const double large = 1600;

  /// Max content width used by [AppResponsiveContainer] per window size.
  static double maxContentWidthFor(AppWindowSize w) => switch (w) {
        AppWindowSize.compact => double.infinity,
        AppWindowSize.medium => 720,
        AppWindowSize.expanded => 960,
        AppWindowSize.large => 1200,
        AppWindowSize.extraLarge => 1440,
      };

  /// Max width for narrow single-column forms (auth, settings).
  static double maxFormWidth = 480;

  /// Max width for floating toasts/notifications.
  static const double maxToastWidth = 480;

  /// Standard page horizontal padding per window size.
  static double pagePaddingFor(AppWindowSize w) => switch (w) {
        AppWindowSize.compact => 16,
        AppWindowSize.medium => 24,
        AppWindowSize.expanded => 32,
        AppWindowSize.large => 48,
        AppWindowSize.extraLarge => 64,
      };

  static AppWindowSize fromWidth(double width) {
    if (width < compact) return AppWindowSize.compact;
    if (width < medium) return AppWindowSize.medium;
    if (width < expanded) return AppWindowSize.expanded;
    if (width < large) return AppWindowSize.large;
    return AppWindowSize.extraLarge;
  }
}
