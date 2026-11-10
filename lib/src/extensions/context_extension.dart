import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/enums/snack_bar_type.dart';
import '../theme/breakpoints.dart';
import '../theme/color_schemes.dart';
import '../theme/theme.dart';

extension ContextExtension on BuildContext {
  // ── Theme shortcuts ──────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get typography => theme.textTheme;
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Semantic/custom colors (success, warning, info).
  AppColorsExtension get appColors =>
      theme.extension<AppColorsExtension>() ?? (isDarkMode ? AppPalettes.dark : AppPalettes.light);

  /// Design tokens (spacing, border radii, elevation defaults).
  AppDesignTokens get designTokens =>
      theme.extension<AppDesignTokens>() ?? AppDesignTokens.fallback;

  // ── MediaQuery shortcuts ─────────────────────────────────────────────────
  Size get mediaQuerySize => MediaQuery.sizeOf(this);
  Size get screenSize => mediaQuerySize;
  double get width => mediaQuerySize.width;
  double get height => mediaQuerySize.height;

  // ── Responsive ───────────────────────────────────────────────────────────
  /// Current window size class (compact/medium/expanded/large/extraLarge).
  AppWindowSize get windowSize => AppBreakpoints.fromWidth(width);
  bool get isMobile => windowSize.isMobile;
  bool get isTablet => windowSize.isTablet;
  bool get isDesktop => windowSize.isDesktop;
  bool get isCompact => windowSize == AppWindowSize.compact;
  bool get isExpanded => windowSize == AppWindowSize.expanded;
  bool get isLarge => windowSize == AppWindowSize.large;
  bool get isExtraLarge => windowSize == AppWindowSize.extraLarge;

  /// Max width for centred content on the current viewport.
  double get maxContentWidth => AppBreakpoints.maxContentWidthFor(windowSize);

  /// Default horizontal page padding for the current viewport.
  double get pagePadding => AppBreakpoints.pagePaddingFor(windowSize);

  /// Pick a value per window size. Falls back from the requested tier down to
  /// the next defined one (so providing only `mobile` + `desktop` still works
  /// for tablets, medium, expanded, etc).
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? large,
  }) {
    return switch (windowSize) {
      AppWindowSize.compact => mobile,
      AppWindowSize.medium => tablet ?? mobile,
      AppWindowSize.expanded => desktop ?? tablet ?? mobile,
      AppWindowSize.large => large ?? desktop ?? tablet ?? mobile,
      AppWindowSize.extraLarge => large ?? desktop ?? tablet ?? mobile,
    };
  }

  /// Safe-area insets for the current view.
  EdgeInsets get safeArea => MediaQuery.paddingOf(this);

  // ── Keyboard ──────────────────────────────────────────────────────────────
  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;
  void hideKeyboard() => FocusScope.of(this).unfocus();

  // ── Platform ─────────────────────────────────────────────────────────────
  bool get isIOS => theme.platform == TargetPlatform.iOS;
  bool get isAndroid => theme.platform == TargetPlatform.android;

  // ── Overlays ─────────────────────────────────────────────────────────────
  void showSnackBar(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          duration: duration,
        ),
      );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: appColors.success,
        ),
      );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: colors.error,
        ),
      );
  }

  Future<T?> showAppBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
    );
  }

  Future<T?> showAppDialog<T>({required WidgetBuilder builder}) {
    return showDialog<T>(
      context: this,
      builder: builder,
    );
  }

  /// Shows a snackbar with a colour driven by [SnackBarType].
  ///
  /// ```dart
  /// context.showTypedSnackBar('Saved!', type: SnackBarType.success);
  /// ```
  void showTypedSnackBar(
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final bg = switch (type) {
      SnackBarType.success => appColors.success,
      SnackBarType.warning => appColors.warning,
      SnackBarType.error   => colors.error,
      SnackBarType.info    => colors.inverseSurface,
    };
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bg,
          duration: duration,
        ),
      );
  }

  // ── Routing shortcuts ────────────────────────────────────────────────────
  String get currentRoute {
    final router = GoRouter.of(this);
    final RouteMatch lastMatch = router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

}
