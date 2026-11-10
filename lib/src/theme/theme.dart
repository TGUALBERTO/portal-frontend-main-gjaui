import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'gja_theme_bridge.dart';
import 'text_theme.dart';

Color _colorFromHex(String hex) => GjaThemeBridge.colorFromHex(hex);

/// Raios do GJA (botão 8, campo 4, elemento 12, bloco 16).
const _r = GjaThemeBridge.radius;

/// Custom theme extension for spacing and other design tokens.
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  const AppDesignTokens({
    required this.paddingSmall,
    required this.paddingMedium,
    required this.paddingLarge,
    required this.borderRadiusSmall,
    required this.borderRadiusMedium,
    required this.borderRadiusLarge,
    required this.cardElevation,
    required this.maxFormWidth,
    required this.maxContentWidth,
  });

  final double paddingSmall;
  final double paddingMedium;
  final double paddingLarge;
  final double borderRadiusSmall;
  final double borderRadiusMedium;
  final double borderRadiusLarge;
  final double cardElevation;

  /// Max width for single-column forms (login, settings).
  final double maxFormWidth;

  /// Max width for primary content area on large screens.
  final double maxContentWidth;

  static const fallback = AppDesignTokens(
    paddingSmall: 8,
    paddingMedium: 16,
    paddingLarge: 24,
    borderRadiusSmall: 4,
    borderRadiusMedium: 12,
    borderRadiusLarge: 24,
    cardElevation: 0,
    maxFormWidth: 480,
    maxContentWidth: 1200,
  );

  @override
  ThemeExtension<AppDesignTokens> copyWith({
    double? paddingSmall,
    double? paddingMedium,
    double? paddingLarge,
    double? borderRadiusSmall,
    double? borderRadiusMedium,
    double? borderRadiusLarge,
    double? cardElevation,
    double? maxFormWidth,
    double? maxContentWidth,
  }) {
    return AppDesignTokens(
      paddingSmall: paddingSmall ?? this.paddingSmall,
      paddingMedium: paddingMedium ?? this.paddingMedium,
      paddingLarge: paddingLarge ?? this.paddingLarge,
      borderRadiusSmall: borderRadiusSmall ?? this.borderRadiusSmall,
      borderRadiusMedium: borderRadiusMedium ?? this.borderRadiusMedium,
      borderRadiusLarge: borderRadiusLarge ?? this.borderRadiusLarge,
      cardElevation: cardElevation ?? this.cardElevation,
      maxFormWidth: maxFormWidth ?? this.maxFormWidth,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    );
  }

  @override
  ThemeExtension<AppDesignTokens> lerp(
    covariant ThemeExtension<AppDesignTokens>? other,
    double t,
  ) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      paddingSmall: lerpDouble(paddingSmall, other.paddingSmall, t)!,
      paddingMedium: lerpDouble(paddingMedium, other.paddingMedium, t)!,
      paddingLarge: lerpDouble(paddingLarge, other.paddingLarge, t)!,
      borderRadiusSmall:
          lerpDouble(borderRadiusSmall, other.borderRadiusSmall, t)!,
      borderRadiusMedium:
          lerpDouble(borderRadiusMedium, other.borderRadiusMedium, t)!,
      borderRadiusLarge:
          lerpDouble(borderRadiusLarge, other.borderRadiusLarge, t)!,
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t)!,
      maxFormWidth: lerpDouble(maxFormWidth, other.maxFormWidth, t)!,
      maxContentWidth: lerpDouble(maxContentWidth, other.maxContentWidth, t)!,
    );
  }

  static double? lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}

