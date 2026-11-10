import 'package:flutter/material.dart';

class FioriColors {
  FioriColors._();

  static const blue3 = Color(0xFFA6E0FF);
  static const blue5 = Color(0xFF4DB1FF);
  static const blue6 = Color(0xFF1B90FF);
  static const blue7 = Color(0xFF0070F2);
  static const blue8 = Color(0xFF0057D2);
  static const grey1 = Color(0xFFF5F6F7);
  static const grey2 = Color(0xFFEAECEE);
  static const grey3 = Color(0xFFD5DADD);
  static const grey4 = Color(0xFFA9B4BE);
  static const grey5 = Color(0xFF8396A8);
  static const grey6 = Color(0xFF5B738B);
  static const grey7 = Color(0xFF475E75);
  static const grey8 = Color(0xFF354A5F);
  static const grey9 = Color(0xFF223548);
  static const grey11 = Color(0xFF12171C);
  static const baseDark = Color(0xFF14171A);
  static const red5 = Color(0xFFFF5C77);
  static const red6 = Color(0xFFEE3939);
  static const red7 = Color(0xFFD20A0A);
  static const mango5 = Color(0xFFFFB300);
  static const mango6 = Color(0xFFE76500);
  static const mango7 = Color(0xFFC35500);
  static const green5 = Color(0xFF5DC122);
  static const green6 = Color(0xFF36A41D);
  static const green7 = Color(0xFF188918);
  static const darkOverlay = Color(0xFF7198BF);
}

const fioriLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: FioriColors.blue7,
  onPrimary: Colors.white,
  primaryContainer: Color(0x140070F2),
  onPrimaryContainer: FioriColors.blue8,
  secondary: FioriColors.grey11,
  onSecondary: Colors.white,
  secondaryContainer: FioriColors.grey1,
  onSecondaryContainer: FioriColors.grey9,
  tertiary: FioriColors.blue8,
  onTertiary: Colors.white,
  tertiaryContainer: FioriColors.blue3,
  onTertiaryContainer: FioriColors.blue8,
  error: FioriColors.red7,
  onError: Colors.white,
  errorContainer: Color(0x14EE3939),
  onErrorContainer: FioriColors.red7,
  surface: Colors.white,
  onSurface: FioriColors.grey9,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Colors.white,
  surfaceContainer: FioriColors.grey1,
  surfaceContainerHigh: FioriColors.grey1,
  surfaceContainerHighest: FioriColors.grey2,
  onSurfaceVariant: FioriColors.grey7,
  outline: FioriColors.grey5,
  outlineVariant: FioriColors.grey3,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: FioriColors.grey11,
  onInverseSurface: Colors.white,
  inversePrimary: FioriColors.blue5,
  surfaceTint: FioriColors.blue7,
);

const fioriDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: FioriColors.blue5,
  onPrimary: FioriColors.grey11,
  primaryContainer: Color(0x5C4DB1FF),
  onPrimaryContainer: FioriColors.blue3,
  secondary: Colors.white,
  onSecondary: FioriColors.grey11,
  secondaryContainer: FioriColors.grey6,
  onSecondaryContainer: Colors.white,
  tertiary: FioriColors.blue3,
  onTertiary: FioriColors.grey11,
  tertiaryContainer: FioriColors.blue8,
  onTertiaryContainer: FioriColors.blue3,
  error: FioriColors.red5,
  onError: FioriColors.grey11,
  errorContainer: Color(0x1FEE3939),
  onErrorContainer: FioriColors.red5,
  surface: FioriColors.baseDark,
  onSurface: FioriColors.grey1,
  surfaceContainerLowest: FioriColors.baseDark,
  surfaceContainerLow: Color(0xFF1A1D21),
  surfaceContainer: Color(0xFF20252A),
  surfaceContainerHigh: Color(0xFF263039),
  surfaceContainerHighest: FioriColors.grey6,
  onSurfaceVariant: FioriColors.grey3,
  outline: FioriColors.grey5,
  outlineVariant: Color(0x805B738B),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: FioriColors.grey1,
  onInverseSurface: FioriColors.grey11,
  inversePrimary: FioriColors.blue7,
  surfaceTint: FioriColors.blue5,
);

/// App-specific colors that aren't part of the standard [ColorScheme].
/// Access via `context.appColors` (defined in `context_extension.dart`).
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    this.successContainer,
    this.onSuccessContainer,
    this.warningContainer,
    this.onWarningContainer,
    this.infoContainer,
    this.onInfoContainer,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color? successContainer;
  final Color? onSuccessContainer;
  final Color? warningContainer;
  final Color? onWarningContainer;
  final Color? infoContainer;
  final Color? onInfoContainer;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t),
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t),
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t),
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t),
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t),
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t),
    );
  }
}

/// Helper class to define the actual color palettes
class AppPalettes {
  AppPalettes._();

  static const light = AppColorsExtension(
    success: FioriColors.green7,
    onSuccess: Colors.white,
    successContainer: Color(0x1436A41D),
    onSuccessContainer: FioriColors.green7,
    warning: FioriColors.mango7,
    onWarning: Colors.white,
    warningContainer: Color(0x14E76500),
    onWarningContainer: FioriColors.mango7,
    info: FioriColors.blue7,
    onInfo: Colors.white,
    infoContainer: Color(0x141B90FF),
    onInfoContainer: FioriColors.blue7,
  );

  static const dark = AppColorsExtension(
    success: FioriColors.green5,
    onSuccess: FioriColors.grey11,
    successContainer: Color(0x1F36A41D),
    onSuccessContainer: FioriColors.green5,
    warning: FioriColors.mango5,
    onWarning: FioriColors.grey11,
    warningContainer: Color(0x1FE76500),
    onWarningContainer: FioriColors.mango5,
    info: FioriColors.blue5,
    onInfo: FioriColors.grey11,
    infoContainer: Color(0x1F1B90FF),
    onInfoContainer: FioriColors.blue5,
  );
}

/// Access semantic colors via `context.appColors` from `context_extension.dart`.
/// Example: `context.appColors.success`
