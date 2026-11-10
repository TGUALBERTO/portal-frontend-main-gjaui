import 'package:flutter/material.dart';
import 'package:gja_ui/gja_ui.dart'
    show
        GjaColorTokens,
        GjaRadiusTokens,
        GjaShadowLayer,
        GjaThemeData,
        GjaTypographyTokens;

import 'color_schemes.dart' show AppColorsExtension;

/// Ponte entre o design system GJA (`packages/gja`) e o tema Material do
/// portal.
///
/// O portal continua usando os componentes Material; esta ponte faz com que
/// eles leiam as cores, a fonte e os raios do GJA. A cor da marca continua a
/// do portal (hex vindo do app), e os demais papéis vêm dos tokens do GJA.
///
/// O mesmo [GjaThemeData] é publicado no app (`GjaThemeScope`) para que os
/// widgets GJA usados nas telas fiquem coerentes com o Material.
abstract final class GjaThemeBridge {
  /// Raios de borda do GJA, usados pelos temas de componente do Material.
  static const radius = GjaRadiusTokens.fallback();

  /// Tipografia de referência do GJA (Inter empacotada).
  static const typography = GjaTypographyTokens.fallback();

  /// Tema GJA com a marca do portal ([primaryColorHex]).
  static GjaThemeData theme({
    required Brightness brightness,
    required String primaryColorHex,
  }) {
    final base = brightness == Brightness.dark
        ? GjaThemeData.dark()
        : GjaThemeData.light();
    return base.copyWith(
      colors: colors(brightness: brightness, primaryColorHex: primaryColorHex),
    );
  }

  /// Papéis de cor do GJA com a marca trocada pela do portal.
  ///
  /// Hover e ativo seguem a convenção do GJA: no claro escurecem, no
  /// escuro clareiam. O texto sobre a marca é o de maior contraste.
  static GjaColorTokens colors({
    required Brightness brightness,
    required String primaryColorHex,
  }) {
    final isDark = brightness == Brightness.dark;
    final reference =
        isDark ? const GjaColorTokens.dark() : const GjaColorTokens.light();
    final brand = colorFromHex(primaryColorHex);
    final step = isDark ? 0.08 : -0.08;

    return reference.copyWith(
      brand: brand,
      brandHover: _shiftLightness(brand, step),
      highlight: _shiftLightness(brand, step * 2),
      contrastText: onColor(brand),
      focus: brand,
    );
  }

  /// [ColorScheme] do Material derivado dos papéis do GJA.
  static ColorScheme colorScheme(GjaColorTokens c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.contrastText,
      primaryContainer: c.brand.withValues(alpha: isDark ? 0.36 : 0.08),
      onPrimaryContainer: c.brand,
      secondary: c.text,
      onSecondary: c.base,
      secondaryContainer: c.selectionBackground,
      onSecondaryContainer: c.text,
      tertiary: c.link,
      onTertiary: c.base,
      tertiaryContainer: c.selectionHoverBackground,
      onTertiaryContainer: c.text,
      error: c.error.foreground,
      onError: c.base,
      errorContainer: c.error.background,
      onErrorContainer: c.error.foreground,
      surface: c.base,
      onSurface: c.text,
      surfaceContainerLowest: c.base,
      surfaceContainerLow: c.base,
      surfaceContainer: c.background,
      surfaceContainerHigh: c.headerBackground,
      surfaceContainerHighest: c.separator,
      onSurfaceVariant: c.label,
      outline: c.fieldBorder,
      outlineVariant: c.separator,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: c.text,
      onInverseSurface: c.base,
      inversePrimary: c.brand,
      surfaceTint: c.brand,
    );
  }

  /// Cores semânticas do portal (`context.appColors`) a partir dos estados de
  /// valor do GJA (success, warning, information).
  static AppColorsExtension appColors(GjaColorTokens c) {
    return AppColorsExtension(
      success: c.success.foreground,
      onSuccess: c.base,
      successContainer: c.success.background,
      onSuccessContainer: c.success.foreground,
      warning: c.warning.foreground,
      onWarning: c.base,
      warningContainer: c.warning.background,
      onWarningContainer: c.warning.foreground,
      info: c.information.foreground,
      onInfo: c.base,
      infoContainer: c.information.background,
      onInfoContainer: c.information.foreground,
    );
  }

  /// [textTheme] com a família tipográfica do GJA (Inter), mantendo os
  /// tamanhos e pesos do portal para não alterar layouts.
  static TextTheme applyTypography(TextTheme textTheme) {
    return textTheme.apply(
      fontFamily: typography.base.fontFamily,
      fontFamilyFallback: typography.base.fontFamilyFallback,
    );
  }

  /// Camadas de sombra do GJA ([layers], ex.: `theme.shadows.card`) como
  /// [BoxShadow], na cor de sombra do tema.
  static List<BoxShadow> boxShadows(
    GjaThemeData theme,
    List<GjaShadowLayer> layers,
  ) {
    final color = theme.colors.shadow;
    return [
      for (final layer in layers)
        BoxShadow(
          color: color.withValues(alpha: color.a * layer.opacity),
          offset: Offset(0, layer.offsetY),
          blurRadius: layer.blurRadius,
          spreadRadius: layer.spreadRadius,
        ),
    ];
  }

  /// Converte `#RRGGBB` em [Color] opaca.
  static Color colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('ff$cleaned', radix: 16));
  }

  /// Branco ou o texto escuro do GJA, o que tiver mais contraste com [color].
  static Color onColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const GjaColorTokens.light().text;
  }

  static Color _shiftLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + delta).clamp(0.0, 1.0))
        .toColor();
  }
}