ThemeData _buildTheme(
    ColorScheme colorScheme, AppColorsExtension customColors) {
  // Tamanhos e pesos do portal, na família tipográfica do GJA (Inter).
  final textTheme = GjaThemeBridge.applyTypography(buildTextTheme());

  return ThemeData(
    useMaterial3: true,
    primaryColor: colorScheme.primary,
    colorScheme: colorScheme,
    textTheme: textTheme,
    fontFamily: GjaThemeBridge.typography.base.fontFamily,
    fontFamilyFallback: GjaThemeBridge.typography.base.fontFamilyFallback,
    extensions: [
      customColors,
      AppDesignTokens.fallback,
    ],

    // --- Basic Elements ---
    // Fundo da aplicação do GJA (sapBackgroundColor), atrás dos contêineres.
    scaffoldBackgroundColor: colorScheme.surfaceContainer,
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(
      color: colorScheme.onSurface,
      size: 24,
    ),

    // --- Widget Themes ---

    // App Bar Theme
    // Cabeçalho do GJA (GjaBarDesign.header): fundo base com a sombra de
    // cabeçalho (2 px de deslocamento, 4 de desfoque), aproximada pela
    // elevação 2 do Material. O tint fica desligado para o fundo não puxar a
    // marca ao rolar.
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 2,
      scrolledUnderElevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.5),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(88, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.button)),
        elevation: 0,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.button)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.button)),
        // Linha fina do GJA (borda do botão standard).
        side: BorderSide(color: colorScheme.outline),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(88, 40),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.button)),
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: AppDesignTokens.fallback.cardElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(_r.tile),
      ),
      color: colorScheme.surfaceContainerLow,
    ),

    // Input Decoration Theme
    // Campo do GJA (GjaInput): fundo base, borda fina `fieldBorder`, marca
    // no foco e cores de erro do estado de valor. Rótulo e dica na cor
    // `label`, sem transparência, para manter o contraste mínimo.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_r.field),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_r.field),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_r.field),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_r.field),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_r.field),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_r.field),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      floatingLabelStyle: TextStyle(color: colorScheme.primary),
      labelStyle:
          textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      hintStyle:
          textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
    ),

    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      elevation: 8,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 80,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelSmall?.copyWith(
              color: colorScheme.primary, fontWeight: FontWeight.bold);
        }
        return textTheme.labelSmall
            ?.copyWith(color: colorScheme.onSurfaceVariant);
      }),
    ),

    // Navigation Rail Theme
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      labelType: NavigationRailLabelType.all,
      unselectedLabelTextStyle:
          textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: textTheme.labelSmall
          ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: textTheme.titleSmall,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      // onPrimary, nao onPrimaryContainer: os builds light/dark fazem
      // copyWith(onPrimaryContainer: primary), o que deixaria o icone
      // primary-sobre-primary (invisivel) nos dois modos.
      foregroundColor: colorScheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.tile)),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.m)),
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // `color` é obrigatório: sem ela o rótulo usa a cor default do engine
      // (preta) em vez de `onSurface` — ilegível no dark mode.
      labelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
      iconTheme: IconThemeData(color: colorScheme.primary, size: 16),
    ),

    // List Tile Theme
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.element)),
      visualDensity: VisualDensity.comfortable,
      // `color` é obrigatório aqui: o ListTile usa este style como está (só
      // sobrescreve a cor se `textColor`/`selectedColor` estiverem setados no
      // tema, o que não é o caso). Sem cor explícita o título cai no default do
      // engine em vez de `onSurface` — ilegível no dark mode.
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle:
          textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.s)),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primaryContainer;
        }
        return colorScheme.surfaceContainerHighest;
      }),
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.m)),
      elevation: 4,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.element)),
      elevation: 0,
      backgroundColor: colorScheme.surface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_r.tile),
        ),
      ),
    ),

    // Search Bar Theme
    searchBarTheme: SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerLow),
      shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_r.full))),
      padding:
          WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
      hintStyle: WidgetStateProperty.all(
          textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
    ),

    // Badge Theme
    badgeTheme: BadgeThemeData(
      backgroundColor: colorScheme.error,
      textColor: colorScheme.onError,
      textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
    ),

    // Segmented Button Theme
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: colorScheme.secondaryContainer,
        selectedForegroundColor: colorScheme.onSecondaryContainer,
        side: BorderSide(color: colorScheme.outline),
      ),
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(_r.s),
      ),
      textStyle:
          textTheme.labelSmall?.copyWith(color: colorScheme.onInverseSurface),
    ),
  );
}

/// Tema Material claro com as cores do GJA e a marca [primaryColorHex].
ThemeData buildLightTheme({required String primaryColorHex}) =>
    _buildGjaTheme(Brightness.light, primaryColorHex);

/// Tema Material escuro com as cores do GJA e a marca [primaryColorHex].
ThemeData buildDarkTheme({required String primaryColorHex}) =>
    _buildGjaTheme(Brightness.dark, primaryColorHex);

ThemeData _buildGjaTheme(Brightness brightness, String primaryColorHex) {
  final colors = GjaThemeBridge.colors(
    brightness: brightness,
    primaryColorHex: primaryColorHex,
  );
  return _buildTheme(
    GjaThemeBridge.colorScheme(colors, brightness),
    GjaThemeBridge.appColors(colors),
  );
}

CupertinoThemeData buildCupertinoTheme({required String primaryColorHex}) {
  final seed =
      _colorFromHex(primaryColorHex.isNotEmpty ? primaryColorHex : '#de3438');

  return CupertinoThemeData(
    applyThemeToAll: true,
    primaryColor: seed,
    primaryContrastingColor: CupertinoColors.white,
    brightness: null, // Allow system-wide dark mode support
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    barBackgroundColor: CupertinoColors.systemGrey6,
    textTheme: CupertinoTextThemeData(
      primaryColor: seed,
      textStyle: const TextStyle(
        fontSize: 17,
        letterSpacing: -0.41,
      ),
      actionTextStyle: TextStyle(
        color: seed,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      navTitleTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        letterSpacing: -0.41,
      ),
      navLargeTitleTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 34,
        letterSpacing: 0.41,
      ),
      tabLabelTextStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.24,
      ),
      pickerTextStyle: const TextStyle(
        fontSize: 21,
        letterSpacing: -0.41,
      ),
      dateTimePickerTextStyle: const TextStyle(
        fontSize: 21,
        letterSpacing: -0.41,
      ),
    ),
  );
}
